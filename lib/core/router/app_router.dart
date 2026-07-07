import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/child_feed/presentation/child_feed_screen.dart';
import '../../features/common_view/presentation/article_detail_screen.dart';
import '../../features/common_view/presentation/common_view_screen.dart';
import '../../features/parent_dashboard/presentation/parent_dashboard_screen.dart';
import '../../shared/widgets/shell_scaffold.dart';
import '../firebase/firebase_providers.dart';

/// アプリのルーティング定義 (GoRouter)。
///
/// 認証状態に応じて未ログイン時は `/login` へリダイレクトする。
/// Firebase 未初期化時（テスト/未設定環境）はゲートを無効化し、サンプルデータで
/// そのまま本編を表示する。
///
/// /child・/common・/parent は StatefulShellRoute.indexedStack で束ね、
/// 画面下部の NavigationBar で切り替える。
///
/// FCM Push 通知のディープリンクは `core/notifications/fcm_service.dart` が
/// 本 GoRouter の `.go('/common/article/<newsId>')` を呼んで実現する
/// （通知 data 契約: `{ "type": "article", "news_id": "<id>" }`）。
final appRouterProvider = Provider<GoRouter>((ref) {
  // 認証状態の変化で GoRouter を再評価させるための Listenable。
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/child',
    refreshListenable: refresh,
    redirect: (context, state) {
      // Firebase が無い環境では認証ゲートをかけない。
      if (!ref.read(firebaseReadyProvider)) return null;

      final loggedIn = ref.read(authStateProvider).valueOrNull != null;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn) return loggingIn ? null : '/login';
      if (loggingIn) return '/child';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/child',
              builder: (context, state) => const ChildFeedScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/common',
              builder: (context, state) => const CommonViewScreen(),
              routes: [
                GoRoute(
                  path: 'article/:newsId',
                  builder: (context, state) => ArticleDetailScreen(
                    newsId: state.pathParameters['newsId'] ?? '',
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/parent',
              builder: (context, state) => const ParentDashboardScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
