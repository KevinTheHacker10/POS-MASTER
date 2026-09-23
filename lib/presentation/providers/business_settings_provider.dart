import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matcha_lovers_506/domain/entities/business_settings.dart';
import 'package:matcha_lovers_506/presentation/providers/auth_provider.dart';

class BusinessSettingsNotifier extends Notifier<BusinessSettings> {
  static const _nameKey = 'business_name';
  static const _typeKey = 'business_type';
  static const _paletteKey = 'business_palette';
  static const _configuredKey = 'business_configured';

  @override
  BusinessSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return BusinessSettings(
      businessName: prefs.getString(_nameKey) ?? '',
      businessType: BusinessType.values.firstWhere(
        (value) => value.name == prefs.getString(_typeKey),
        orElse: () => BusinessType.restaurant,
      ),
      palette: AppPalette.values.firstWhere(
        (value) => value.name == prefs.getString(_paletteKey),
        orElse: () => AppPalette.forest,
      ),
      isConfigured: prefs.getBool(_configuredKey) ?? false,
    );
  }

  Future<void> save({
    required String businessName,
    required BusinessType businessType,
    required AppPalette palette,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final cleanName = businessName.trim();
    await Future.wait([
      prefs.setString(_nameKey, cleanName),
      prefs.setString(_typeKey, businessType.name),
      prefs.setString(_paletteKey, palette.name),
      prefs.setBool(_configuredKey, true),
    ]);
    state = BusinessSettings(
      businessName: cleanName,
      businessType: businessType,
      palette: palette,
      isConfigured: true,
    );
  }
}

final businessSettingsProvider =
    NotifierProvider<BusinessSettingsNotifier, BusinessSettings>(
  BusinessSettingsNotifier.new,
);
