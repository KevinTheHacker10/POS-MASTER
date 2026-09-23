import 'package:pos_master/core/constants.dart';

/// Order item entity
class OrderItemEntity {
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  const OrderItemEntity({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  OrderItemEntity copyWith({
    String? productId,
    String? productName,
    double? price,
    int? quantity,
  }) {
    return OrderItemEntity(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Order entity - Domain layer
class OrderEntity {
  final String id;
  final String userId;
  final String userName;
  final List<OrderItemEntity> items;
  final double subtotal;
  final double tax;
  final double total;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final bool taxExempt;         // Exonerado de IVA
  final String? sinpeVoucher;   // Número de comprobante SINPE
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    required this.paymentMethod,
    this.taxExempt = false,
    this.sinpeVoucher,
    required this.createdAt,
    required this.updatedAt,
  });

  OrderEntity copyWith({
    String? id,
    String? userId,
    String? userName,
    List<OrderItemEntity>? items,
    double? subtotal,
    double? tax,
    double? total,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    bool? taxExempt,
    String? sinpeVoucher,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      taxExempt: taxExempt ?? this.taxExempt,
      sinpeVoucher: sinpeVoucher ?? this.sinpeVoucher,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
