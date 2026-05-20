import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'features/settings/application/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is optional for local BLE hardware testing. Production builds can
  // provide android/app/google-services.json and initialize normally.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Continue without Firebase so BLE scanning/recording can be tested.
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const FreeFormApp(),
    ),
  );
}
