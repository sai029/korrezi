import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';
import 'personalized_feed_item.dart';

part 'news_pool.freezed.dart';
part 'news_pool.g.dart';

/// Firestore `/news_pool/{newsId}` に対応するモデル。
///
/// 全ユーザー共通の記事プール。Gemini が生成した子ども向け表示データも含む。
/// フィードは news_pool を直接読むため、新規ユーザーでも即座に記事が表示される。
@freezed
class NewsPool with _$NewsPool {
  const factory NewsPool({
    @JsonKey(name: 'original_title') required String originalTitle,
    @TimestampConverter()
    @JsonKey(name: 'published_at')
    required DateTime publishedAt,

    /// 大人向けの箇条書きダイジェスト。
    @JsonKey(name: 'parent_summary') required String parentSummary,

    /// 子ども向けに書き直し、ルビ markup を埋め込んだ本文。
    @JsonKey(name: 'child_body_with_ruby') required String childBodyWithRuby,

    /// Gemini が生成した子ども向けタイトル。
    @JsonKey(name: 'display_title') @Default('') String displayTitle,

    /// Gemini が生成したキャッチコピー。
    @JsonKey(name: 'display_tagline') @Default('') String displayTagline,

    /// 出典名（例: "NHK ニュース"）。interest_profile のスコアキーとして使用。
    @JsonKey(name: 'interest_context') @Default('ニュース') String interestContext,

    /// ルビ markup を埋め込んだ子ども向けタイトル（未設定時は originalTitle で表示）。
    @JsonKey(name: 'child_title_with_ruby') @Default('') String childTitleWithRuby,

    /// サムネイル設定。画像があれば generated モード、なければ text_overlay。
    @JsonKey(name: 'thumbnail_config')
    @Default(ThumbnailConfig())
    ThumbnailConfig thumbnailConfig,
  }) = _NewsPool;

  factory NewsPool.fromJson(Map<String, dynamic> json) =>
      _$NewsPoolFromJson(json);
}
