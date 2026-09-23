import 'package:flutter/material.dart';
import 'package:pos_master/domain/entities/product_entity.dart';
import 'package:pos_master/theme.dart';
import 'package:intl/intl.dart';
import 'package:pos_master/core/constants.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  Color get _bgColor {
    switch (product.category) {
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

  Color get _accentColor {
    switch (product.category) {
      case ProductCategory.meals:
        return AppColors.oliveGreen;
      case ProductCategory.drinks:
        return AppColors.peach;
      case ProductCategory.groceries:
        return AppColors.amber;
      case ProductCategory.desserts:
        return const Color(0xFF8B6D5A);
      case ProductCategory.services:
        return const Color(0xFF2864A8);
      case ProductCategory.other:
        return const Color(0xFF616161);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: AppConstants.currency,
      decimalDigits: 0,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: product.isAvailable ? onTap : null,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Imagen ────────────────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: _ProductImage(product: product, bgColor: _bgColor),
                ),

                // ── Info ──────────────────────────────────────────────────
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.name,
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatter.format(product.price),
                              style: context.textStyles.titleMedium?.copyWith(
                                color: _accentColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Overlay no disponible ──────────────────────────────────
            if (!product.isAvailable)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'No disponible',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Badge categoría ────────────────────────────────────────
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  product.category.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGET DE IMAGEN — reutilizado también en CartPanel
// =============================================================================

/// Muestra la imagen del producto: URL de red, emoji personalizado, o emoji de categoría.
/// Se puede usar en ProductCard y CartItemCard.
class ProductImage extends StatelessWidget {
  final ProductEntity product;
  final Color bgColor;
  final double? emojiSize;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.product,
    required this.bgColor,
    this.emojiSize,
    this.borderRadius,
  });

  bool get _isNetworkImage {
    final url = product.imageUrl ?? '';
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(0);

    if (_isNetworkImage) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          product.imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _EmojiBox(
            bgColor: bgColor,
            emoji: product.category.icon,
            size: emojiSize ?? 56,
            borderRadius: radius,
          ),
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(color: bgColor, borderRadius: radius),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      );
    }

    // Emoji personalizado o el de la categoría
    return _EmojiBox(
      bgColor: bgColor,
      emoji: product.displayImage,
      size: emojiSize ?? 56,
      borderRadius: radius,
    );
  }
}

class _ProductImage extends StatelessWidget {
  final ProductEntity product;
  final Color bgColor;

  const _ProductImage({required this.product, required this.bgColor});

  bool get _isNetworkImage {
    final url = product.imageUrl ?? '';
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (_isNetworkImage) {
      return Image.network(
        product.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _EmojiBox(
          bgColor: bgColor,
          emoji: product.category.icon,
          size: 56,
        ),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: bgColor,
            child:
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
      );
    }

    return _EmojiBox(
      bgColor: bgColor,
      emoji: product.displayImage,
      size: 56,
    );
  }
}

class _EmojiBox extends StatelessWidget {
  final Color bgColor;
  final String emoji;
  final double size;
  final BorderRadius? borderRadius;

  const _EmojiBox({
    required this.bgColor,
    required this.emoji,
    required this.size,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
      ),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size)),
      ),
    );
  }
}
