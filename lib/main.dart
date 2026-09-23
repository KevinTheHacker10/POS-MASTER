import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matcha_lovers_506/core/constants.dart';
import 'package:matcha_lovers_506/nav.dart';
import 'package:matcha_lovers_506/presentation/providers/auth_provider.dart';
import 'package:matcha_lovers_506/presentation/providers/business_settings_provider.dart';
import 'package:matcha_lovers_506/theme.dart';
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: settings.palette.color,
      brightness: Brightness.light,
    );
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: lightTheme.copyWith(colorScheme: colorScheme),
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
