import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/device/device_role.dart';
import 'core/firebase/firebase_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 初期化。失敗してもサンプルデータでアプリは起動を継続する
  // （未設定プラットフォームや権限未整備でも開発を止めないため）。
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase init failed, falling back to sample data: $e');
  }

  // この端末の役割（保護者 / お子さん）を復元する。オンボーディングで確定する
  // まで null で、その間はルーターが /onboarding へ誘導する。
  DeviceRole? storedRole;
  try {
    final prefs = await SharedPreferences.getInstance();
    storedRole = DeviceRole.fromName(prefs.getString(DeviceRoleController.prefsKey));
  } catch (e) {
    debugPrint('SharedPreferences load failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        firebaseReadyProvider.overrideWithValue(firebaseReady),
        bootstrapDeviceRoleProvider.overrideWithValue(storedRole),
      ],
      child: const MyApp(),
    ),
  );
}
