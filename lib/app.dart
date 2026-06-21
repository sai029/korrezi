import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme.dart';

/// ルートアプリウィジェット。
///
/// ProviderScope は main.dart 側で wrap する。
/// 向き・モードによる色切替は行わず、常に childMode テーマを使用。
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'AI Discovery Learning App',
      theme: AppTheme.childMode,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
