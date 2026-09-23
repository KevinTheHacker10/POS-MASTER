import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:matcha_lovers_506/core/constants.dart';
import 'package:matcha_lovers_506/domain/entities/order_entity.dart';
import 'package:matcha_lovers_506/presentation/providers/auth_provider.dart';
import 'package:matcha_lovers_506/presentation/providers/business_settings_provider.dart';
import 'package:matcha_lovers_506/presentation/providers/cart_provider.dart';
import 'package:matcha_lovers_506/presentation/providers/order_provider.dart';
import 'package:matcha_lovers_506/theme.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _taxExempt = false;
  bool _isProcessing = false;
  bool _paymentDone = false;

  // Comprobante SINPE
  final _voucherCtrl = TextEditingController();
  final _voucherFocus = FocusNode();

  @override
  void dispose() {
    _voucherCtrl.dispose();
    _voucherFocus.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    // Validar comprobante SINPE
    if (_selectedPaymentMethod == PaymentMethod.sinpe &&
        _voucherCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresá el número de comprobante SINPE'),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _voucherFocus.requestFocus();
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() => _isProcessing = true);

    final orderItems = cart.map((item) => item.toOrderItem()).toList();

    final order = await ref.read(orderProvider.notifier).createOrder(
          userId: currentUser.id,
          userName: currentUser.fullName,
          items: orderItems,
          paymentMethod: _selectedPaymentMethod,
          taxExempt: _taxExempt,
          sinpeVoucher: _selectedPaymentMethod == PaymentMethod.sinpe
              ? _voucherCtrl.text.trim()
              : null,
        );

    if (!mounted) return;

    if (order != null) {
      setState(() => _paymentDone = true);
      ref.read(cartProvider.notifier).clear();

      // Mostrar diálogo de éxito con opción de ver factura
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          order: order,
          onContinue: () => context.go('/pos'),
          onViewInvoice: () {
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (_) => _InvoiceDialog(order: order),
            );
          },
        ),
      );
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar el pago. Intenta de nuevo.'),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final currentUser = ref.watch(currentUserProvider);
    final cartSummary = ref.watch(cartSummaryProvider);
    final formatter =
        NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);

    if (cart.isEmpty && !_paymentDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Recalcular totales con exoneración
    final subtotal = cartSummary['subtotal'] as double;
    final tax = _taxExempt ? 0.0 : (cartSummary['tax'] as double);
    final total = subtotal + tax;

    return Scaffold(
      backgroundColor: AppColors.softGreen,
      appBar: AppBar(
        title: const Text('Confirmar Pago'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          margin: AppSpacing.paddingXl,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding: AppSpacing.paddingXl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Encabezado ────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.softGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long,
                          color: AppColors.oliveGreen, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Text('Resumen de Pedido',
                        style: context.textStyles.headlineSmall?.bold),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Items ─────────────────────────────────────────────
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.softGreen.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: cart
                        .map((item) => Padding(
                              padding: AppSpacing.verticalSm,
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.oliveGreen,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${item.quantity}x',
                                        style: context.textStyles.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(item.product.name,
                                        style: context.textStyles.bodyLarge),
                                  ),
                                  Text(
                                    formatter.format(item.total),
                                    style:
                                        context.textStyles.bodyLarge?.semiBold,
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Exoneración de IVA ────────────────────────────────
                if (currentUser?.role != UserRole.customer)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _taxExempt
                          ? AppColors.oliveGreen.withValues(alpha: 0.08)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _taxExempt
                            ? AppColors.oliveGreen
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          color: _taxExempt
                              ? AppColors.oliveGreen
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Exonerar IVA (13%)',
                                style: context.textStyles.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _taxExempt ? AppColors.oliveGreen : null,
                                ),
                              ),
                              Text(
                                _taxExempt
                                    ? 'Factura sin impuesto aplicado'
                                    : 'Activar para clientes exonerados',
                                style: context.textStyles.bodySmall
                                    ?.copyWith(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _taxExempt,
                          activeColor: AppColors.oliveGreen,
                          onChanged: (v) => setState(() => _taxExempt = v),
                        ),
                      ],
                    ),
                  ),
                if (currentUser?.role != UserRole.customer)
                  const SizedBox(height: 16),

                // ── Totales ───────────────────────────────────────────
                _summaryRow('Subtotal', formatter.format(subtotal)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Impuesto (13%)',
                            style: context.textStyles.bodyLarge),
                        if (_taxExempt) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.oliveGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'EXONERADO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.oliveGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _taxExempt ? '₡0' : formatter.format(tax),
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration:
                            _taxExempt ? TextDecoration.lineThrough : null,
                        color: _taxExempt ? Colors.grey[400] : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                _summaryRow('Total', formatter.format(total), isTotal: true),
                const SizedBox(height: 28),

                // ── Método de pago ────────────────────────────────────
                Text('Método de Pago',
                    style: context.textStyles.titleLarge?.bold),
                const SizedBox(height: 12),
                ...PaymentMethod.values.map((method) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PaymentMethodOption(
                        method: method,
                        isSelected: _selectedPaymentMethod == method,
                        onTap: () =>
                            setState(() => _selectedPaymentMethod = method),
                      ),
                    )),

                // ── Campo comprobante SINPE ───────────────────────────
                if (_selectedPaymentMethod == PaymentMethod.sinpe) ...[
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _voucherCtrl,
                    focusNode: _voucherFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Número de comprobante SINPE *',
                      hintText: 'Ej: 123456789',
                      prefixIcon: const Icon(Icons.confirmation_number,
                          color: AppColors.oliveGreen),
                      filled: true,
                      fillColor: AppColors.softGreen.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppColors.oliveGreen),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: AppColors.oliveGreen.withValues(alpha: 0.4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.oliveGreen, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                const SizedBox(height: 24),

                // ── Botón confirmar ───────────────────────────────────
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    child: _isProcessing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Confirmar Pago',
                                style: context.textStyles.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: context.textStyles.bodyLarge?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 22 : null,
            )),
        Text(value,
            style: context.textStyles.bodyLarge?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 22 : null,
              color: isTotal ? AppColors.oliveGreen : null,
            )),
      ],
    );
  }
}

// =============================================================================
// PAYMENT METHOD OPTION
// =============================================================================

class _PaymentMethodOption extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodOption({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.sinpe:
        return Icons.smartphone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.oliveGreen.withValues(alpha: 0.1)
          : Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.oliveGreen : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.oliveGreen : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.oliveGreen : null,
                      ),
                    ),
                    if (method == PaymentMethod.sinpe)
                      Text(
                        'Requiere número de comprobante',
                        style: context.textStyles.labelSmall
                            ?.copyWith(color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: AppColors.oliveGreen, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SUCCESS DIALOG
// =============================================================================

class _SuccessDialog extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onContinue;
  final VoidCallback onViewInvoice;

  const _SuccessDialog({
    required this.order,
    required this.onContinue,
    required this.onViewInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.oliveGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.oliveGreen, size: 64),
            ),
            const SizedBox(height: 20),
            Text('¡Pago Exitoso!',
                style: context.textStyles.headlineSmall?.bold,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              formatter.format(order.total),
              style: context.textStyles.headlineMedium?.copyWith(
                color: AppColors.oliveGreen,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Pedido #${order.id.substring(0, 8).toUpperCase()}',
              style: context.textStyles.bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (order.taxExempt) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.oliveGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'IVA EXONERADO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.oliveGreen,
                  ),
                ),
              ),
            ],
            if (order.sinpeVoucher != null) ...[
              const SizedBox(height: 8),
              Text(
                'Comprobante SINPE: ${order.sinpeVoucher}',
                style: context.textStyles.bodySmall
                    ?.copyWith(color: Colors.grey[500]),
              ),
            ],
            const SizedBox(height: 28),
            // Botón ver factura
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long),
                label: const Text('Ver Factura'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.oliveGreen,
                  side: const BorderSide(color: AppColors.oliveGreen),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onViewInvoice,
              ),
            ),
            const SizedBox(height: 10),
            // Botón continuar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onContinue,
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// INVOICE DIALOG — Factura imprimible
// =============================================================================

class _InvoiceDialog extends ConsumerWidget {
  final OrderEntity order;

  const _InvoiceDialog({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessName = ref.watch(businessSettingsProvider).businessName;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header del diálogo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.oliveGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Factura',
                    style: context.textStyles.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Contenido de la factura
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _InvoiceContent(order: order),
            ),
          ),

          // Botones
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar'),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: _buildInvoiceText(order, businessName),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Factura copiada al portapapeles'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Imprimir'),
                    onPressed: () {
                      // En web/desktop abre el diálogo de impresión del sistema
                      // En mobile copia al portapapeles como fallback
                      Clipboard.setData(
                        ClipboardData(
                          text: _buildInvoiceText(order, businessName),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Factura lista — usa Ctrl+P o compártela desde el portapapeles',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Texto plano de la factura para copiar/imprimir
  String _buildInvoiceText(OrderEntity order, String businessName) {
    final formatter =
        NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);
    final buf = StringBuffer();
    buf.writeln('================================');
    buf.writeln(businessName.isEmpty ? AppConstants.appName : businessName);
    buf.writeln(AppConstants.appName);
    buf.writeln('================================');
    buf.writeln('Fecha: $dateStr');
    buf.writeln('Pedido: #${order.id.substring(0, 8).toUpperCase()}');
    buf.writeln('Atendió: ${order.userName}');
    buf.writeln('--------------------------------');
    for (final item in order.items) {
      buf.writeln('${item.quantity}x ${item.productName}');
      buf.writeln(
          '   ${formatter.format(item.price)} c/u  →  ${formatter.format(item.total)}');
    }
    buf.writeln('--------------------------------');
    buf.writeln('Subtotal:      ${formatter.format(order.subtotal)}');
    if (order.taxExempt) {
      buf.writeln('IVA (13%):     EXONERADO');
    } else {
      buf.writeln('IVA (13%):     ${formatter.format(order.tax)}');
    }
    buf.writeln('TOTAL:         ${formatter.format(order.total)}');
    buf.writeln('--------------------------------');
    buf.writeln('Pago: ${order.paymentMethod.displayName}');
    if (order.sinpeVoucher != null) {
      buf.writeln('Comprobante:   ${order.sinpeVoucher}');
    }
    if (order.taxExempt) {
      buf.writeln('** FACTURA EXONERADA DE IVA **');
    }
    buf.writeln('================================');
    buf.writeln('     ¡Gracias por su compra!');
    buf.writeln('================================');

    return buf.toString();
  }
}

// =============================================================================
// INVOICE CONTENT — visual dentro del dialog
// =============================================================================

class _InvoiceContent extends StatelessWidget {
  final OrderEntity order;

  const _InvoiceContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);
    final dateStr = DateFormat('dd/MM/yyyy · HH:mm').format(order.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Encabezado empresa
        Center(
          child: Column(
            children: [
              const Text('🍵', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 4),
              Text(
                AppConstants.appName,
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.oliveGreen,
                ),
              ),
              Text(
                'Sistema de Punto de Venta',
                style: context.textStyles.bodySmall
                    ?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _divider(),

        // Info orden
        _infoRow('Fecha', dateStr, context),
        _infoRow(
            'Pedido', '#${order.id.substring(0, 8).toUpperCase()}', context),
        _infoRow('Atendió', order.userName, context),
        _divider(),

        // Items
        Text('Productos',
            style: context.textStyles.labelMedium
                ?.copyWith(color: Colors.grey[500])),
        const SizedBox(height: 8),
        ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.oliveGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.oliveGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.productName,
                        style: context.textStyles.bodyMedium),
                  ),
                  Text(
                    formatter.format(item.total),
                    style: context.textStyles.bodyMedium?.semiBold,
                  ),
                ],
              ),
            )),
        _divider(),

        // Totales
        _totalRow('Subtotal', formatter.format(order.subtotal), context),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('IVA (13%)', style: context.textStyles.bodyMedium),
                if (order.taxExempt) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.oliveGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'EXONERADO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.oliveGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              order.taxExempt ? '₡0' : formatter.format(order.tax),
              style: context.textStyles.bodyMedium?.copyWith(
                decoration: order.taxExempt ? TextDecoration.lineThrough : null,
                color: order.taxExempt ? Colors.grey[400] : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.oliveGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL',
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.oliveGreen,
                  )),
              Text(
                formatter.format(order.total),
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.oliveGreen,
                ),
              ),
            ],
          ),
        ),
        _divider(),

        // Pago
        _infoRow('Método de pago', order.paymentMethod.displayName, context),
        if (order.sinpeVoucher != null)
          _infoRow('Comprobante SINPE', order.sinpeVoucher!, context),
        if (order.taxExempt)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.oliveGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.oliveGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified,
                      color: AppColors.oliveGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Factura exonerada de IVA',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: AppColors.oliveGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '¡Gracias por su compra! 🍵',
            style: context.textStyles.bodyMedium?.copyWith(
              color: AppColors.oliveGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1),
      );

  Widget _infoRow(String label, String value, BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text('$label: ',
                style: context.textStyles.bodySmall
                    ?.copyWith(color: Colors.grey[500])),
            Expanded(
              child: Text(value, style: context.textStyles.bodySmall?.semiBold),
            ),
          ],
        ),
      );

  Widget _totalRow(String label, String value, BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.textStyles.bodyMedium),
          Text(value, style: context.textStyles.bodyMedium?.semiBold),
        ],
      );
}
