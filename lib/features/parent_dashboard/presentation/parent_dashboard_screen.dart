import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/bouncy_tap.dart';
import '../../../shared/widgets/dev_menu_button.dart';
import '../../../shared/widgets/settings_button.dart';
import '../../common_view/application/common_view_provider.dart';
import '../application/parent_dashboard_provider.dart';
import 'widgets/reading_lamp.dart';

/// Parent Mode (スマホ・縦) — 会話のきっかけダッシュボード。
///
/// レトロモダン新聞（ニュースピックス風）のトーン:
/// 太い濃紺ボーダー / 影なしフラット / ランキング風ナンバー / ハンコ風スタンプ。
///
/// - Masthead（題字バナー）
/// - 当日記事: 子どもの既読/未読 ＋ 子ども記事へのジャンプボタン
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('きょうの ようす'),
        actions: const [SettingsButton(), DevMenuButton()],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (data) {
          // 既読/未読は子ども画面と同じ源（childFeedProvider 由来）で突合する。
          // 子どもが記事を読むと即座にここへ連動する。
          final viewed = ref.watch(viewedNewsIdsProvider);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.space4),
            children: [
              const _Masthead(),
              const SizedBox(height: AppSpacing.space5),
              ReadingLampHero(
                ratio: data.readRatio(viewed),
                readCount: data.readCount(viewed),
                totalCount: data.totalCount,
              ),
              const SizedBox(height: AppSpacing.space6),
              const _SectionHeader('きょうの記事'),
              const _ReadLegend(),
              const SizedBox(height: AppSpacing.space3),
              for (final pa in data.articles)
                _ArticleCard(item: pa, isRead: viewed.contains(pa.newsId)),
              const SizedBox(height: AppSpacing.space5),
            ],
          );
        },
      ),
    );
  }
}

/// 新聞の題字バナー。濃紺の地に日付とワクワクするコピー。
class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: const BoxDecoration(
        color: AppColors.ink900,
        borderRadius: AppRadii.sm,
        border: Border.fromBorderSide(AppBorder.sideThick),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'こども プレス',
            style: textTheme.headlineSmall?.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: AppSpacing.space1),
          Row(
            children: [
              Text(
                _today(),
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.brandPrimaryInk.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              Text(
                '本日のダイジェスト',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.brandPrimaryInk.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _today() {
    final n = DateTime.now();
    const week = ['月', '火', '水', '木', '金', '土', '日'];
    return '${n.year}年${n.month}月${n.day}日（${week[n.weekday - 1]}）';
  }
}

/// 新聞見出しスタイルのセクション見出し（色ブロック ＋ 極太アンダーライン罫）。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 12, height: 24, color: AppColors.brandPrimary),
              const SizedBox(width: AppSpacing.space2),
              Text(text, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          const DecoratedBox(
            decoration: BoxDecoration(color: AppColors.ink900),
            child: SizedBox(height: AppBorder.base, width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// 既読/未読の凡例。
class _ReadLegend extends StatelessWidget {
  const _ReadLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _ReadStamp(isRead: false),
        SizedBox(width: AppSpacing.space2),
        //Text('まだ', style: TextStyle(color: AppColors.ink500)),
        SizedBox(width: AppSpacing.space4),
        _ReadStamp(isRead: true),
        SizedBox(width: AppSpacing.space2),
        //Text('よんだ', style: TextStyle(color: AppColors.ink500)),
      ],
    );
  }
}

/// ハンコ風の既読/未読スタンプ。わずかに傾けて遊び心を出す。
class _ReadStamp extends StatelessWidget {
  const _ReadStamp({required this.isRead});
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final color = isRead ? AppColors.brandPrimary : AppColors.ink900;
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.sm,
          border: Border.all(color: color, width: AppBorder.base),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRead ? Icons.check : Icons.fiber_new,
              size: 16,
              color: color,
            ),
            const SizedBox(width: AppSpacing.space1),
            Text(
              isRead ? 'よんだ' : 'よんでない',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: AppType.sizeCaption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 記事カード。ランキング風ナンバー ＋ カテゴリ・キッカー ＋ 既読/未読スタンプ ＋
/// 「子どもの記事を見にいく」ボタン。calm content 原則: 要約本文は body。
class _ArticleCard extends ConsumerWidget {
  const _ArticleCard({required this.item, required this.isRead});
  final ParentArticle item;

  /// 子どもがこの記事を読んだか（viewedNewsIdsProvider と突合済み）。
  final bool isRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final article = item.article;
    // 子どもが読んだ記事を親に見にいってほしいので、既読を強調し未読を落ち着かせる。
    final dim = !isRead;

    return Opacity(
      opacity: dim ? 0.72 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space3),
        decoration: BoxDecoration(
          color: dim ? AppColors.surfaceAlt : AppColors.surface,
          borderRadius: AppRadii.sm,
          border: Border.all(
            color: AppColors.ink900,
            width: dim ? AppBorder.thin : AppBorder.base,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ナンバー ＋ カテゴリ・キッカー ＋ 既読/未読スタンプ
            Row(
              children: [
                Text(
                  (item.feedIndex + 1).toString().padLeft(2, '0'),
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    '#${article.interestContext}',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _ReadStamp(isRead: isRead),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            // タイトル: titleMedium（Rounded）
            Text(article.originalTitle, style: textTheme.titleMedium),
            const Divider(height: AppSpacing.space5),
            // 要約本文: body（Noto Sans JP）・calm content 厳守
            Text(article.parentSummary, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.space4),
            // 子どもが読む本文（Common View）へ遷移
            SizedBox(
              width: double.infinity,
              child: BouncyTap(
                onTap: () => _openChildArticle(context, ref),
                child: FilledButton.icon(
                  onPressed: () => _openChildArticle(context, ref),
                  icon: const Icon(Icons.menu_book),
                  label: const Text('子どもの記事を見にいく'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChildArticle(BuildContext context, WidgetRef ref) {
    context.go('/common/article/${item.newsId}');
  }
}
