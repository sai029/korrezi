import 'package:go_router/go_router.dart';

import '../../features/child_feed/presentation/child_feed_screen.dart';
import '../../features/common_view/presentation/common_view_screen.dart';
import '../../features/parent_dashboard/presentation/parent_dashboard_screen.dart';

/// アプリのルーティング定義 (GoRouter)。
///
/// TODO: FCM Push通知のディープリンク対応を追加する。
/// 当面は3つの主要画面への静的ルートのみ定義した雛形。
final GoRouter appRouter = GoRouter(
  initialLocation: '/child',
  routes: [
    GoRoute(
      path: '/child',
      builder: (context, state) => const ChildFeedScreen(),
    ),
    GoRoute(
      path: '/common',
      builder: (context, state) => const CommonViewScreen(),
    ),
    GoRoute(
      path: '/parent',
      builder: (context, state) => const ParentDashboardScreen(),
    ),
  ],
);
