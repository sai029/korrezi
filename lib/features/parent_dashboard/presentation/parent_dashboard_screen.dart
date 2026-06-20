import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/news_pool.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../application/parent_dashboard_provider.dart';

/// Parent Mode (スマホ・縦) — 会話のきっかけダッシュボード。
///
/// 監視/グラフではなく、温かい「会話のきっかけ」を提示する:
/// - Interest Cloud / Topic Badges（最近の関心）
/// - 親子トークプロンプト（AI生成）
/// - 当日の記事の大人向け要約（parent_summary）
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentDashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('きょうの ようす')),
      drawer: const AppDrawer(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle('最近わきあがっている好奇心'),
            _InterestCloud(interests: data.profile.currentInterests),
            const SizedBox(height: 24),
            _SectionTitle('親子トークのきっかけ'),
            ...data.talkPrompts.map((p) => _TalkPromptCard(prompt: p)),
            const SizedBox(height: 24),
            _SectionTitle('きょうの記事（保護者向け要約）'),
            ...data.articles.map((a) => _ArticleSummaryCard(article: a)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );
}

/// 興味スコアをバッジ化（スコアが高いほど大きく表示）。
class _InterestCloud extends StatelessWidget {
  const _InterestCloud({required this.interests});
  final Map<String, int> interests;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = interests.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final e in entries)
          Chip(
            label: Text(
              '#${e.key}',
              style: TextStyle(fontSize: 12 + e.value * 0.12), // スコアでサイズ可変
            ),
            backgroundColor: Color.lerp(
                scheme.surfaceContainerHighest, scheme.primaryContainer,
                e.value / 100),
          ),
      ],
    );
  }
}

class _TalkPromptCard extends StatelessWidget {
  const _TalkPromptCard({required this.prompt});
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.chat_bubble_outline),
        title: Text(prompt),
        trailing: IconButton(
          icon: const Icon(Icons.push_pin_outlined),
          onPressed: () {
            // TODO: お気に入り保存 / 後で話す リスト追加。
          },
        ),
      ),
    );
  }
}

class _ArticleSummaryCard extends StatelessWidget {
  const _ArticleSummaryCard({required this.article});
  final NewsPool article;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article.originalTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            Text(article.parentSummary),
          ],
        ),
      ),
    );
  }
}
