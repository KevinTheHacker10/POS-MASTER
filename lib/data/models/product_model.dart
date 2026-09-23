import 'package:matcha_lovers_506/core/constants.dart';
import 'package:matcha_lovers_506/domain/entities/product_entity.dart';

/// Product model - Data layer
class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
    required super.category,
    super.description,
    super.isAvailable,
    super.imageUrl,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      category: _categoryFromStorage(json['category'] as String?),
      description: json['description'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category.name,
      'description': description,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      price: entity.price,
      category: entity.category,
      description: entity.description,
      isAvailable: entity.isAvailable,
      imageUrl: entity.imageUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

ProductCategory _categoryFromStorage(String? value) {
  // Migrates data created by the original single-business Matcha version.
  switch (value) {
    case 'matcha':
    case 'smoothies':
    case 'healthyJuices':
    case 'coldCoffee':
      return ProductCategory.drinks;
    default:
      return ProductCategory.values.firstWhere(
        (category) => category.name == value,
        orElse: () => ProductCategory.other,
      );
  }
}
