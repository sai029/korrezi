import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/personalized_feed_item.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/feed_thumbnail.dart';
import '../application/child_feed_provider.dart';

/// Child Mode (タブレット・縦) — TikTok風エンドレス縦スクロールフィード。
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

  @override
  void dispose() {
    _flushCurrentDuration();
    _controller.dispose();
    super.dispose();
  }

  /// 直前ページの滞在秒数を Telemetry として記録する。
  void _flushCurrentDuration() {
    final id = _currentNewsId;
    if (id == null) return;
    final seconds = DateTime.now().difference(_pageEnteredAt).inSeconds;
    if (seconds > 0) {
      ref.read(childFeedProvider.notifier).recordView(id, seconds);
    }
  }

  void _onPageChanged(List<PersonalizedFeedItem> feed, int index) {
    _flushCurrentDuration();
    setState(() {
      _currentNewsId = feed[index].newsId;
      _pageEnteredAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(childFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          feedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('読み込みに失敗しました: $e',
                  style: const TextStyle(color: Colors.white)),
            ),
            data: (feed) {
              if (feed.isEmpty) {
                return const Center(
                  child: Text('まだ記事がありません',
                      style: TextStyle(color: Colors.white)),
                );
              }
              // 初回ページの計測を開始。
              _currentNewsId ??= feed.first.newsId;

              return PageView.builder(
                controller: _controller,
                scrollDirection: Axis.vertical,
                itemCount: feed.length,
                onPageChanged: (index) => _onPageChanged(feed, index),
                itemBuilder: (context, index) => _FeedPage(item: feed[index]),
              );
            },
          ),
          // 没入感を保ちつつ、左上に控えめなメニュー導線を重ねる。
          SafeArea(
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 1記事分の没入型ページ（大型サムネ + テキストオーバーレイ + アクションフック）。
class _FeedPage extends StatelessWidget {
  const _FeedPage({required this.item});

  final PersonalizedFeedItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FeedThumbnail(
      config: item.thumbnailConfig,
      // useGeneratedImages: true でImagen 3生成画像へ切替（コスト検証後）。
      overlay: Stack(
        fit: StackFit.expand,
        children: [
          // 下部を暗くしてテキストの可読性を確保するグラデーション。
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 関心コンテキストのバッジ。
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#${item.interestContext}',
                    style: textTheme.labelLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.displayTitle,
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.displayTagline,
                  style: textTheme.bodyLarge
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                // アクションフック（深掘り探索への入口）。
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        // TODO: 記事リーダー（Common View）へ遷移。
                      },
                      icon: const Icon(Icons.menu_book),
                      label: const Text('よんでみる'),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: () {
                        // TODO: 探索選択(もっと見たい)を Telemetry へ送る。
                      },
                      icon: const Icon(Icons.favorite_border),
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
