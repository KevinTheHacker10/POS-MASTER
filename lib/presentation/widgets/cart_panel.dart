import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_master/core/constants.dart';
import 'package:pos_master/presentation/providers/cart_provider.dart';
import 'package:pos_master/presentation/widgets/product_card.dart';
import 'package:pos_master/theme.dart';

class CartPanel extends ConsumerWidget {
  final List<CartItem> cartItems;
  final VoidCallback onCheckout;

  const CartPanel({
    super.key,
    required this.cartItems,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartSummary = ref.watch(cartSummaryProvider);
    final formatter = NumberFormat.currency(
      symbol: AppConstants.currency,
      decimalDigits: 0,
    );

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: AppColors.oliveGreen,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Carrito',
                style: context.textStyles.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (cartItems.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cartSummary['itemCount']}',
                    style: context.textStyles.titleMedium?.copyWith(
                      color: AppColors.oliveGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Items ─────────────────────────────────────────────────────────
        Expanded(
          child: cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Carrito vacío',
                        style: context.textStyles.titleMedium
                            ?.copyWith(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca un producto para agregarlo',
                        style: context.textStyles.bodySmall
                            ?.copyWith(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return CartItemCard(
                      item: item,
                      onIncrement: () => ref
                          .read(cartProvider.notifier)
                          .incrementQuantity(item.product.id),
                      onDecrement: () => ref
                          .read(cartProvider.notifier)
                          .decrementQuantity(item.product.id),
                      onRemove: () => ref
                          .read(cartProvider.notifier)
                          .removeProduct(item.product.id),
                    );
                  },
                ),
        ),

        // ── Resumen + botón ───────────────────────────────────────────────
        if (cartItems.isNotEmpty)
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                _summaryRow('Subtotal',
                    formatter.format(cartSummary['subtotal']), context),
                const SizedBox(height: 6),
                _summaryRow('Impuesto (13%)',
                    formatter.format(cartSummary['tax']), context),
                const Divider(height: 20),
                _summaryRow(
                  'Total',
                  formatter.format(cartSummary['total']),
                  context,
                  isTotal: true,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onCheckout,
                    icon: const Icon(Icons.payment, size: 22),
                    label: Text(
                      'Procesar Pago',
                      style: context.textStyles.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.oliveGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, BuildContext context,
      {bool isTotal = false}) {
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

// =============================================================================
// CART ITEM CARD — usa ProductImage para mostrar imagen real o emoji
// =============================================================================

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  Color get _bgColor {
    switch (item.product.category) {
      case ProductCategory.meals:
        return const Color(0xFFDFF2D0);
      case ProductCategory.drinks:
        return const Color(0xFFFFE4F0);
      case ProductCategory.groceries:
        return const Color(0xFFFFF3CC);
      case ProductCategory.desserts:
        return const Color(0xFFE8DDD0);
      case ProductCategory.services:
        return const Color(0xFFDDEBFF);
      case ProductCategory.other:
        return const Color(0xFFE8E8E8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: AppConstants.currency,
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // ── Imagen del producto (URL o emoji) ──────────────────────
            SizedBox(
              width: 60,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ProductImage(
                  product: item.product,
                  bgColor: _bgColor,
                  emojiSize: 30,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info + controles ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: context.textStyles.bodyMedium?.semiBold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onRemove,
                        child: const Icon(Icons.close,
                            size: 18, color: AppColors.coral),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _qtyBtn(Icons.remove, onDecrement),
                          SizedBox(
                            width: 36,
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                              style: context.textStyles.titleSmall?.bold,
                            ),
                          ),
                          _qtyBtn(Icons.add, onIncrement),
                        ],
                      ),
                      Text(
                        formatter.format(item.total),
                        style: context.textStyles.titleSmall?.bold
                            .withColor(AppColors.oliveGreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.oliveGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
