import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:matcha_lovers_506/core/constants.dart';
import 'package:matcha_lovers_506/data/models/product_model.dart';
import 'package:matcha_lovers_506/domain/entities/product_entity.dart';

/// Repository for product operations
class ProductRepository {
  final SharedPreferences _prefs;
  static const _uuid = Uuid();

  ProductRepository(this._prefs);

  /// Initialize with sample products
  Future<void> initializeSampleData() async {
    // A multi-business installation starts with an empty catalog. Products are
    // created from Administration according to the configured establishment.
  }

  /// Get all products
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final productsJson =
          _prefs.getStringList(AppConstants.storageKeyProducts) ?? [];
      return productsJson
          .map((json) =>
              ProductModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Get all products error: $e');
      return [];
    }
  }

  /// Get products by category
  Future<List<ProductEntity>> getProductsByCategory(
      ProductCategory category) async {
    final products = await getAllProducts();
    return products.where((p) => p.category == category).toList();
  }

  /// Save product (append)
  Future<void> _saveProduct(ProductModel product) async {
    try {
      final products = await getAllProducts();
      products.add(product);
      final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();
      await _prefs.setStringList(AppConstants.storageKeyProducts, productsJson);
    } catch (e) {
      debugPrint('Save product error: $e');
    }
  }

  /// Create new product — now accepts imageUrl
  Future<ProductEntity?> createProduct({
    required String name,
    required double price,
    required ProductCategory category,
    String? description,
    String? imageUrl, // ← NUEVO
  }) async {
    try {
      final now = DateTime.now();
      final product = ProductModel(
        id: _uuid.v4(),
        name: name,
        price: price,
        category: category,
        description: description,
        isAvailable: true,
        imageUrl: imageUrl, // ← NUEVO
        createdAt: now,
        updatedAt: now,
      );
      await _saveProduct(product);
      return product;
    } catch (e) {
      debugPrint('Create product error: $e');
      return null;
    }
  }

  /// Update product
  Future<void> updateProduct(ProductEntity product) async {
    try {
      final products = await getAllProducts();
      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        products[index] = ProductModel.fromEntity(product);
        final productsJson =
            products.map((p) => jsonEncode(p.toJson())).toList();
        await _prefs.setStringList(
            AppConstants.storageKeyProducts, productsJson);
      }
    } catch (e) {
      debugPrint('Update product error: $e');
    }
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      final products = await getAllProducts();
      products.removeWhere((p) => p.id == productId);
      final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();
      await _prefs.setStringList(AppConstants.storageKeyProducts, productsJson);
    } catch (e) {
      debugPrint('Delete product error: $e');
    }
  }
}
