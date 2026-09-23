/// Core constants for the application
class AppConstants {
  static const String appName = 'POS-MASTER';
  static const String currency = '₡';

  // Storage keys
  static const String storageKeyUsers = 'users';
  static const String storageKeyProducts = 'products';
  static const String storageKeyOrders = 'orders';
  static const String storageKeyCurrentUser = 'current_user';
}

/// User roles
enum UserRole {
  admin,
  waiter,
  customer;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.waiter:
        return 'Mesero';
      case UserRole.customer:
        return 'Cliente autoservicio';
    }
  }
}

/// Product categories
enum ProductCategory {
  meals,
  drinks,
  groceries,
  desserts,
  services,
  other;

  String get displayName {
    switch (this) {
      case ProductCategory.meals:
        return 'Comidas';
      case ProductCategory.drinks:
        return 'Bebidas';
      case ProductCategory.groceries:
        return 'Abarrotes';
      case ProductCategory.desserts:
        return 'Postres';
      case ProductCategory.services:
        return 'Servicios';
      case ProductCategory.other:
        return 'Otros';
    }
  }

  String get icon {
    switch (this) {
      case ProductCategory.meals:
        return '🍽️';
      case ProductCategory.drinks:
        return '🥤';
      case ProductCategory.groceries:
        return '🛒';
      case ProductCategory.desserts:
        return '🍰';
      case ProductCategory.services:
        return '🛠️';
      case ProductCategory.other:
        return '📦';
    }
  }
}

/// Order status
enum OrderStatus {
  pending,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.completed:
        return 'Completado';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }
}

/// Payment method — SINPE Móvil agregado
enum PaymentMethod {
  cash,
  card,
  sinpe;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.sinpe:
        return 'SINPE Móvil';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.cash:
        return '💵';
      case PaymentMethod.card:
        return '💳';
      case PaymentMethod.sinpe:
        return '📱';
    }
  }

  /// SINPE requiere número de comprobante
  bool get requiresVoucher => this == PaymentMethod.sinpe;
}
