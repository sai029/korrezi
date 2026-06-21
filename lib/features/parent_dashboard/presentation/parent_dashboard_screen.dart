import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/models/news_pool.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/bouncy_tap.dart';
import '../application/parent_dashboard_provider.dart';

/// Parent Mode (スマホ・縦) — 会話のきっかけダッシュボード。
///
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
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            _SectionTitle('最近わきあがっている好奇心'),
            _InterestCloud(interests: data.profile.currentInterests),
            const SizedBox(height: AppSpacing.space5),
            _SectionTitle('親子トークのきっかけ'),
            ...data.talkPrompts.map((p) => _TalkPromptCard(prompt: p)),
            const SizedBox(height: AppSpacing.space5),
            _SectionTitle('きょうの記事（保護者向け要約）'),
            ...data.articles.map((a) => _ArticleSummaryCard(article: a)),
          ],
        ),
      ),
    );
  }
}

/// セクション見出し（M PLUS Rounded 1c / テーマ titleLarge から自動適用）。
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.space3),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );
}

/// 興味スコアをバッジ化（スコアが高いほど大きく・accent 寄りの色）。
/// ステッカー風 Chip: radiusPill + accent 淡ティント + elev1。
class _InterestCloud extends StatelessWidget {
  const _InterestCloud({required this.interests});
  final Map<String, int> interests;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final entries = interests.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: AppSpacing.space2 + 2,
      runSpacing: AppSpacing.space2 + 2,
      children: [
        for (final e in entries)
          BouncyTap(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space1 + 2,
              ),
              decoration: BoxDecoration(
                color: Color.lerp(
                  AppColors.surfaceAlt,
                  accent.withValues(alpha: 0.25),
                  e.value / 100,
                ),
                borderRadius: AppRadii.pill,
                border: Border.all(
                  color: AppColors.brandPrimaryInk.withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: AppElevation.elev1(),
              ),
              child: Text(
                '#${e.key}',
                style: TextStyle(
                  fontSize: AppType.sizeCaption + e.value * 0.12,
                  color: AppColors.ink900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 会話プロンプトカード。Card 仕様: surface / radiusLg / elev1 / space4 padding。
class _TalkPromptCard extends StatelessWidget {
  const _TalkPromptCard({required this.prompt});
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lg,
        boxShadow: AppElevation.elev1(),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        leading: const Icon(Icons.chat_bubble_outline,
            color: AppColors.brandPrimary),
        title: Text(
          prompt,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: BouncyTap(
          onTap: () {
            // TODO: お気に入り保存 / 後で話す リスト追加。
          },
          child: const Icon(Icons.push_pin_outlined,
              color: AppColors.brandPrimary),
        ),
      ),
    );
  }
}

/// 記事要約カード。calm content 原則: 本文は body（Noto Sans JP）。
class _ArticleSummaryCard extends StatelessWidget {
  const _ArticleSummaryCard({required this.article});
  final NewsPool article;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lg,
        boxShadow: AppElevation.elev1(),
      ),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル: titleMedium（Rounded）
          Text(article.originalTitle, style: textTheme.titleMedium),
          const Divider(height: AppSpacing.space4),
          // 要約本文: body（Noto Sans JP）・calm content 厳守
          Text(article.parentSummary, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
