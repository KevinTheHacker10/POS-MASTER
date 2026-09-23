import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_master/core/constants.dart';
import 'package:pos_master/data/repositories/product_repository.dart';
import 'package:pos_master/domain/entities/product_entity.dart';
import 'package:pos_master/presentation/providers/auth_provider.dart';

/// Provider for ProductRepository
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProductRepository(prefs);
});

/// Sorting options for product list
enum ProductSort { relevance, priceAsc, priceDesc, nameAsc }

/// UI filter state for products
class ProductFilterState {
  final String query;
  final double? minPrice;
  final double? maxPrice;
  final bool onlyAvailable;
  final ProductSort sort;

  const ProductFilterState({
    this.query = '',
    this.minPrice,
    this.maxPrice,
    this.onlyAvailable = true,
    this.sort = ProductSort.relevance,
  });

  ProductFilterState copyWith({
    String? query,
    double? minPrice,
    double? maxPrice,
    bool? onlyAvailable,
    ProductSort? sort,
  }) =>
      ProductFilterState(
        query: query ?? this.query,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        onlyAvailable: onlyAvailable ?? this.onlyAvailable,
        sort: sort ?? this.sort,
      );

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasPriceRange => minPrice != null || maxPrice != null;
  bool get hasAnyFilter =>
      hasQuery || hasPriceRange || !onlyAvailable || sort != ProductSort.relevance;
}

/// Notifier for filters
class ProductFilterNotifier extends Notifier<ProductFilterState> {
  @override
  ProductFilterState build() => const ProductFilterState();

  void setQuery(String value) => state = state.copyWith(query: value);
  void setPriceRange({double? min, double? max}) =>
      state = state.copyWith(minPrice: min, maxPrice: max);
  void setOnlyAvailable(bool value) =>
      state = state.copyWith(onlyAvailable: value);
  void setSort(ProductSort sort) => state = state.copyWith(sort: sort);
  void clear() => state = const ProductFilterState();
}

/// Provider for product filters
final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilterState>(() {
  return ProductFilterNotifier();
});

/// State notifier for products
class ProductNotifier extends Notifier<AsyncValue<List<ProductEntity>>> {
  late final ProductRepository _repository;

  @override
  AsyncValue<List<ProductEntity>> build() {
    _repository = ref.watch(productRepositoryProvider);
    loadProducts();
    return const AsyncValue.loading();
  }

  Future<void> loadProducts() async {
    try {
      state = const AsyncValue.loading();
      final products = await _repository.getAllProducts();
      state = AsyncValue.data(products);
    } catch (e, stack) {
      debugPrint('Load products error: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> initializeSampleData() async {
    await _repository.initializeSampleData();
    await loadProducts();
  }

  /// Create product — now accepts imageUrl
  Future<void> createProduct({
    required String name,
    required double price,
    required ProductCategory category,
    String? description,
    String? imageUrl,           // ← NUEVO
  }) async {
    try {
      await _repository.createProduct(
        name: name,
        price: price,
        category: category,
        description: description,
        imageUrl: imageUrl,     // ← NUEVO
      );
      await loadProducts();
    } catch (e) {
      debugPrint('Create product error: $e');
    }
  }

  Future<void> updateProduct(ProductEntity product) async {
    try {
      await _repository.updateProduct(product);
      await loadProducts();
    } catch (e) {
      debugPrint('Update product error: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _repository.deleteProduct(productId);
      await loadProducts();
    } catch (e) {
      debugPrint('Delete product error: $e');
    }
  }
}

/// Provider for products state
final productProvider =
    NotifierProvider<ProductNotifier, AsyncValue<List<ProductEntity>>>(() {
  return ProductNotifier();
});

/// Provider to get products by category
final productsByCategoryProvider =
    Provider.family<List<ProductEntity>, ProductCategory>((ref, category) {
  final productsAsync = ref.watch(productProvider);
  return productsAsync.maybeWhen(
    data: (products) =>
        products.where((p) => p.category == category && p.isAvailable).toList(),
    orElse: () => [],
  );
});

/// Provider to get all available products
final availableProductsProvider = Provider<List<ProductEntity>>((ref) {
  final productsAsync = ref.watch(productProvider);
  return productsAsync.maybeWhen(
    data: (products) => products.where((p) => p.isAvailable).toList(),
    orElse: () => [],
  );
});

/// Combined provider: products filtered by current filters and category
final filteredProductsByCategoryProvider =
    Provider.family<List<ProductEntity>, ProductCategory>((ref, category) {
  final productsAsync = ref.watch(productProvider);
  final filters = ref.watch(productFilterProvider);

  List<ProductEntity> items =
      productsAsync.maybeWhen(data: (p) => p, orElse: () => []);

  items = items.where((p) => p.category == category).toList();

  if (filters.onlyAvailable) {
    items = items.where((p) => p.isAvailable).toList();
  }

  final q = filters.query.trim().toLowerCase();
  if (q.isNotEmpty) {
    items = items.where((p) {
      final name = p.name.toLowerCase();
      final desc = (p.description ?? '').toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  if (filters.minPrice != null) {
    items =
        items.where((p) => p.price >= (filters.minPrice! - 0.0001)).toList();
  }
  if (filters.maxPrice != null) {
    items =
        items.where((p) => p.price <= (filters.maxPrice! + 0.0001)).toList();
  }

  switch (filters.sort) {
    case ProductSort.relevance:
      break;
    case ProductSort.priceAsc:
      items.sort((a, b) => a.price.compareTo(b.price));
      break;
    case ProductSort.priceDesc:
      items.sort((a, b) => b.price.compareTo(a.price));
      break;
    case ProductSort.nameAsc:
      items.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
  }

  return items;
});