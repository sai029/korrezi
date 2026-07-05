import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/models/news_pool.dart';
import '../../../shared/widgets/bouncy_tap.dart';
import '../../../shared/widgets/feed_thumbnail.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../../child_feed/application/child_feed_provider.dart';
import '../application/common_view_provider.dart';
import '../application/favorites_provider.dart';
import '../data/quiz_service.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  const ArticleDetailScreen({super.key, required this.newsId});
  final String newsId;

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 記事詳細を開いた時点で既読とみなす。
    Future.microtask(() {
      if (!mounted) return;
      ref.read(childFeedProvider.notifier).markAsViewed(widget.newsId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(commonViewProvider);

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('読み込みに失敗しました: $e')),
      ),
      data: (articles) {
        final article = articles.firstWhere(
          (a) => a.newsId == widget.newsId,
          orElse: () => articles.first,
        );
        return _DetailView(article: article);
      },
    );
  }
}

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.article});
  final NewsPool article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final genreColor = AppColors.accentForGenre(article.interestContext);
    final title = article.childTitleWithRuby.isNotEmpty
        ? article.childTitleWithRuby
        : article.originalTitle;

    final favoriteIds = ref.watch(favoritesProvider).valueOrNull ?? {};
    final isFavorited = favoriteIds.contains(article.newsId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.background,
            // ナビゲーションボタンを画像の明暗に依存しない円形ボタンに置き換える。
            automaticallyImplyLeading: false,
            leading: _NavCircleButton(
              icon: Icons.arrow_back,
              onPressed: () => context.pop(),
            ),
            actions: [
              AnimatedSwitcher(
                duration: AppMotion.durFast,
                child: _NavCircleButton(
                  key: ValueKey(isFavorited),
                  icon: isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? AppColors.brandPrimary : AppColors.ink700,
                  onPressed: () => ref
                      .read(favoritesProvider.notifier)
                      .toggle(article.newsId),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: FeedThumbnail(
                config: article.thumbnailConfig,
                fallbackIcon: Icons.article_outlined,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space5,
                AppSpacing.space5,
                AppSpacing.space5,
                AppSpacing.space8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Genre badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space1,
                    ),
                    decoration: BoxDecoration(
                      color: genreColor,
                      borderRadius: AppRadii.pill,
                    ),
                    child: Text(
                      '#${article.interestContext}',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.brandPrimaryInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  // Title with furigana
                  FuriganaText(
                    title,
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppColors.ink900,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  // Published date
                  Text(
                    _formatDate(article.publishedAt),
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.ink500),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space4),
                    child: Divider(
                      color: AppColors.ink300,
                      thickness: AppBorder.thin,
                    ),
                  ),
                  // Body with furigana
                  FuriganaText(
                    article.childBodyWithRuby,
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space6),
                  // 記事内容を元にした4択クイズ（読んだ内容の確認）。
                  _QuizSection(
                    newsId: article.newsId,
                    accentColor: genreColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}年${dt.month}月${dt.day}日';
}

// ── クイズ ─────────────────────────────────────────────────────────────────────
// 記事本文を元に Gemini が生成した4択クイズ（`generateQuiz` Cloud Function）。
// 回答すると即時に正誤を色分けし、なぜその答えかの解説を表示する。

class _QuizSection extends ConsumerStatefulWidget {
  const _QuizSection({required this.newsId, required this.accentColor});

  final String newsId;
  final Color accentColor;

  @override
  ConsumerState<_QuizSection> createState() => _QuizSectionState();
}

class _QuizSectionState extends ConsumerState<_QuizSection> {
  /// 選んだ選択肢。null なら未回答。
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final async = ref.watch(quizProvider(widget.newsId));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lg,
        border: Border.fromBorderSide(AppBorder.sideBase),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(textTheme),
          const SizedBox(height: AppSpacing.space4),
          async.when(
            loading: () => _loading(textTheme),
            error: (_, _) => _error(textTheme),
            data: (quiz) => _quizBody(textTheme, quiz),
          ),
        ],
      ),
    );
  }

  Widget _header(TextTheme textTheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.space2),
          decoration: BoxDecoration(
            color: widget.accentColor,
            borderRadius: AppRadii.md,
          ),
          child: const Icon(
            Icons.quiz_outlined,
            size: 20,
            color: AppColors.brandPrimaryInk,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Text(
          'よんでクイズ',
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.ink900,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _loading(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.space3),
          Text(
            'クイズをつくっています…',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.ink500),
          ),
        ],
      ),
    );
  }

  Widget _error(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'クイズをよういできませんでした。',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.ink700),
        ),
        const SizedBox(height: AppSpacing.space3),
        BouncyTap(
          onTap: () => ref.invalidate(quizProvider(widget.newsId)),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadii.pill,
              border: Border.fromBorderSide(AppBorder.sideThin),
            ),
            child: Text(
              'もういちど',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.ink900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quizBody(TextTheme textTheme, Quiz quiz) {
    final answered = _selected != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FuriganaText(
          quiz.question,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.ink900,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        for (int i = 0; i < quiz.choices.length; i++) ...[
          _ChoiceTile(
            label: quiz.choices[i],
            marker: _kMarkers[i % _kMarkers.length],
            state: _choiceState(quiz, i),
            onTap: answered ? null : () => setState(() => _selected = i),
          ),
          if (i < quiz.choices.length - 1)
            const SizedBox(height: AppSpacing.space3),
        ],
        if (answered) ...[
          const SizedBox(height: AppSpacing.space4),
          _explanation(textTheme, quiz),
        ],
      ],
    );
  }

  _ChoiceState _choiceState(Quiz quiz, int index) {
    if (_selected == null) return _ChoiceState.idle;
    if (index == quiz.answerIndex) return _ChoiceState.correct;
    if (index == _selected) return _ChoiceState.wrong;
    return _ChoiceState.muted;
  }

  Widget _explanation(TextTheme textTheme, Quiz quiz) {
    final correct = quiz.isCorrect(_selected!);
    final color = correct ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadii.md,
        border: Border.all(color: color, width: AppBorder.thin),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.circle_outlined : Icons.close,
                color: color,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                correct ? 'せいかい！' : 'ざんねん…',
                style: textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          FuriganaText(
            quiz.explanation,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.ink900,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _kMarkers = ['ア', 'イ', 'ウ', 'エ'];

/// 回答後の選択肢の見た目。
enum _ChoiceState { idle, correct, wrong, muted }

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.marker,
    required this.state,
    required this.onTap,
  });

  final String label;
  final String marker;
  final _ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final (Color bg, Color border, Color fg) = switch (state) {
      _ChoiceState.idle => (
          AppColors.surface,
          AppColors.ink900,
          AppColors.ink900,
        ),
      _ChoiceState.correct => (
          AppColors.success.withValues(alpha: 0.12),
          AppColors.success,
          AppColors.ink900,
        ),
      _ChoiceState.wrong => (
          AppColors.error.withValues(alpha: 0.12),
          AppColors.error,
          AppColors.ink900,
        ),
      _ChoiceState.muted => (
          AppColors.surfaceAlt,
          AppColors.ink300,
          AppColors.ink500,
        ),
    };

    final IconData? trailing = switch (state) {
      _ChoiceState.correct => Icons.circle_outlined,
      _ChoiceState.wrong => Icons.close,
      _ => null,
    };

    final tile = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.md,
        border: Border.all(color: border, width: AppBorder.thin),
      ),
      child: Row(
        children: [
          // 選択肢マーカー（ア・イ・ウ・エ）
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: border,
              borderRadius: AppRadii.sm,
            ),
            child: Text(
              marker,
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.brandPrimaryInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: FuriganaText(
              label,
              style: textTheme.bodyLarge?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.space2),
            Icon(trailing, color: border, size: 20),
          ],
        ],
      ),
    );

    if (onTap == null) return tile;
    return BouncyTap(onTap: onTap, child: tile);
  }
}

// ── ナビゲーション用円形ボタン ────────────────────────────────────────────────────
// SliverAppBar が画像（白・黒・カラー問わず）の上に乗るとき、
// 90% 不透明の白い円形背景＋影でアイコンの視認性を保証する。

class _NavCircleButton extends StatelessWidget {
  const _NavCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.90),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.ink900.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? AppColors.ink700,
          ),
        ),
      ),
    );
  }
}
