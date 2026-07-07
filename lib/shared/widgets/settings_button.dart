import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// AppBar 用の設定ボタン。設定画面（/settings）へ遷移する。
///
/// 役割切り替え・アカウント/ログアウト・アプリ情報をまとめた [SettingsScreen] を開く。
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: '設定',
      onPressed: () => context.push('/settings'),
    );
  }
}
