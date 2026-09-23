import 'package:pos_master/core/constants.dart';
import 'package:pos_master/domain/entities/order_entity.dart';

/// Order item model
class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.productId,
    required super.productName,
    required super.price,
    required super.quantity,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
      };

  factory OrderItemModel.fromEntity(OrderItemEntity entity) =>
      OrderItemModel(
        productId: entity.productId,
        productName: entity.productName,
        price: entity.price,
        quantity: entity.quantity,
      );
}

/// Order model - Data layer
class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.items,
    required super.subtotal,
    required super.tax,
    required super.total,
    required super.status,
    required super.paymentMethod,
    super.taxExempt = false,
    super.sinpeVoucher,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      items: (json['items'] as List)
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      taxExempt: json['taxExempt'] as bool? ?? false,
      sinpeVoucher: json['sinpeVoucher'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'items': items.map((i) => OrderItemModel.fromEntity(i).toJson()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'status': status.name,
        'paymentMethod': paymentMethod.name,
        'taxExempt': taxExempt,
        'sinpeVoucher': sinpeVoucher,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory OrderModel.fromEntity(OrderEntity entity) => OrderModel(
        id: entity.id,
        userId: entity.userId,
        userName: entity.userName,
        items: entity.items,
        subtotal: entity.subtotal,
        tax: entity.tax,
        total: entity.total,
        status: entity.status,
        paymentMethod: entity.paymentMethod,
        taxExempt: entity.taxExempt,
        sinpeVoucher: entity.sinpeVoucher,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}