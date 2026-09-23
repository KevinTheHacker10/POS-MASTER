import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_master/core/constants.dart';
import 'package:pos_master/main.dart';
import 'package:pos_master/presentation/providers/auth_provider.dart';
import 'package:pos_master/presentation/screens/login_screen.dart';
import 'package:pos_master/presentation/screens/setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _configuredBusiness = <String, Object>{
  'business_name': 'Negocio de Prueba',
  'business_type': 'restaurant',
  'business_palette': 'forest',
  'business_configured': true,
};

Future<SharedPreferences> _preferences(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  for (final viewport in <String, Size>{
    'phone': const Size(320, 568),
    'tablet': const Size(768, 1024),
    'desktop': const Size(1440, 900),
  }.entries) {
    testWidgets('setup is usable without overflow on ${viewport.key}',
        (tester) async {
      _setViewport(tester, viewport.value);
      final preferences = await _preferences({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: const MaterialApp(home: SetupScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configura tu negocio'), findsOneWidget);
      expect(find.text('Guardar y continuar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('login is usable without overflow on ${viewport.key}',
        (tester) async {
      _setViewport(tester, viewport.value);
      final preferences = await _preferences(_configuredBusiness);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Negocio de Prueba'), findsWidgets);
      expect(find.text('Entrar como cliente · Autoservicio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('customer can enter self-service mode from the login screen',
      (tester) async {
    _setViewport(tester, const Size(390, 844));
    final preferences = await _preferences(_configuredBusiness);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como cliente · Autoservicio'));
    await tester.pumpAndSettle();

    expect(find.text('Negocio de Prueba'), findsOneWidget);
    expect(find.text('Historial'), findsNothing);
    expect(find.text('Admin'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final account in <({String username, String password, bool isAdmin})>[
    (username: 'admin', password: 'admin123', isAdmin: true),
    (username: 'mesero', password: 'mesero123', isAdmin: false),
  ]) {
    testWidgets('${account.username} receives the correct POS permissions',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      final preferences = await _preferences(_configuredBusiness);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), account.username);
      await tester.enterText(find.byType(TextField).at(1), account.password);
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Historial'), findsOneWidget);
      expect(
        find.byTooltip('Panel Admin'),
        account.isAdmin ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('self-service completes the catalog-to-pending-order flow',
      (tester) async {
    _setViewport(tester, const Size(1440, 900));
    final now = DateTime(2026, 1, 1).toIso8601String();
    final preferences = await _preferences({
      ..._configuredBusiness,
      AppConstants.storageKeyProducts: [
        jsonEncode({
          'id': 'meal-1',
          'name': 'Casado de prueba',
          'price': 3500,
          'category': ProductCategory.meals.name,
          'description': 'Producto para validar el flujo de venta',
          'isAvailable': true,
          'imageUrl': '🍽️',
          'createdAt': now,
          'updatedAt': now,
        }),
      ],
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como cliente · Autoservicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Casado de prueba'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Procesar Pago'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enviar Pedido'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar Pedido'));
    await tester.pumpAndSettle();

    expect(find.text('¡Pedido Enviado!'), findsOneWidget);
    final storedOrders =
        preferences.getStringList(AppConstants.storageKeyOrders) ?? [];
    expect(storedOrders, hasLength(1));
    expect(jsonDecode(storedOrders.single)['status'], OrderStatus.pending.name);
    expect(tester.takeException(), isNull);
  });
}
