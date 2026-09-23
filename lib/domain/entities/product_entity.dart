import 'package:pos_master/core/constants.dart';

/// Product entity - Domain layer
class ProductEntity {
  final String id;
  final String name;
  final double price;
  final ProductCategory category;
  final String? description;
  final bool isAvailable;
  final String? imageUrl; // URL de imagen o emoji personalizado
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.description,
    this.isAvailable = true,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductEntity copyWith({
    String? id,
    String? name,
    double? price,
    ProductCategory? category,
    String? description,
    bool? isAvailable,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Devuelve la imagen a mostrar: imageUrl si existe, si no el emoji de categoría
  String get displayImage => (imageUrl != null && imageUrl!.isNotEmpty)
      ? imageUrl!
      : category.icon;

  /// True si tiene imagen personalizada (URL http o emoji distinto al de categoría)
  bool get hasCustomImage =>
      imageUrl != null && imageUrl!.isNotEmpty && imageUrl != category.icon;
}