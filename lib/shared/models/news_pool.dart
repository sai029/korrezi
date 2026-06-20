import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'news_pool.freezed.dart';
part 'news_pool.g.dart';

/// Firestore `/news_pool/{newsId}` に対応するモデル。
///
/// 1日1回の Curated Global Batch で Gemini が生成する、全ユーザー共通の元記事。
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
    /// 例: `〔世界｜せかい〕の〔環境｜かんきょう〕を守るルールが...`
    @JsonKey(name: 'child_body_with_ruby') required String childBodyWithRuby,
  }) = _NewsPool;

  factory NewsPool.fromJson(Map<String, dynamic> json) =>
      _$NewsPoolFromJson(json);
}
