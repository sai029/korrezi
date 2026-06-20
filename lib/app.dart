import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme.dart';

/// ルートアプリウィジェット。
///
/// ProviderScope は main.dart 側で wrap する。
/// 向き(縦/横)に応じて Child Mode ⇔ Common Mode のテーマを滑らかに切り替える。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Discovery Learning App',
      theme: AppTheme.childMode,
      routerConfig: appRouter,
      // 全ルート共通で向き連動テーマを適用（縦=childMode / 横=commonMode）。
      // TODO: Parent Mode ルートでは portraitTheme を AppTheme.parentMode に切替。
      builder: (context, child) => OrientationResponsiveTheme(
        portraitTheme: AppTheme.childMode,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
