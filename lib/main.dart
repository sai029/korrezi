import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // TODO: Firebase 接続後にここで以下を実行する。
  //   WidgetsFlutterBinding.ensureInitialized();
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ※ firebase_options.dart は `flutterfire configure` でユーザーが生成する。
  runApp(const ProviderScope(child: MyApp()));
}
