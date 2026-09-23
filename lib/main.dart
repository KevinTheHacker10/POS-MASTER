import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_master/core/constants.dart';
import 'package:pos_master/nav.dart';
import 'package:pos_master/presentation/providers/auth_provider.dart';
import 'package:pos_master/presentation/providers/business_settings_provider.dart';
import 'package:pos_master/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main entry point for POS-MASTER.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final _router = AppRouter.router(ref);

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await ref.read(authProvider.notifier).initializeSampleData();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(businessSettingsProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(settings.palette.color),
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
