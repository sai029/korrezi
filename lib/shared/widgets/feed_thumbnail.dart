import 'package:flutter/material.dart';

import '../models/personalized_feed_item.dart';

/// 画像抽象化レイヤー。
///
/// NetworkImage の読み込みに失敗した場合（CORS エラー含む）は
/// グラデーション背景へ自動フォールバックする。
class FeedThumbnail extends StatefulWidget {
  const FeedThumbnail({
    super.key,
    required this.config,
    this.useGeneratedImages = false,
    this.overlay,
  });

  final ThumbnailConfig config;
  final bool useGeneratedImages;
  final Widget? overlay;

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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        image: provider == null
            ? null
            : DecorationImage(
                image: provider,
                fit: BoxFit.cover,
                onError: (e, _) {
                  if (mounted) setState(() => _imageError = true);
                },
              ),
        gradient: provider == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primaryContainer, scheme.tertiaryContainer],
              )
            : null,
      ),
      child: widget.overlay,
    );
  }
}
