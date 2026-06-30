import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_service.dart';
import '../../core/firebase/firebase_providers.dart';
import '../../core/firebase/firestore_seeder.dart';
import '../../core/firebase/news_fetch_service.dart';
import '../../features/child_feed/application/child_feed_provider.dart';
import '../../features/common_view/application/common_view_provider.dart';
import '../../features/parent_dashboard/application/parent_dashboard_provider.dart';

/// AppBar アクション用の開発・アカウントメニュー。
/// ドロワーから移植したサンプルデータ投入・ニュース取得・ログアウトを提供する。
class DevMenuButton extends ConsumerWidget {
  const DevMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_Action>(
      onSelected: (action) => _handle(context, ref, action),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _Action.seed,
          child: ListTile(
            leading: Icon(Icons.cloud_upload_outlined),
            title: Text('サンプルデータ投入 (dev)'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _Action.news,
          child: ListTile(
            leading: Icon(Icons.newspaper_outlined),
            title: Text('ニュース取得 (GNews)'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _Action.logout,
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('ログアウト'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _handle(
      BuildContext context, WidgetRef ref, _Action action) async {
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);

    switch (action) {
      case _Action.seed:
        if (!container.read(firebaseReadyProvider)) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Firebase 未初期化のため投入できません')),
          );
          return;
        }
        messenger.showSnackBar(
          const SnackBar(content: Text('サンプルデータを投入中…')),
        );
        try {
          final userId = container.read(currentUserIdProvider);
          await container.read(firestoreSeederProvider).seedAll(userId);
          container.invalidate(childFeedProvider);
          container.invalidate(commonViewProvider);
          container.invalidate(parentDashboardProvider);
          messenger.showSnackBar(
            const SnackBar(content: Text('投入しました。各画面に反映されます。')),
          );
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('投入に失敗しました: $e')));
        }

      case _Action.news:
        if (!container.read(firebaseReadyProvider)) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Firebase 未初期化のため取得できません')),
          );
          return;
        }
        messenger.showSnackBar(
          const SnackBar(content: Text('ニュースを取得中…')),
        );
        try {
          final count =
              await container.read(newsFetchServiceProvider).fetchNews();
          container.invalidate(childFeedProvider);
          container.invalidate(commonViewProvider);
          container.invalidate(parentDashboardProvider);
          messenger.showSnackBar(
            SnackBar(content: Text('$count 件取得しました。各画面に反映されます。')),
          );
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('取得に失敗しました: $e')));
        }

      case _Action.logout:
        await ref.read(authServiceProvider).signOut();
    }
  }
}

enum _Action { seed, news, logout }
