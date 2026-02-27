import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ble/application/ble_controller.dart';
import '../data/settings_repository.dart';

/// Shared preferences instance provider (initialized in main).
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden at startup');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(sharedPrefsProvider));
});

class AppSettings {
  final String serverBaseUrl;
  final bool mockMode;
  final int scanTimeoutSec;
  final int sampleRateHz;
  final String webAppUrl;
  final String postSessionNavigatePath;
  final bool enableAutoInjectToWeb;

  const AppSettings({
    this.serverBaseUrl = 'http://localhost:8080',
    this.mockMode = true,
    this.scanTimeoutSec = 10,
    this.sampleRateHz = 200,
    this.webAppUrl = 'http://172.30.1.67:3000',
    this.postSessionNavigatePath = '/workout-summary',
    this.enableAutoInjectToWeb = true,
  });

  AppSettings copyWith({
    String? serverBaseUrl,
    bool? mockMode,
    int? scanTimeoutSec,
    int? sampleRateHz,
    String? webAppUrl,
    String? postSessionNavigatePath,
    bool? enableAutoInjectToWeb,
  }) {
    return AppSettings(
      serverBaseUrl: serverBaseUrl ?? this.serverBaseUrl,
      mockMode: mockMode ?? this.mockMode,
      scanTimeoutSec: scanTimeoutSec ?? this.scanTimeoutSec,
      sampleRateHz: sampleRateHz ?? this.sampleRateHz,
      webAppUrl: webAppUrl ?? this.webAppUrl,
      postSessionNavigatePath:
          postSessionNavigatePath ?? this.postSessionNavigatePath,
      enableAutoInjectToWeb:
          enableAutoInjectToWeb ?? this.enableAutoInjectToWeb,
    );
  }
}

class SettingsController extends StateNotifier<AppSettings> {
  final SettingsRepository _repo;
  final Ref _ref;

  SettingsController(this._repo, this._ref)
    : super(
        AppSettings(
          serverBaseUrl: _repo.serverBaseUrl,
          mockMode: _repo.mockMode,
          scanTimeoutSec: _repo.scanTimeoutSec,
          sampleRateHz: _repo.sampleRateHz,
          webAppUrl: _repo.webAppUrl,
          postSessionNavigatePath: _repo.postSessionNavigatePath,
          enableAutoInjectToWeb: _repo.enableAutoInjectToWeb,
        ),
      );

  void setServerBaseUrl(String url) {
    _repo.serverBaseUrl = url;
    state = state.copyWith(serverBaseUrl: url);
  }

  void setMockMode(bool enabled) {
    _repo.mockMode = enabled;
    state = state.copyWith(mockMode: enabled);
    // Sync mock mode with BLE client
    _ref.read(isMockModeProvider.notifier).state = enabled;
  }

  void setScanTimeout(int seconds) {
    _repo.scanTimeoutSec = seconds;
    state = state.copyWith(scanTimeoutSec: seconds);
  }

  void setSampleRate(int hz) {
    _repo.sampleRateHz = hz;
    state = state.copyWith(sampleRateHz: hz);
  }

  void setWebAppUrl(String url) {
    _repo.webAppUrl = url;
    state = state.copyWith(webAppUrl: url);
  }

  void setPostSessionNavigatePath(String path) {
    _repo.postSessionNavigatePath = path;
    state = state.copyWith(postSessionNavigatePath: path);
  }

  void setEnableAutoInjectToWeb(bool enabled) {
    _repo.enableAutoInjectToWeb = enabled;
    state = state.copyWith(enableAutoInjectToWeb: enabled);
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) {
    final repo = ref.watch(settingsRepositoryProvider);
    return SettingsController(repo, ref);
  },
);
