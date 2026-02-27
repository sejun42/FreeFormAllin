import 'package:shared_preferences/shared_preferences.dart';

/// Persists user settings to SharedPreferences.
class SettingsRepository {
  static const _keyServerUrl = 'server_base_url';
  static const _keyMockMode = 'mock_mode';
  static const _keyScanTimeout = 'scan_timeout_sec';
  static const _keySampleRate = 'sample_rate_hz';
  static const _keyWebAppUrl = 'web_app_url';
  static const _keyPostSessionPath = 'post_session_navigate_path';
  static const _keyAutoInjectToWeb = 'enable_auto_inject_to_web';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  String get serverBaseUrl =>
      _prefs.getString(_keyServerUrl) ?? 'http://localhost:8080';
  set serverBaseUrl(String value) => _prefs.setString(_keyServerUrl, value);

  bool get mockMode => _prefs.getBool(_keyMockMode) ?? true;
  set mockMode(bool value) => _prefs.setBool(_keyMockMode, value);

  int get scanTimeoutSec => _prefs.getInt(_keyScanTimeout) ?? 10;
  set scanTimeoutSec(int value) => _prefs.setInt(_keyScanTimeout, value);

  int get sampleRateHz => _prefs.getInt(_keySampleRate) ?? 200;
  set sampleRateHz(int value) => _prefs.setInt(_keySampleRate, value);

  String get webAppUrl =>
      _prefs.getString(_keyWebAppUrl) ?? 'https://freeformdb-c3667.web.app';
  set webAppUrl(String value) => _prefs.setString(_keyWebAppUrl, value);

  String get postSessionNavigatePath =>
      _prefs.getString(_keyPostSessionPath) ?? '/workout-summary';
  set postSessionNavigatePath(String value) =>
      _prefs.setString(_keyPostSessionPath, value);

  bool get enableAutoInjectToWeb =>
      _prefs.getBool(_keyAutoInjectToWeb) ?? true;
  set enableAutoInjectToWeb(bool value) =>
      _prefs.setBool(_keyAutoInjectToWeb, value);
}
