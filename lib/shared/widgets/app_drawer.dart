import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_service.dart';
import '../../core/device/device_role.dart';
import '../../core/firebase/firebase_providers.dart';
import '../../core/firebase/firestore_seeder.dart';
import '../../core/firebase/news_fetch_service.dart';
import '../../core/theme/tokens.dart';
import '../../features/child_feed/application/child_feed_provider.dart';
import '../../features/common_view/application/common_view_provider.dart';
import '../../features/parent_dashboard/application/parent_dashboard_provider.dart';

/// 開発用のモード切替ナビゲーション。
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = GoRouterState.of(context).uri.path;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ヘッダー: brandPrimary 背景、ロゴは M PLUS Rounded 1c
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.brandPrimary),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'AI Discovery\nLearning App',
                style: GoogleFonts.mPlusRounded1c(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandPrimaryInk,
                ),
              ),
            ),
          ),
          _tile(context, current, '/child', Icons.dynamic_feed,
              'Child Feed', 'タブレット・縦 / TikTok風フィード'),
          _tile(context, current, '/common', Icons.menu_book,
              'Common View', 'タブレット・横 / 親子で記事を読む'),
          _tile(context, current, '/parent', Icons.favorite,
              'Parent Dashboard', 'スマホ・縦 / 会話のきっかけ'),
          const Divider(),
          _roleTile(context, ref),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('サンプルデータ投入 (dev)'),
            subtitle: const Text('Firestore にサンプルを書き込み'),
            onTap: () => _seed(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.newspaper_outlined),
            title: const Text('ニュース取得 (GNews)'),
            subtitle: const Text('実記事を Cloud Functions 経由で取り込み'),
            onTap: () => _fetchNews(context, ref),
          ),
          _authTile(context, ref),
        ],
      ),
    );
  }

  /// この端末の役割（保護者/お子さん）の表示と変更。
  Widget _roleTile(BuildContext context, WidgetRef ref) {
    final role = ref.watch(deviceRoleProvider);
    if (role == null) return const SizedBox.shrink();
    final label = role == DeviceRole.parent ? '保護者用' : 'お子さん用';
    return ListTile(
      leading: const Icon(Icons.devices_outlined),
      title: const Text('この端末の役割'),
      subtitle: Text(label),
      onTap: () => _changeRole(context, ref, role),
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    DeviceRole current,
  ) async {
    final selected = await showDialog<DeviceRole>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('この端末の役割'),
        children: [
          for (final role in DeviceRole.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, role),
              child: Row(
                children: [
                  Icon(
                    role == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  const SizedBox(width: 12),
                  Text(role == DeviceRole.parent ? '保護者用' : 'お子さん用'),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || selected == current) return;
    if (!context.mounted) return;
    await ref.read(deviceRoleProvider.notifier).setRole(selected);
    if (!context.mounted) return;
    Navigator.pop(context); // ドロワーを閉じる
    context.go(selected.homePath);
  }

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
      },
    );
  }

  Widget _tile(BuildContext context, String current, String path,
      IconData icon, String title, String subtitle) {
    final selected = current == path;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.brandPrimary : null),
      title: Text(title),
      subtitle: Text(subtitle),
      selected: selected,
      selectedColor: AppColors.brandPrimary,
      onTap: () {
        Navigator.pop(context);
        if (!selected) context.go(path);
      },
    );
  }

  Future<void> _seed(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    Navigator.pop(context);

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
      messenger.showSnackBar(
        SnackBar(content: Text('投入に失敗しました: $e')),
      );
    }
  }

  Future<void> _fetchNews(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    Navigator.pop(context);

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
      final count = await container.read(newsFetchServiceProvider).fetchNews();
      container.invalidate(childFeedProvider);
      container.invalidate(commonViewProvider);
      container.invalidate(parentDashboardProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('$count 件取得しました。各画面に反映されます。')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('取得に失敗しました: $e')),
      );
    }
  }
}
