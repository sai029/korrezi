import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/models/personalized_feed_item.dart';
import '../../../shared/widgets/bouncy_tap.dart';
import '../../../shared/widgets/feed_thumbnail.dart';
import '../../../shared/widgets/furigana_text.dart';
import '../../../shared/widgets/status_views.dart';
import '../application/child_feed_provider.dart';
import '../../common_view/application/favorites_provider.dart';

/// Child Mode (タブレット・縦) TikTok風エンドレス縦スクロールフィード。
///
/// `PageView.builder(scrollDirection: Axis.vertical)` で1記事=1ページの没入型UI。
/// ページ滞在時間を計測し、Telemetry Agent (recordView) へ送る。
class ChildFeedScreen extends ConsumerStatefulWidget {
  const ChildFeedScreen({super.key});

  @override
  ConsumerState<ChildFeedScreen> createState() => _ChildFeedScreenState();
}

class _ChildFeedScreenState extends ConsumerState<ChildFeedScreen> {
  final _controller = PageController();

  /// 現在表示中ページの newsId と、表示開始時刻（滞在秒数の計測用）。
  String? _currentNewsId;
  DateTime _pageEnteredAt = DateTime.now();

  /// 破棄後でも安全に Telemetry を送るための notifier 参照。
  /// PageView のスナップ・アニメーションは画面破棄後に onPageChanged を
  /// 発火させることがあり、その時点で `ref` は使えないため事前に保持する。
  ChildFeedNotifier? _feedNotifier;

  @override
  void dispose() {
    _flushCurrentDuration();
    _controller.dispose();
    super.dispose();
  }

  void _flushCurrentDuration() {
    final id = _currentNewsId;
    if (id == null) return;
    final seconds = DateTime.now().difference(_pageEnteredAt).inSeconds;
    if (seconds > 0) {
      // dispose() 内で provider を直接変更すると Riverpod が例外を出すため、
      // microtask に逃がしてウィジェットツリー確定後に実行する。
      final notifier = _feedNotifier;
      Future.microtask(() => notifier?.recordView(id, seconds));
    }
  }

  void _onPageChanged(List<PersonalizedFeedItem> feed, int index) {
    _flushCurrentDuration();
    if (!mounted) return;
    setState(() {
      _currentNewsId = feed[index].newsId;
      _pageEnteredAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    _feedNotifier = ref.read(childFeedProvider.notifier);
    final feedAsync = ref.watch(childFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.ink900,
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            ErrorRetryView(onRetry: () => ref.invalidate(childFeedProvider)),
        data: (feed) {
          if (feed.isEmpty) {
            return EmptyStateView(
              hint: 'メニューの「ニュース取得」をおしてね',
              onRetry: () => ref.invalidate(childFeedProvider),
            );
          }
          _currentNewsId ??= feed.first.newsId;

          return Stack(
            children: [
              PageView.builder(
                controller: _controller,
                scrollDirection: Axis.vertical,
                physics: const _FastPageScrollPhysics(),
                itemCount: feed.length,
                onPageChanged: (index) => _onPageChanged(feed, index),
                itemBuilder: (context, index) =>
                    _FeedPage(item: feed[index], index: index),
              ),
              // サンプルフォールバック中は必ず可視化する（障害の隠蔽防止）
              if (isSampleFeed(feed))
                const Positioned(
                  top: AppSpacing.space3,
                  right: AppSpacing.space3,
                  child: SafeArea(child: SampleDataBanner()),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 反応の速いページスクロール物理。既存を維持。
class _FastPageScrollPhysics extends PageScrollPhysics {
  const _FastPageScrollPhysics({super.parent});

  @override
  _FastPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _FastPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.3,
        stiffness: 360,
        ratio: 1.1,
      );

  @override
  double get minFlingVelocity => 30.0;

  @override
  double get dragStartDistanceMotionThreshold => 1.5;
}

/// 1記事分の没入型ページ（大型サムネ + テキストオーバーレイ + アクションフック）。
class _FeedPage extends ConsumerWidget {
  const _FeedPage({required this.item, required this.index});

  final PersonalizedFeedItem item;
  final int index;

  void _openInCommon(BuildContext context) {
    context.go('/common/article/${item.newsId}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final favoriteIds = ref.watch(favoritesProvider).valueOrNull ?? {};
    final isFavorited = favoriteIds.contains(item.newsId);

    return FeedThumbnail(
      config: item.thumbnailConfig,
      fallbackIcon: categoryIcon(item.interestContext),
      overlay: Stack(
        fit: StackFit.expand,
        children: [
          // 下部グラデーション（transparent → #000B29 @85%）
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.feedOverlay),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // カテゴリバッジ（ジャンル別アクセントカラー）
                BouncyTap(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space1 + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentForGenre(item.interestContext),
                      borderRadius: AppRadii.pill,
                    ),
                    child: Text(
                      '#${item.interestContext}',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.brandPrimaryInk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                // タイトル（ルビ対応）
                FuriganaText(
                  item.displayTitle,
                  style: textTheme.displaySmall?.copyWith(
                    color: AppColors.brandPrimaryInk,
                    shadows: const [
                      Shadow(
                        color: AppColors.onImageShadow,
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                // タグライン
                FuriganaText(
                  item.displayTagline,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.brandPrimaryInk.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                // アクション行
                Row(
                  children: [
                    BouncyTap(
                      onTap: () => _openInCommon(context),
                      child: FilledButton.icon(
                        onPressed: () => _openInCommon(context),
                        icon: const Icon(Icons.menu_book),
                        label: const Text('よんでみる'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    BouncyTap(
                      onTap: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(item.newsId),
                      child: IconButton.filledTonal(
                        onPressed: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(item.newsId),
                        icon: AnimatedSwitcher(
                          duration: AppMotion.durFast,
                          child: Icon(
                            isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            key: ValueKey(isFavorited),
                            color: isFavorited
                                ? AppColors.brandPrimary
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
