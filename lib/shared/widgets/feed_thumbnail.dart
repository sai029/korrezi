import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../models/personalized_feed_item.dart';

/// 画像抽象化レイヤー。
///
/// NetworkImage の読み込みに失敗した場合（CORS エラー含む）は
/// accent グラデーション ＋ カテゴリアイコンへ自動フォールバックする。
class FeedThumbnail extends StatefulWidget {
  const FeedThumbnail({
    super.key,
    required this.config,
    this.useGeneratedImages = false,
    this.overlay,
    this.fallbackIcon,
  });

  final ThumbnailConfig config;
  final bool useGeneratedImages;
  final Widget? overlay;

  /// フォールバック時に accent グラデの中央に表示するアイコン。
  /// 未指定の場合は `Icons.article_outlined` を使う。
  final IconData? fallbackIcon;

  @override
  State<FeedThumbnail> createState() => _FeedThumbnailState();
}

class _FeedThumbnailState extends State<FeedThumbnail> {
  bool _imageError = false;

  ImageProvider? _resolveProvider() {
    if (_imageError) return null;
    final wantsGenerated = widget.useGeneratedImages ||
        widget.config.mode == ThumbnailMode.generated;
    if (wantsGenerated && widget.config.optionalGeneratedUrl.isNotEmpty) {
      return NetworkImage(widget.config.optionalGeneratedUrl);
    }
    if (widget.config.baseAsset.isNotEmpty) {
      return AssetImage(widget.config.baseAsset);
    }
    return null;
  }

  @override
  void didUpdateWidget(FeedThumbnail old) {
    super.didUpdateWidget(old);
    if (old.config.optionalGeneratedUrl !=
        widget.config.optionalGeneratedUrl) {
      setState(() => _imageError = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _resolveProvider();
    final scheme = Theme.of(context).colorScheme;

    if (provider != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          image: DecorationImage(
            image: provider,
            fit: BoxFit.cover,
            onError: (e, _) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _imageError = true);
                });
              }
            },
          ),
        ),
        child: widget.overlay,
      );
    }

    // フォールバック: ベースカラー + カテゴリアイコン
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(
              widget.fallbackIcon ?? Icons.article_outlined,
              size: 80,
              color: AppColors.brandPrimaryInk.withValues(alpha: 0.5),
            ),
          ),
          if (widget.overlay != null) widget.overlay!,
        ],
      ),
    );
  }
}

/// interestContext（カテゴリ文字列）から代表アイコンを返すユーティリティ。
IconData categoryIcon(String interest) {
  final key = interest.toLowerCase();
  if (key.contains('soccer') || key.contains('football') || key.contains('サッカー')) {
    return Icons.sports_soccer;
  }
  if (key.contains('science') || key.contains('科学')) return Icons.science;
  if (key.contains('music') || key.contains('音楽')) return Icons.music_note;
  if (key.contains('nature') || key.contains('自然')) return Icons.park;
  if (key.contains('space') || key.contains('宇宙')) return Icons.rocket_launch;
  if (key.contains('animal') || key.contains('動物')) return Icons.pets;
  if (key.contains('food') || key.contains('食べ物')) return Icons.restaurant;
  if (key.contains('sport') || key.contains('スポーツ')) return Icons.sports;
  if (key.contains('tech') || key.contains('テクノロジー')) return Icons.computer;
  return Icons.article_outlined;
}
