import 'package:flutter/material.dart';

import 'core/router/app_router.dart';

/// ルートアプリウィジェット。
///
/// ProviderScope は main.dart 側で wrap する。
/// TODO: Step 3 完成後に AppTheme をここで適用する。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Discovery Learning App',
      routerConfig: appRouter,
      // TODO: theme / darkTheme に AppTheme を割り当てる。
    );
  }
}
