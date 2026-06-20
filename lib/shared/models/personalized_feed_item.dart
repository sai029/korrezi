import 'package:freezed_annotation/freezed_annotation.dart';

part 'personalized_feed_item.freezed.dart';
part 'personalized_feed_item.g.dart';

/// サムネイルの表示モード。
///
/// 画像レイヤーの疎結合化要件: 既定はキャッシュ済みカテゴリイラストへの
/// テキストオーバーレイ。コスト検証後に Imagen 3 生成画像へ切替可能にする。
enum ThumbnailMode {
  @JsonValue('text_overlay')
  textOverlay,
  @JsonValue('generated')
  generated,
}

/// サムネイル構成（画像抽象化レイヤー）。
@freezed
class ThumbnailConfig with _$ThumbnailConfig {
  const factory ThumbnailConfig({
    @JsonKey(name: 'mode') @Default(ThumbnailMode.textOverlay) ThumbnailMode mode,

    /// text_overlay モードで使うカテゴリ別イラスト。
    /// 例: `assets/images/categories/soccer.png`
    @JsonKey(name: 'base_asset') @Default('') String baseAsset,

    /// generated モードで使う Imagen 3 生成画像の URL（未使用時は空）。
    @JsonKey(name: 'optional_generated_url') @Default('') String optionalGeneratedUrl,
  }) = _ThumbnailConfig;

  factory ThumbnailConfig.fromJson(Map<String, dynamic> json) =>
      _$ThumbnailConfigFromJson(json);
}

/// Firestore `/users/{userId}/personalized_feed/{newsId}` に対応するモデル。
///
/// セッション初期化時に interest_profile の上位ウェイトを元に Gemini が
/// タイトル/タグラインを子どもの関心に合わせて翻訳・ブレンドした結果。
@freezed
class PersonalizedFeedItem with _$PersonalizedFeedItem {
  const factory PersonalizedFeedItem({
    @JsonKey(name: 'news_id') required String newsId,

    /// ブレンドに使った関心コンテキスト（例: "Soccer"）。
    @JsonKey(name: 'interest_context') required String interestContext,
    @JsonKey(name: 'display_title') required String displayTitle,
    @JsonKey(name: 'display_tagline') required String displayTagline,
    @JsonKey(name: 'thumbnail_config') required ThumbnailConfig thumbnailConfig,
    @JsonKey(name: 'is_viewed') @Default(false) bool isViewed,

    /// Telemetry Agent が記録する閲覧秒数。
    @JsonKey(name: 'view_duration_seconds') @Default(0) int viewDurationSeconds,
  }) = _PersonalizedFeedItem;

  factory PersonalizedFeedItem.fromJson(Map<String, dynamic> json) =>
      _$PersonalizedFeedItemFromJson(json);
}
