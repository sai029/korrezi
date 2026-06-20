import 'package:flutter/material.dart';

/// Child Mode (タブレット・縦) — TikTok風エンドレスフィード。
///
/// TODO: Step 5 で実装。
/// - PageView.builder(scrollDirection: Axis.vertical) による縦スクロール
/// - 没入型の大型サムネ + 動的テキストオーバーレイ
/// - Telemetry Agent: view_duration_seconds / swipe velocity を Firestore へ送信
class ChildFeedScreen extends StatelessWidget {
  const ChildFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Child Feed (TODO: Step 5)')),
    );
  }
}
