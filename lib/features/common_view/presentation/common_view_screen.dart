import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/models/news_pool.dart';
import '../../../shared/widgets/dev_menu_button.dart';
import '../../../shared/widgets/feed_thumbnail.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../application/common_view_provider.dart';
import '../application/favorites_provider.dart';

class CommonViewScreen extends ConsumerStatefulWidget {
  const CommonViewScreen({super.key});

  @override
  ConsumerState<CommonViewScreen> createState() => _CommonViewScreenState();
}

class _CommonViewScreenState extends ConsumerState<CommonViewScreen> {
  String? _selectedGenre;

  List<NewsPool> _filtered(List<NewsPool> all) {
    if (_selectedGenre == null) return all;
    return all.where((a) => a.interestContext == _selectedGenre).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(commonViewProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ニュース'),
        actions: const [DevMenuButton()],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (articles) {
          if (articles.isEmpty) {
            return const Center(child: Text('まだ記事がありません'));
          }
          final genres = articles
              .map((a) => a.interestContext)
              .where((g) => g.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final filtered = _filtered(articles);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GenreBar(
                genres: genres,
                selected: _selectedGenre,
                onSelect: (g) => setState(() => _selectedGenre = g),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('この条件の記事はありません'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.space3,
                          AppSpacing.space3,
                          AppSpacing.space3,
                          AppSpacing.space8,
                        ),
                        child: _NewspaperGrid(articles: filtered),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Genre filter bar ──────────────────────────────────────────────────────────

class _GenreBar extends StatelessWidget {
  const _GenreBar({
    required this.genres,
    required this.selected,
    required this.onSelect,
  });

  final List<String> genres;
  final String? selected;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        child: Row(
          children: [
            _GenreChip(
              label: 'おすすめ',
              selected: selected == null,
              color: AppColors.brandPrimary,
              onTap: () => onSelect(null),
            ),
            const SizedBox(width: AppSpacing.space2),
            ...genres.map(
              (g) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.space2),
                child: _GenreChip(
                  label: g,
                  selected: selected == g,
                  color: AppColors.accentForGenre(g),
                  onTap: () => onSelect(selected == g ? null : g),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.durFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: AppRadii.pill,
          border: Border.all(
            color: selected ? color : AppColors.ink300,
            width: AppBorder.thin,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.brandPrimaryInk : AppColors.ink700,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}

// ── Newspaper grid ────────────────────────────────────────────────────────────

class _NewspaperGrid extends ConsumerWidget {
  const _NewspaperGrid({required this.articles});
  final List<NewsPool> articles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewedIds = ref.watch(viewedNewsIdsProvider);
    final favoriteIds = ref.watch(favoritesProvider).valueOrNull ?? {};

    Widget card(NewsPool a) {
      final isViewed = viewedIds.contains(a.newsId);
      final isFavorited = favoriteIds.contains(a.newsId);
      return _ArticleCard(
        article: a,
        isViewed: isViewed,
        isFavorited: isFavorited,
        onToggleFavorite: () =>
            ref.read(favoritesProvider.notifier).toggle(a.newsId),
      );
    }

    final rows = <Widget>[];
    int i = 0;

    // Hero: full-width feature article
    if (i < articles.length) {
      final a = articles[i];
      rows.add(_HeroCard(
        article: a,
        isViewed: viewedIds.contains(a.newsId),
        isFavorited: favoriteIds.contains(a.newsId),
        onToggleFavorite: () =>
            ref.read(favoritesProvider.notifier).toggle(a.newsId),
      ));
      i++;
    }

    // Unequal pair: wide left (3) + narrow right (2)
    if (i < articles.length) {
      rows.add(const SizedBox(height: AppSpacing.space2));
      if (i + 1 < articles.length) {
        rows.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: card(articles[i])),
            const SizedBox(width: AppSpacing.space2),
            Expanded(flex: 2, child: card(articles[i + 1])),
          ],
        ));
        i += 2;
      } else {
        rows.add(card(articles[i]));
        i++;
      }
    }

    // Remaining: 2-column equal grid
    while (i < articles.length) {
      rows.add(const SizedBox(height: AppSpacing.space2));
      if (i + 1 < articles.length) {
        rows.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: card(articles[i])),
            const SizedBox(width: AppSpacing.space2),
            Expanded(child: card(articles[i + 1])),
          ],
        ));
        i += 2;
      } else {
        rows.add(Row(
          children: [
            Expanded(child: card(articles[i])),
            const SizedBox(width: AppSpacing.space2),
            const Expanded(child: SizedBox()),
          ],
        ));
        i++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

// ── Cards ─────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.article,
    required this.isViewed,
    required this.isFavorited,
    required this.onToggleFavorite,
  });

  final NewsPool article;
  final bool isViewed;
  final bool isFavorited;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.accentForGenre(article.interestContext);
    final title = article.childTitleWithRuby.isNotEmpty
        ? article.childTitleWithRuby
        : article.originalTitle;

    return GestureDetector(
      onTap: () => context.go('/common/article/${article.newsId}'),
      child: ClipRRect(
        borderRadius: AppRadii.lg,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: FeedThumbnail(
            config: article.thumbnailConfig,
            fallbackIcon: Icons.article_outlined,
            overlay: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: AppGradients.feedOverlay),
                ),
                // 本文エリア（下部）
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: AppRadii.sm,
                          ),
                          child: Text(
                            article.interestContext,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.brandPrimaryInk,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        FuriganaText(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: AppColors.brandPrimaryInk,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                // バッジ（右上）
                Positioned(
                  top: AppSpacing.space2,
                  right: AppSpacing.space2,
                  child: _ArticleBadges(
                    isViewed: isViewed,
                    isFavorited: isFavorited,
                    onToggleFavorite: onToggleFavorite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.isViewed,
    required this.isFavorited,
    required this.onToggleFavorite,
  });

  final NewsPool article;
  final bool isViewed;
  final bool isFavorited;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.accentForGenre(article.interestContext);
    final title = article.childTitleWithRuby.isNotEmpty
        ? article.childTitleWithRuby
        : article.originalTitle;

    return GestureDetector(
      onTap: () => context.go('/common/article/${article.newsId}'),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.lg,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 4, color: accentColor),
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: FeedThumbnail(
                    config: article.thumbnailConfig,
                    fallbackIcon: Icons.article_outlined,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.interestContext,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 4),
                      FuriganaText(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.ink900,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // バッジ（右上、Clip.antiAlias の外側の Stack に配置）
          Positioned(
            top: AppSpacing.space2,
            right: AppSpacing.space2,
            child: _ArticleBadges(
              isViewed: isViewed,
              isFavorited: isFavorited,
              onToggleFavorite: onToggleFavorite,
            ),
          ),
        ],
      ),
    );
  }
}

// ── バッジ ─────────────────────────────────────────────────────────────────────

class _ArticleBadges extends StatelessWidget {
  const _ArticleBadges({
    required this.isViewed,
    required this.isFavorited,
    required this.onToggleFavorite,
  });

  final bool isViewed;
  final bool isFavorited;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isViewed) ...[
          const _ReadStamp(),
          const SizedBox(width: AppSpacing.space1),
        ],
        GestureDetector(
          onTap: onToggleFavorite,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppMotion.durFast,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isFavorited
                  ? AppColors.brandPrimary
                  : AppColors.surface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              size: 14,
              color: isFavorited ? AppColors.brandPrimaryInk : AppColors.ink500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadStamp extends StatelessWidget {
  const _ReadStamp();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.sm,
          border: Border.all(
            color: AppColors.brandPrimary,
            width: AppBorder.base,
          ),
        ),
        child: Text(
          'よんだ',
          style: TextStyle(
            fontSize: 9,
            color: AppColors.brandPrimary,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
