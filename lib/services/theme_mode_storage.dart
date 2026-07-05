import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeStorage {
  static const _key = 'theme_mode_v1';

  Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }
}

class ThemeModeController {
  ThemeModeController._();

  static final ThemeModeController instance = ThemeModeController._();

  final ThemeModeStorage _storage = ThemeModeStorage();
  final ValueNotifier<ThemeMode> notifier = ValueNotifier<ThemeMode>(ThemeMode.system);

  Future<void> load() async {
    notifier.value = await _storage.load();
  }

  Future<void> setMode(ThemeMode mode) async {
    notifier.value = mode;
    await _storage.save(mode);
  }
}