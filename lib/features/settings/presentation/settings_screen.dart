import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/device/device_role.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/theme/tokens.dart';

/// アプリのバージョン情報。設定画面の「アプリ情報」で表示する。
final packageInfoProvider =
    FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

/// 設定画面。
///
/// - アカウント: サインイン中のアカウント表示とログアウト。
/// - この端末: 役割（保護者/お子さん）の切り替え（[deviceRoleProvider]）。
/// - アプリ情報: バージョン・ビルド番号。
///
/// 開発用の操作（サンプル投入・ニュース取得）は本画面には含めず、
/// 各画面 AppBar の [DevMenuButton] に残している。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const _SectionLabel('アカウント'),
          _AccountTile(),
          _LogoutTile(),
          const Divider(height: AppSpacing.space6),
          const _SectionLabel('この端末'),
          _RoleTile(),
          const Divider(height: AppSpacing.space6),
          const _SectionLabel('アプリ情報'),
          _VersionTile(),
          const SizedBox(height: AppSpacing.space5),
        ],
      ),
    );
  }
}

/// セクション見出し（小さめ・ブランド色）。
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space2,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

/// サインイン中のアカウント表示。
class _AccountTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(firebaseReadyProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    final String primary;
    final String secondary;
    if (!ready) {
      primary = 'サンプルモード';
      secondary = 'Firebase 未接続';
    } else if (user == null) {
      primary = '未ログイン';
      secondary = '';
    } else if (user.isAnonymous) {
      primary = 'ゲスト';
      secondary = '匿名でご利用中';
    } else {
      primary = user.displayName ?? user.email ?? user.uid;
      secondary = user.email != null && user.displayName != null
          ? user.email!
          : 'Google アカウント';
    }

    return ListTile(
      leading: const Icon(Icons.account_circle_outlined,
          color: AppColors.brandPrimary),
      title: Text(primary),
      subtitle: secondary.isEmpty ? null : Text(secondary),
    );
  }
}

/// ログアウト。サインイン中のみ表示する。
class _LogoutTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(firebaseReadyProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    if (!ready || user == null) return const SizedBox.shrink();

    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('ログアウト'),
      onTap: () => _confirmLogout(context, ref),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウトしますか？'),
        content: const Text('もう一度ご利用になるにはログインが必要です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // サインアウトすると authState が null になり、GoRouter の redirect が
    // /login へ誘導する（本画面からの明示的な遷移は不要）。
    await ref.read(authServiceProvider).signOut();
  }
}

/// この端末の役割（保護者/お子さん）の表示と切り替え。
class _RoleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(deviceRoleProvider);
    final label = switch (role) {
      DeviceRole.parent => '保護者用',
      DeviceRole.child => 'お子さん用',
      null => '未設定',
    };

    return ListTile(
      leading: const Icon(Icons.devices_outlined, color: AppColors.brandPrimary),
      title: const Text('この端末の役割'),
      subtitle: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _changeRole(context, ref, role),
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    DeviceRole? current,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
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
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Text(role == DeviceRole.parent ? '保護者用' : 'お子さん用'),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || selected == current) return;
    await ref.read(deviceRoleProvider.notifier).setRole(selected);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'この端末を${selected == DeviceRole.parent ? '保護者用' : 'お子さん用'}に設定しました',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// アプリのバージョン表示。
class _VersionTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider);
    final subtitle = info.when(
      loading: () => '取得中…',
      error: (_, _) => '不明',
      data: (i) => '${i.version} (${i.buildNumber})',
    );
    return ListTile(
      leading: const Icon(Icons.info_outline, color: AppColors.brandPrimary),
      title: const Text('バージョン'),
      subtitle: Text(subtitle),
    );
  }
}
