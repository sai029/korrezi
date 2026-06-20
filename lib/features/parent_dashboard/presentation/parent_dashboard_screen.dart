import 'package:flutter/material.dart';

/// Parent Mode (スマホ・縦) — 会話のきっかけダッシュボード。
///
/// TODO: Step後続で実装。
/// - Interest Cloud / Topic Badges（最近の関心の可視化）
/// - Parent-Child Talk Prompts（AI生成の親子対話プロンプト）
/// - parent_summary（大人向け箇条書き要約）の表示
class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Parent Dashboard (TODO)')),
    );
  }
}
