import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService(this._preferences);

  final SharedPreferences _preferences;

  static const String _themeModeKey = 'theme_mode';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _soundKey = 'sound_enabled';
  static const String _vibrationKey = 'vibration_enabled';
  static const String _languageKey = 'language';
  static const String _timeFormatKey = 'time_format';

  ThemeMode get themeMode {
    final value = _preferences.getString(_themeModeKey) ?? 'system';

    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  bool get notificationsEnabled =>
      _preferences.getBool(_notificationsKey) ?? true;

  bool get soundEnabled => _preferences.getBool(_soundKey) ?? false;

  bool get vibrationEnabled => _preferences.getBool(_vibrationKey) ?? true;

  String get language => _preferences.getString(_languageKey) ?? 'ru';

  String get timeFormat => _preferences.getString(_timeFormatKey) ?? '24h';

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    await _preferences.setString(_themeModeKey, value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _preferences.setBool(_notificationsKey, value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    await _preferences.setBool(_soundKey, value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _preferences.setBool(_vibrationKey, value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    await _preferences.setString(_languageKey, value);
    notifyListeners();
  }

  Future<void> setTimeFormat(String value) async {
    await _preferences.setString(_timeFormatKey, value);
    notifyListeners();
  }

  Future<void> resetSettings() async {
    await _preferences.clear();
    notifyListeners();
  }
}