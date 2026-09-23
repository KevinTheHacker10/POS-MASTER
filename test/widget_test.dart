import 'package:flutter_test/flutter_test.dart';
import 'package:matcha_lovers_506/core/constants.dart';
import 'package:matcha_lovers_506/data/repositories/order_repository.dart';
import 'package:matcha_lovers_506/domain/entities/business_settings.dart';
import 'package:matcha_lovers_506/domain/entities/order_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('public product identity is POS-MASTER', () {
    expect(AppConstants.appName, 'POS-MASTER');
  });

  test('catalog exposes generic multi-business categories', () {
    expect(ProductCategory.values, contains(ProductCategory.meals));
    expect(ProductCategory.values, contains(ProductCategory.groceries));
    expect(ProductCategory.values, contains(ProductCategory.services));
  });

  test('setup supports the requested business types', () {
    expect(BusinessType.values, contains(BusinessType.restaurant));
    expect(BusinessType.values, contains(BusinessType.soda));
    expect(BusinessType.values, contains(BusinessType.serviceWindow));
    expect(BusinessType.values, contains(BusinessType.grocery));
  });

  test('self-service is a distinct application role', () {
    expect(UserRole.customer.displayName, 'Cliente autoservicio');
  });

  test('self-service orders can remain pending until staff completes them',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = OrderRepository(preferences);
    const items = [
      OrderItemEntity(
        productId: 'coffee',
        productName: 'Café',
        price: 1000,
        quantity: 2,
      ),
    ];

    final order = await repository.createOrder(
      userId: 'self-service',
      userName: 'Cliente autoservicio',
      items: items,
      paymentMethod: PaymentMethod.cash,
      initialStatus: OrderStatus.pending,
    );

    expect(order, isNotNull);
    expect(order!.status, OrderStatus.pending);
    expect((await repository.getSalesStats())['totalOrders'], 0);

    await repository.updateOrderStatus(order.id, OrderStatus.completed);
    final completed = await repository.getAllOrders();
    expect(completed.single.status, OrderStatus.completed);
    expect((await repository.getSalesStats())['totalOrders'], 1);
  });
}
