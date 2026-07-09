import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTextScale { small, standard, large, extraLarge }

extension AppTextScaleValue on AppTextScale {
  /// Multiplier applied app-wide on top of the base font sizes used
  /// throughout Daily Thesis. 1.0 matches the original, unscaled design.
  double get factor => switch (this) {
        AppTextScale.small => 0.9,
        AppTextScale.standard => 1.0,
        AppTextScale.large => 1.15,
        AppTextScale.extraLarge => 1.3,
      };

  String get label => switch (this) {
        AppTextScale.small => 'Small',
        AppTextScale.standard => 'Default',
        AppTextScale.large => 'Large',
        AppTextScale.extraLarge => 'Extra Large',
      };
}

class TextScaleStorage {
  static const _key = 'text_scale_v1';

  Future<AppTextScale> load() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_key)) {
      case 'small':
        return AppTextScale.small;
      case 'large':
        return AppTextScale.large;
      case 'extraLarge':
        return AppTextScale.extraLarge;
      case 'standard':
      default:
        return AppTextScale.standard;
    }
  }

  Future<void> save(AppTextScale scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, scale.name);
  }
}

class TextScaleController {
  TextScaleController._();

  static final TextScaleController instance = TextScaleController._();

  final TextScaleStorage _storage = TextScaleStorage();
  final ValueNotifier<AppTextScale> notifier =
      ValueNotifier<AppTextScale>(AppTextScale.standard);

  Future<void> load() async {
    notifier.value = await _storage.load();
  }

  Future<void> setScale(AppTextScale scale) async {
    notifier.value = scale;
    await _storage.save(scale);
  }
}
