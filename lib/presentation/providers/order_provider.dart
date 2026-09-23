import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_master/core/constants.dart';
import 'package:pos_master/data/repositories/order_repository.dart';
import 'package:pos_master/domain/entities/order_entity.dart';
import 'package:pos_master/presentation/providers/auth_provider.dart';

/// Provider for OrderRepository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OrderRepository(prefs);
});

/// State notifier for orders
class OrderNotifier extends Notifier<AsyncValue<List<OrderEntity>>> {
  late final OrderRepository _repository;

  @override
  AsyncValue<List<OrderEntity>> build() {
    _repository = ref.watch(orderRepositoryProvider);
    loadOrders();
    return const AsyncValue.loading();
  }

  Future<void> loadOrders() async {
    try {
      state = const AsyncValue.loading();
      final orders = await _repository.getAllOrders();
      state = AsyncValue.data(orders);
    } catch (e, stack) {
      debugPrint('Load orders error: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create order — now accepts taxExempt and sinpeVoucher
  Future<OrderEntity?> createOrder({
    required String userId,
    required String userName,
    required List<OrderItemEntity> items,
    required PaymentMethod paymentMethod,
    bool taxExempt = false,
    String? sinpeVoucher,
    OrderStatus initialStatus = OrderStatus.completed,
  }) async {
    try {
      final order = await _repository.createOrder(
        userId: userId,
        userName: userName,
        items: items,
        paymentMethod: paymentMethod,
        taxExempt: taxExempt,
        sinpeVoucher: sinpeVoucher,
        initialStatus: initialStatus,
      );
      if (order != null) await loadOrders();
      return order;
    } catch (e) {
      debugPrint('Create order error: $e');
      return null;
    }
  }

  Future<void> updateOrderStatus(
      String orderId, OrderStatus status) async {
    try {
      await _repository.updateOrderStatus(orderId, status);
      await loadOrders();
    } catch (e) {
      debugPrint('Update order status error: $e');
    }
  }

  Future<Map<String, dynamic>> getSalesStats(
      {DateTime? startDate, DateTime? endDate}) async {
    return await _repository.getSalesStats(
        startDate: startDate, endDate: endDate);
  }
}

/// Provider for orders state
final orderProvider =
    NotifierProvider<OrderNotifier, AsyncValue<List<OrderEntity>>>(
        () => OrderNotifier());

/// Provider for today's orders
final todayOrdersProvider = Provider<List<OrderEntity>>((ref) {
  final ordersAsync = ref.watch(orderProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  return ordersAsync.maybeWhen(
    data: (orders) => orders.where((o) {
      final d = DateTime(
          o.createdAt.year, o.createdAt.month, o.createdAt.day);
      return d.isAtSameMomentAs(today);
    }).toList(),
    orElse: () => [],
  );
});

/// Provider for sales statistics
final salesStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  return await repository.getSalesStats();
});
