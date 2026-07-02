import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/models/news_pool.dart';
import '../../../shared/widgets/feed_thumbnail.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../../child_feed/application/child_feed_provider.dart';
import '../application/common_view_provider.dart';
import '../application/favorites_provider.dart';

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
