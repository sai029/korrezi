import 'package:flutter/material.dart';

/// Common Mode (タブレット・横) — 親子同時閲覧用の2カラム分割ビュー。
///
/// TODO: 後続で実装。
/// - OrientationBuilder で横向き遷移を検知し commonModeTheme へ切替（AnimatedTheme）
/// - 2カラム分割: 左=動的ナビゲーショングリッド / 右=記事リーダー（ルビ/Furiganaレンダリング）
class CommonViewScreen extends StatelessWidget {
  const CommonViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Common View (TODO)')),
    );
  }
}
