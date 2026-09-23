import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:matcha_lovers_506/core/constants.dart';
import 'package:matcha_lovers_506/data/models/order_model.dart';
import 'package:matcha_lovers_506/domain/entities/order_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Repository for order operations
class OrderRepository {
  final SharedPreferences _prefs;
  static const _uuid = Uuid();
  static const double taxRate = 0.13;

  OrderRepository(this._prefs);

  /// Get all orders sorted by date desc
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final ordersJson =
          _prefs.getStringList(AppConstants.storageKeyOrders) ?? [];
      final orders = ordersJson
          .map((json) =>
              OrderModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
      
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      debugPrint('Get all orders error: $e');
      return [];
    }
  }

  /// Get orders by user
  Future<List<OrderEntity>> getOrdersByUser(String userId) async {
    final orders = await getAllOrders();
    return orders.where((o) => o.userId == userId).toList();
  }

  /// Get orders by date range
  Future<List<OrderEntity>> getOrdersByDateRange(
      DateTime start, DateTime end) async {
    final orders = await getAllOrders();
    return orders
        .where((o) =>
            o.createdAt.isAfter(start) && o.createdAt.isBefore(end))
        .toList();
  }

  /// Create new order — now accepts taxExempt and sinpeVoucher
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
      final now = DateTime.now();
      final subtotal =
          items.fold<double>(0, (sum, item) => sum + item.total);
      // Si está exonerado, IVA = 0
      final tax = taxExempt ? 0.0 : subtotal * taxRate;
      final total = subtotal + tax;

      final order = OrderModel(
        id: _uuid.v4(),
        userId: userId,
        userName: userName,
        items: items,
        subtotal: subtotal,
        tax: tax,
        total: total,
        status: initialStatus,
        paymentMethod: paymentMethod,
        taxExempt: taxExempt,
        sinpeVoucher: sinpeVoucher,
        createdAt: now,
        updatedAt: now,
      );

      await _saveOrder(order);
      debugPrint(
          'Order created: ${order.id} | total: ${order.total} | exempt: $taxExempt | sinpe: $sinpeVoucher');
      return order;
    } catch (e) {
      debugPrint('Create order error: $e');
      return null;
    }
  }

  /// Save order
  Future<void> _saveOrder(OrderModel order) async {
    try {
      final orders = await getAllOrders();
      orders.add(order);
      final ordersJson =
          orders.map((o) => jsonEncode(o.toJson())).toList();
      await _prefs.setStringList(AppConstants.storageKeyOrders, ordersJson);
    } catch (e) {
      debugPrint('Save order error: $e');
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final orders = await getAllOrders();
      final index = orders.indexWhere((o) => o.id == orderId);
      
      if (index != -1) {
        orders[index] = OrderModel.fromEntity(
          orders[index].copyWith(status: status, updatedAt: DateTime.now()),
        );
        final ordersJson =
            orders.map((o) => jsonEncode(o.toJson())).toList();
        await _prefs.setStringList(
            AppConstants.storageKeyOrders, ordersJson);
      }
    } catch (e) {
      debugPrint('Update order status error: $e');
    }
  }

  /// Get sales statistics
  Future<Map<String, dynamic>> getSalesStats(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final orders = await getAllOrders();
      final filtered = orders.where((o) {
        if (startDate != null && o.createdAt.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && o.createdAt.isAfter(endDate)) return false;
        return o.status == OrderStatus.completed;
      }).toList();

      final totalSales =
          filtered.fold<double>(0, (sum, o) => sum + o.total);
      final totalOrders = filtered.length;
      final averageOrderValue =
          totalOrders > 0 ? totalSales / totalOrders : 0.0;

      return {
        'totalSales': totalSales,
        'totalOrders': totalOrders,
        'averageOrderValue': averageOrderValue,
      };
    } catch (e) {
      debugPrint('Get sales stats error: $e');
      return {
        'totalSales': 0.0,
        'totalOrders': 0,
        'averageOrderValue': 0.0,
      };
    }
  }
}
