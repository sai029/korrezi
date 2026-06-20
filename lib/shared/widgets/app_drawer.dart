import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/firebase/firebase_providers.dart';
import '../../core/firebase/firestore_seeder.dart';
import '../../features/child_feed/application/child_feed_provider.dart';
import '../../features/common_view/application/common_view_provider.dart';
import '../../features/parent_dashboard/application/parent_dashboard_provider.dart';

/// 開発用のモード切替ナビゲーション。
///
/// 本番ではデバイス（タブレット/スマホ）と向きでモードが決まるが、開発中は
/// 1画面で3モードを行き来できるよう Drawer で導線を提供する。
/// あわせて Firestore へサンプルデータを投入する dev アクションも持つ。
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = GoRouterState.of(context).uri.path;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Text('AI Discovery\nLearning App',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          _tile(context, current, '/child', Icons.dynamic_feed,
              'Child Feed', 'タブレット・縦 / TikTok風フィード'),
          _tile(context, current, '/common', Icons.menu_book,
              'Common View', 'タブレット・横 / 親子で記事を読む'),
          _tile(context, current, '/parent', Icons.favorite,
              'Parent Dashboard', 'スマホ・縦 / 会話のきっかけ'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('サンプルデータ投入 (dev)'),
            subtitle: const Text('Firestore にサンプルを書き込み'),
            onTap: () => _seed(context, ref),
          ),
          _authTile(context, ref),
        ],
      ),
    );
  }

  /// ログイン中ユーザーの表示とログアウト。
  Widget _authTile(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final label = user.isAnonymous
        ? 'ゲスト'
        : (user.displayName ?? user.email ?? user.uid);
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('ログアウト'),
      subtitle: Text(label),
      onTap: () async {
        Navigator.pop(context);
        await ref.read(authServiceProvider).signOut();
        // 以降はルーターの redirect が /login へ戻す。
      },
    );
  }

  Widget _tile(BuildContext context, String current, String path,
      IconData icon, String title, String subtitle) {
    final selected = current == path;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      selected: selected,
      onTap: () {
        Navigator.pop(context);
        if (!selected) context.go(path);
      },
    );
  }

  /// Firestore へサンプルデータを投入し、各プロバイダを再取得させる。
  Future<void> _seed(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);

    if (!ref.read(firebaseReadyProvider)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Firebase 未初期化のため投入できません')),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('サンプルデータを投入中…')),
    );
    try {
      final userId = ref.read(currentUserIdProvider);
      await ref.read(firestoreSeederProvider).seedAll(userId);

      // 投入後に各画面のデータを再取得させる。
      ref.invalidate(childFeedProvider);
      ref.invalidate(commonViewProvider);
      ref.invalidate(parentDashboardProvider);

      messenger.showSnackBar(
        const SnackBar(content: Text('投入しました。各画面に反映されます。')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('投入に失敗しました: $e')),
      );
    }
  }
}
