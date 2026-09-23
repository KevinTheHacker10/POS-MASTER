import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:matcha_lovers_506/core/constants.dart';
import 'package:matcha_lovers_506/core/responsive/responsive_helper.dart';
import 'package:matcha_lovers_506/domain/entities/order_entity.dart';
import 'package:matcha_lovers_506/presentation/providers/order_provider.dart';
import 'package:matcha_lovers_506/theme.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchCtrl = TextEditingController();
  OrderStatus? _statusFilter;
  PaymentMethod? _paymentFilter;
  _DateFilter _dateFilter = _DateFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<OrderEntity> _applyFilters(List<OrderEntity> orders) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final now = DateTime.now();

    return orders.where((o) {
      // Búsqueda por nombre o ID
      if (query.isNotEmpty) {
        final inName = o.userName.toLowerCase().contains(query);
        final inId = o.id.toLowerCase().contains(query);
        if (!inName && !inId) return false;
      }

      // Filtro estado
      if (_statusFilter != null && o.status != _statusFilter) return false;

      // Filtro pago
      if (_paymentFilter != null && o.paymentMethod != _paymentFilter) return false;

      // Filtro fecha
      switch (_dateFilter) {
        case _DateFilter.today:
          final today = DateTime(now.year, now.month, now.day);
          if (o.createdAt.isBefore(today)) return false;
        case _DateFilter.week:
          final week = now.subtract(const Duration(days: 7));
          if (o.createdAt.isBefore(week)) return false;
        case _DateFilter.month:
          final month = DateTime(now.year, now.month, 1);
          if (o.createdAt.isBefore(month)) return false;
        case _DateFilter.all:
          break;
      }

      return true;
    }).toList();
  }

  void _showOrderDetail(BuildContext context, OrderEntity order) {
    final formatter = NumberFormat.currency(
        symbol: AppConstants.currency, decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden #${order.id.substring(0, 8).toUpperCase()}',
                          style: context.textStyles.titleLarge?.bold,
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy · HH:mm').format(order.createdAt),
                          style: context.textStyles.bodySmall
                              ?.withColor(Colors.grey[600]!),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const Divider(height: 24),

              // Atendió
              _DetailRow(Icons.person, 'Atendido por', order.userName),
              _DetailRow(
                order.paymentMethod == PaymentMethod.cash
                    ? Icons.money
                    : Icons.credit_card,
                'Método de pago',
                order.paymentMethod.displayName,
              ),
              const SizedBox(height: 16),

              // Items
              Text('Productos', style: context.textStyles.titleMedium?.semiBold),
              const SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.oliveGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.oliveGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
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

              const Divider(height: 24),

              // Totales
              _TotalRow('Subtotal', formatter.format(order.subtotal), context),
              const SizedBox(height: 4),
              _TotalRow(
                  'Impuesto (13%)', formatter.format(order.tax), context),
              const SizedBox(height: 8),
              _TotalRow(
                'Total',
                formatter.format(order.total),
                context,
                isTotal: true,
              ),
              if (order.status == OrderStatus.pending) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _changeOrderStatus(
                          ctx,
                          order,
                          OrderStatus.cancelled,
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.coral,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _changeOrderStatus(
                          ctx,
                          order,
                          OrderStatus.completed,
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Cobrar y completar'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeOrderStatus(
    BuildContext sheetContext,
    OrderEntity order,
    OrderStatus status,
  ) async {
    await ref.read(orderProvider.notifier).updateOrderStatus(order.id, status);
    if (!mounted) return;
    Navigator.of(sheetContext).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Orden marcada como ${status.displayName.toLowerCase()}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderProvider);
    final formatter = NumberFormat.currency(
        symbol: AppConstants.currency, decimalDigits: 0);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.softGreen,
      appBar: AppBar(
        title: const Text('Historial de Órdenes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(orderProvider.notifier).loadOrders(),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allOrders) {
          final orders = _applyFilters(allOrders);
          final totalFiltrado =
              orders.fold<double>(0, (s, o) => s + o.total);

          return Column(
            children: [
              // ── Barra de filtros ─────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    // Búsqueda
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o ID de orden...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.oliveGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Chips de filtro
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Fecha
                          ..._DateFilter.values.map((f) {
                            final sel = _dateFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(f.label),
                                selected: sel,
                                selectedColor: AppColors.oliveGreen,
                                labelStyle: TextStyle(
                                  color: sel ? Colors.white : AppColors.oliveGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) =>
                                    setState(() => _dateFilter = f),
                              ),
                            );
                          }),
                          const SizedBox(width: 8),

                          // Estado
                          _FilterChip(
                            label: _statusFilter?.displayName ?? 'Estado',
                            active: _statusFilter != null,
                            onTap: () => _showStatusPicker(),
                          ),
                          const SizedBox(width: 6),

                          // Pago
                          _FilterChip(
                            label: _paymentFilter?.displayName ?? 'Pago',
                            active: _paymentFilter != null,
                            onTap: () => _showPaymentPicker(),
                          ),

                          // Limpiar
                          if (_statusFilter != null || _paymentFilter != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: TextButton.icon(
                                onPressed: () => setState(() {
                                  _statusFilter = null;
                                  _paymentFilter = null;
                                }),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Limpiar'),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.coral),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Resumen rápido ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: AppColors.oliveGreen.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Text(
                      '${orders.length} órdenes',
                      style: context.textStyles.labelLarge?.semiBold
                          .withColor(AppColors.oliveGreen),
                    ),
                    const Spacer(),
                    Text(
                      'Total: ${formatter.format(totalFiltrado)}',
                      style: context.textStyles.titleSmall?.bold
                          .withColor(AppColors.oliveGreen),
                    ),
                  ],
                ),
              ),

              // ── Lista ────────────────────────────────────────────────
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay órdenes',
                              style: context.textStyles.titleMedium
                                  ?.withColor(Colors.grey[400]!),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final o = orders[i];
                          return _OrderCard(
                            order: o,
                            formatter: formatter,
                            onTap: () => _showOrderDetail(context, o),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Todos los estados'),
            onTap: () {
              setState(() => _statusFilter = null);
              Navigator.pop(context);
            },
          ),
          ...OrderStatus.values.map((s) => ListTile(
                leading: _statusIcon(s),
                title: Text(s.displayName),
                onTap: () {
                  setState(() => _statusFilter = s);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showPaymentPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Todos los métodos'),
            onTap: () {
              setState(() => _paymentFilter = null);
              Navigator.pop(context);
            },
          ),
          ...PaymentMethod.values.map((p) => ListTile(
                leading: Icon(
                  p == PaymentMethod.cash ? Icons.money : Icons.credit_card,
                  color: AppColors.oliveGreen,
                ),
                title: Text(p.displayName),
                onTap: () {
                  setState(() => _paymentFilter = p);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _statusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case OrderStatus.pending:
        return const Icon(Icons.access_time, color: Colors.orange);
      case OrderStatus.cancelled:
        return const Icon(Icons.cancel, color: AppColors.coral);
    }
  }
}

// =============================================================================
// ORDER CARD
// =============================================================================

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  final NumberFormat formatter;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd/MM/yyyy · HH:mm').format(order.createdAt);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Ícono pago
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.oliveGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  order.paymentMethod == PaymentMethod.cash
                      ? Icons.money
                      : Icons.credit_card,
                  color: AppColors.oliveGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.userName,
                            style: context.textStyles.titleSmall?.semiBold,
                          ),
                        ),
                        _StatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.items.length} ítems · $timeStr',
                      style: context.textStyles.bodySmall
                          ?.withColor(Colors.grey[500]!),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.items.map((i) => i.productName).join(', '),
                      style: context.textStyles.bodySmall
                          ?.withColor(Colors.grey[400]!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(order.total),
                    style: context.textStyles.titleSmall?.bold
                        .withColor(AppColors.oliveGreen),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HELPERS
// =============================================================================

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.completed:
        color = Colors.green;
      case OrderStatus.pending:
        color = Colors.orange;
      case OrderStatus.cancelled:
        color = AppColors.coral;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.oliveGreen
              : AppColors.oliveGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.oliveGreen
                : AppColors.oliveGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.oliveGreen,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: active ? Colors.white : AppColors.oliveGreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.oliveGreen),
          const SizedBox(width: 8),
          Text('$label: ', style: context.textStyles.bodyMedium?.withColor(Colors.grey[600]!)),
          Text(value, style: context.textStyles.bodyMedium?.semiBold),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;
  final bool isTotal;

  const _TotalRow(this.label, this.value, this.context, {this.isTotal = false});

  @override
  Widget build(BuildContext _) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.textStyles.bodyLarge?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 18 : null,
          ),
        ),
        Text(
          value,
          style: context.textStyles.bodyLarge?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 18 : null,
            color: isTotal ? AppColors.oliveGreen : null,
          ),
        ),
      ],
    );
  }
}

enum _DateFilter {
  today('Hoy'),
  week('7 días'),
  month('Mes'),
  all('Todo');

  final String label;
  const _DateFilter(this.label);
}
