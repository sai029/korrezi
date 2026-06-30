import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/bouncy_tap.dart';
import '../../../shared/widgets/dev_menu_button.dart';
import '../application/parent_dashboard_provider.dart';

/// Parent Mode (スマホ・縦) — 会話のきっかけダッシュボード。
///
/// レトロモダン新聞（ニュースピックス風）のトーン:
/// 太い濃紺ボーダー / 影なしフラット / ランキング風ナンバー / ハンコ風スタンプ。
///
/// - Masthead（題字バナー）
/// - Interest Cloud（最近の関心）
/// - 親子トークプロンプト（AI生成）
/// - 当日記事: 子どもの既読/未読 ＋ 子ども記事へのジャンプボタン
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('きょうの ようす'),
        actions: const [DevMenuButton()],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            const _Masthead(),
            const SizedBox(height: AppSpacing.space5),
            const _SectionHeader('最近わきあがっている好奇心'),
            _InterestCloud(interests: data.profile.currentInterests),
            const SizedBox(height: AppSpacing.space6),
            const _SectionHeader('親子トークのきっかけ'),
            ...data.talkPrompts.map((p) => _TalkPromptCard(prompt: p)),
            const SizedBox(height: AppSpacing.space6),
            const _SectionHeader('きょうの記事'),
            const _ReadLegend(),
            const SizedBox(height: AppSpacing.space3),
            for (final pa in data.articles) _ArticleCard(item: pa),
            const SizedBox(height: AppSpacing.space5),
          ],
        ),
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
          const SizedBox(height: AppSpacing.space2),
          Text(
            'きょう、子どものあたまの中をのぞいてみよう。',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.brandPrimaryInk,
            ),
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

/// 興味スコアを角ばったステッカー Chip 化（スコアが高いほど大きく・アンバー寄り）。
class _InterestCloud extends StatelessWidget {
  const _InterestCloud({required this.interests});
  final Map<String, int> interests;

  @override
  Widget build(BuildContext context) {
    final entries = interests.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
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
                  AppColors.surface,
                  AppColors.accent.withValues(alpha: 0.55),
                  e.value / 100,
                ),
                borderRadius: AppRadii.sm,
                border: Border.all(
                  color: AppColors.ink900,
                  width: AppBorder.thin,
                ),
              ),
              child: Text(
                '#${e.key}',
                style: TextStyle(
                  fontSize: AppType.sizeCaption + e.value * 0.10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 会話プロンプトカード。左に赤い極太バー＋引用符で「見出し」感を出す。
class _TalkPromptCard extends StatelessWidget {
  const _TalkPromptCard({required this.prompt});
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      // 非均一ボーダー（左だけ太い）には borderRadius を付けられないため角は四角。
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: AppColors.brandPrimary, width: 6),
          top: AppBorder.sideThin,
          right: AppBorder.sideThin,
          bottom: AppBorder.sideThin,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.brandPrimary,
              height: 1.0,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(prompt, style: Theme.of(context).textTheme.bodyMedium),
          ),
          BouncyTap(
            onTap: () {
              // TODO: お気に入り保存 / 後で話す リスト追加。
            },
            child: const Icon(
              Icons.push_pin_outlined,
              color: AppColors.brandPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 記事カード。ランキング風ナンバー ＋ カテゴリ・キッカー ＋ 既読/未読スタンプ ＋
/// 「子どもの記事を見にいく」ボタン。calm content 原則: 要約本文は body。
class _ArticleCard extends ConsumerWidget {
  const _ArticleCard({required this.item});
  final ParentArticle item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final article = item.article;
    // 子どもが読んだ記事を親に見にいってほしいので、既読を強調し未読を落ち着かせる。
    final dim = !item.isRead;

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
                _ReadStamp(isRead: item.isRead),
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
