import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme.dart';

/// ルートアプリウィジェット。
///
/// ProviderScope は main.dart 側で wrap する。
/// 向き・モードによる色切替は行わず、常に childMode テーマを使用。
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // ルーター確定後に FCM を初期化する（初回メッセージでの遷移が可能になるよう
    // 最初のフレーム描画後に実行）。非対応環境では内部で no-op。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'コレッジ',
      theme: AppTheme.childMode,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
