import 'package:flutter_test/flutter_test.dart';
import 'package:matcha_lovers_506/core/constants.dart';
import 'package:matcha_lovers_506/domain/entities/business_settings.dart';

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
}
