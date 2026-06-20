import 'package:flutter/material.dart';

import '../models/personalized_feed_item.dart';

/// 画像抽象化レイヤー。
///
/// プレゼンテーション層は具体的な画像取得方法を知らず、抽象的な [ImageProvider]
/// だけを扱う。既定（text_overlay）はキャッシュ済みカテゴリイラストを背景にし、
/// その上にAIテキストを重ねる。[useGeneratedImages] を true にすると、コスト検証後に
/// Imagen 3 生成画像(URL)へシームレスに切り替えられる。
class FeedThumbnail extends StatelessWidget {
  const FeedThumbnail({
    super.key,
    required this.config,
    this.useGeneratedImages = false,
    this.overlay,
  });

  final ThumbnailConfig config;

  /// true で Imagen 3 生成画像(URL)を優先する切替フラグ（既定は false=イラスト）。
  final bool useGeneratedImages;

  /// 画像の上に重ねるAIテキスト等のウィジェット。
  final Widget? overlay;

  /// 設定とトグルから、使用する [ImageProvider] を解決する。
  /// 生成画像が有効かつURLがあれば NetworkImage、それ以外はカテゴリ AssetImage。
  ImageProvider? _resolveProvider() {
    final wantsGenerated = useGeneratedImages ||
        config.mode == ThumbnailMode.generated;
    if (wantsGenerated && config.optionalGeneratedUrl.isNotEmpty) {
      return NetworkImage(config.optionalGeneratedUrl);
    }
    if (config.baseAsset.isNotEmpty) {
      return AssetImage(config.baseAsset);
    }
    return null;
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
                // アセット未配置/URL失敗時はグラデーション背景にフォールバック。
                onError: (error, stackTrace) {},
              ),
        gradient: provider == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primaryContainer, scheme.tertiaryContainer],
              )
            : null,
      ),
      child: overlay,
    );
  }
}
