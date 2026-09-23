import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_master/domain/entities/order_entity.dart';
import 'package:pos_master/domain/entities/product_entity.dart';

/// Cart item with product and quantity
class CartItem {
  final ProductEntity product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  CartItem copyWith({ProductEntity? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get total => product.price * quantity;

  OrderItemEntity toOrderItem() {
    return OrderItemEntity(
      productId: product.id,
      productName: product.name,
      price: product.price,
      quantity: quantity,
    );
  }
}

/// State notifier for shopping cart
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addProduct(ProductEntity product) {
    final existingIndex =
        state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      state = [
        ...state.sublist(0, existingIndex),
        state[existingIndex]
            .copyWith(quantity: state[existingIndex].quantity + 1),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final index =
        state.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(quantity: quantity),
        ...state.sublist(index + 1),
      ];
    }
  }

  void incrementQuantity(String productId) {
    final index =
        state.indexWhere((item) => item.product.id == productId);
    if (index >= 0) updateQuantity(productId, state[index].quantity + 1);
  }

  void decrementQuantity(String productId) {
    final index =
        state.indexWhere((item) => item.product.id == productId);
    if (index >= 0) updateQuantity(productId, state[index].quantity - 1);
  }

  void clear() => state = [];
}

/// Provider for shopping cart
final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(() => CartNotifier());

/// Provider for cart summary — FIX: watch cartProvider (la lista), no .notifier
final cartSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final items = ref.watch(cartProvider); // ← reactivo, se recalcula al cambiar
  final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
  final tax = subtotal * 0.13;
  return {
    'subtotal': subtotal,
    'tax': tax,
    'total': subtotal + tax,
    'itemCount': items.fold(0, (sum, item) => sum + item.quantity),
  };
});
