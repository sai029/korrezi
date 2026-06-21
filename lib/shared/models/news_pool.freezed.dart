// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'news_pool.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

NewsPool _$NewsPoolFromJson(Map<String, dynamic> json) {
  return _NewsPool.fromJson(json);
}

/// @nodoc
mixin _$NewsPool {
  @JsonKey(name: 'original_title')
  String get originalTitle => throw _privateConstructorUsedError;
  @TimestampConverter()
  @JsonKey(name: 'published_at')
  DateTime get publishedAt => throw _privateConstructorUsedError;

  /// 大人向けの箇条書きダイジェスト。
  @JsonKey(name: 'parent_summary')
  String get parentSummary => throw _privateConstructorUsedError;

  /// 子ども向けに書き直し、ルビ markup を埋め込んだ本文。
  @JsonKey(name: 'child_body_with_ruby')
  String get childBodyWithRuby => throw _privateConstructorUsedError;

  /// Gemini が生成した子ども向けタイトル。
  @JsonKey(name: 'display_title')
  String get displayTitle => throw _privateConstructorUsedError;

  /// Gemini が生成したキャッチコピー。
  @JsonKey(name: 'display_tagline')
  String get displayTagline => throw _privateConstructorUsedError;

  /// 出典名（例: "NHK ニュース"）。interest_profile のスコアキーとして使用。
  @JsonKey(name: 'interest_context')
  String get interestContext => throw _privateConstructorUsedError;

  /// サムネイル設定。画像があれば generated モード、なければ text_overlay。
  @JsonKey(name: 'thumbnail_config')
  ThumbnailConfig get thumbnailConfig => throw _privateConstructorUsedError;

  /// Serializes this NewsPool to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NewsPool
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NewsPoolCopyWith<NewsPool> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NewsPoolCopyWith<$Res> {
  factory $NewsPoolCopyWith(NewsPool value, $Res Function(NewsPool) then) =
      _$NewsPoolCopyWithImpl<$Res, NewsPool>;
  @useResult
  $Res call({
    @JsonKey(name: 'original_title') String originalTitle,
    @TimestampConverter() @JsonKey(name: 'published_at') DateTime publishedAt,
    @JsonKey(name: 'parent_summary') String parentSummary,
    @JsonKey(name: 'child_body_with_ruby') String childBodyWithRuby,
    @JsonKey(name: 'display_title') String displayTitle,
    @JsonKey(name: 'display_tagline') String displayTagline,
    @JsonKey(name: 'interest_context') String interestContext,
    @JsonKey(name: 'thumbnail_config') ThumbnailConfig thumbnailConfig,
  });

  $ThumbnailConfigCopyWith<$Res> get thumbnailConfig;
}

/// @nodoc
class _$NewsPoolCopyWithImpl<$Res, $Val extends NewsPool>
    implements $NewsPoolCopyWith<$Res> {
  _$NewsPoolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NewsPool
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalTitle = null,
    Object? publishedAt = null,
    Object? parentSummary = null,
    Object? childBodyWithRuby = null,
    Object? displayTitle = null,
    Object? displayTagline = null,
    Object? interestContext = null,
    Object? thumbnailConfig = null,
  }) {
    return _then(
      _value.copyWith(
            originalTitle: null == originalTitle
                ? _value.originalTitle
                : originalTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            publishedAt: null == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            parentSummary: null == parentSummary
                ? _value.parentSummary
                : parentSummary // ignore: cast_nullable_to_non_nullable
                      as String,
            childBodyWithRuby: null == childBodyWithRuby
                ? _value.childBodyWithRuby
                : childBodyWithRuby // ignore: cast_nullable_to_non_nullable
                      as String,
            displayTitle: null == displayTitle
                ? _value.displayTitle
                : displayTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            displayTagline: null == displayTagline
                ? _value.displayTagline
                : displayTagline // ignore: cast_nullable_to_non_nullable
                      as String,
            interestContext: null == interestContext
                ? _value.interestContext
                : interestContext // ignore: cast_nullable_to_non_nullable
                      as String,
            thumbnailConfig: null == thumbnailConfig
                ? _value.thumbnailConfig
                : thumbnailConfig // ignore: cast_nullable_to_non_nullable
                      as ThumbnailConfig,
          )
          as $Val,
    );
  }

  /// Create a copy of NewsPool
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ThumbnailConfigCopyWith<$Res> get thumbnailConfig {
    return $ThumbnailConfigCopyWith<$Res>(_value.thumbnailConfig, (value) {
      return _then(_value.copyWith(thumbnailConfig: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NewsPoolImplCopyWith<$Res>
    implements $NewsPoolCopyWith<$Res> {
  factory _$$NewsPoolImplCopyWith(
    _$NewsPoolImpl value,
    $Res Function(_$NewsPoolImpl) then,
  ) = __$$NewsPoolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'original_title') String originalTitle,
    @TimestampConverter() @JsonKey(name: 'published_at') DateTime publishedAt,
    @JsonKey(name: 'parent_summary') String parentSummary,
    @JsonKey(name: 'child_body_with_ruby') String childBodyWithRuby,
    @JsonKey(name: 'display_title') String displayTitle,
    @JsonKey(name: 'display_tagline') String displayTagline,
    @JsonKey(name: 'interest_context') String interestContext,
    @JsonKey(name: 'thumbnail_config') ThumbnailConfig thumbnailConfig,
  });

  @override
  $ThumbnailConfigCopyWith<$Res> get thumbnailConfig;
}

/// @nodoc
class __$$NewsPoolImplCopyWithImpl<$Res>
    extends _$NewsPoolCopyWithImpl<$Res, _$NewsPoolImpl>
    implements _$$NewsPoolImplCopyWith<$Res> {
  __$$NewsPoolImplCopyWithImpl(
    _$NewsPoolImpl _value,
    $Res Function(_$NewsPoolImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NewsPool
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalTitle = null,
    Object? publishedAt = null,
    Object? parentSummary = null,
    Object? childBodyWithRuby = null,
    Object? displayTitle = null,
    Object? displayTagline = null,
    Object? interestContext = null,
    Object? thumbnailConfig = null,
  }) {
    return _then(
      _$NewsPoolImpl(
        originalTitle: null == originalTitle
            ? _value.originalTitle
            : originalTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        publishedAt: null == publishedAt
            ? _value.publishedAt
            : publishedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        parentSummary: null == parentSummary
            ? _value.parentSummary
            : parentSummary // ignore: cast_nullable_to_non_nullable
                  as String,
        childBodyWithRuby: null == childBodyWithRuby
            ? _value.childBodyWithRuby
            : childBodyWithRuby // ignore: cast_nullable_to_non_nullable
                  as String,
        displayTitle: null == displayTitle
            ? _value.displayTitle
            : displayTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        displayTagline: null == displayTagline
            ? _value.displayTagline
            : displayTagline // ignore: cast_nullable_to_non_nullable
                  as String,
        interestContext: null == interestContext
            ? _value.interestContext
            : interestContext // ignore: cast_nullable_to_non_nullable
                  as String,
        thumbnailConfig: null == thumbnailConfig
            ? _value.thumbnailConfig
            : thumbnailConfig // ignore: cast_nullable_to_non_nullable
                  as ThumbnailConfig,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NewsPoolImpl implements _NewsPool {
  const _$NewsPoolImpl({
    @JsonKey(name: 'original_title') required this.originalTitle,
    @TimestampConverter()
    @JsonKey(name: 'published_at')
    required this.publishedAt,
    @JsonKey(name: 'parent_summary') required this.parentSummary,
    @JsonKey(name: 'child_body_with_ruby') required this.childBodyWithRuby,
    @JsonKey(name: 'display_title') this.displayTitle = '',
    @JsonKey(name: 'display_tagline') this.displayTagline = '',
    @JsonKey(name: 'interest_context') this.interestContext = 'ニュース',
    @JsonKey(name: 'thumbnail_config')
    this.thumbnailConfig = const ThumbnailConfig(),
  });

  factory _$NewsPoolImpl.fromJson(Map<String, dynamic> json) =>
      _$$NewsPoolImplFromJson(json);

  @override
  @JsonKey(name: 'original_title')
  final String originalTitle;
  @override
  @TimestampConverter()
  @JsonKey(name: 'published_at')
  final DateTime publishedAt;

  /// 大人向けの箇条書きダイジェスト。
  @override
  @JsonKey(name: 'parent_summary')
  final String parentSummary;

  /// 子ども向けに書き直し、ルビ markup を埋め込んだ本文。
  @override
  @JsonKey(name: 'child_body_with_ruby')
  final String childBodyWithRuby;

  /// Gemini が生成した子ども向けタイトル。
  @override
  @JsonKey(name: 'display_title')
  final String displayTitle;

  /// Gemini が生成したキャッチコピー。
  @override
  @JsonKey(name: 'display_tagline')
  final String displayTagline;

  /// 出典名（例: "NHK ニュース"）。interest_profile のスコアキーとして使用。
  @override
  @JsonKey(name: 'interest_context')
  final String interestContext;

  /// サムネイル設定。画像があれば generated モード、なければ text_overlay。
  @override
  @JsonKey(name: 'thumbnail_config')
  final ThumbnailConfig thumbnailConfig;

  @override
  String toString() {
    return 'NewsPool(originalTitle: $originalTitle, publishedAt: $publishedAt, parentSummary: $parentSummary, childBodyWithRuby: $childBodyWithRuby, displayTitle: $displayTitle, displayTagline: $displayTagline, interestContext: $interestContext, thumbnailConfig: $thumbnailConfig)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NewsPoolImpl &&
            (identical(other.originalTitle, originalTitle) ||
                other.originalTitle == originalTitle) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt) &&
            (identical(other.parentSummary, parentSummary) ||
                other.parentSummary == parentSummary) &&
            (identical(other.childBodyWithRuby, childBodyWithRuby) ||
                other.childBodyWithRuby == childBodyWithRuby) &&
            (identical(other.displayTitle, displayTitle) ||
                other.displayTitle == displayTitle) &&
            (identical(other.displayTagline, displayTagline) ||
                other.displayTagline == displayTagline) &&
            (identical(other.interestContext, interestContext) ||
                other.interestContext == interestContext) &&
            (identical(other.thumbnailConfig, thumbnailConfig) ||
                other.thumbnailConfig == thumbnailConfig));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    originalTitle,
    publishedAt,
    parentSummary,
    childBodyWithRuby,
    displayTitle,
    displayTagline,
    interestContext,
    thumbnailConfig,
  );

  /// Create a copy of NewsPool
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NewsPoolImplCopyWith<_$NewsPoolImpl> get copyWith =>
      __$$NewsPoolImplCopyWithImpl<_$NewsPoolImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NewsPoolImplToJson(this);
  }
}

abstract class _NewsPool implements NewsPool {
  const factory _NewsPool({
    @JsonKey(name: 'original_title') required final String originalTitle,
    @TimestampConverter()
    @JsonKey(name: 'published_at')
    required final DateTime publishedAt,
    @JsonKey(name: 'parent_summary') required final String parentSummary,
    @JsonKey(name: 'child_body_with_ruby')
    required final String childBodyWithRuby,
    @JsonKey(name: 'display_title') final String displayTitle,
    @JsonKey(name: 'display_tagline') final String displayTagline,
    @JsonKey(name: 'interest_context') final String interestContext,
    @JsonKey(name: 'thumbnail_config') final ThumbnailConfig thumbnailConfig,
  }) = _$NewsPoolImpl;

  factory _NewsPool.fromJson(Map<String, dynamic> json) =
      _$NewsPoolImpl.fromJson;

  @override
  @JsonKey(name: 'original_title')
  String get originalTitle;
  @override
  @TimestampConverter()
  @JsonKey(name: 'published_at')
  DateTime get publishedAt;

  /// 大人向けの箇条書きダイジェスト。
  @override
  @JsonKey(name: 'parent_summary')
  String get parentSummary;

  /// 子ども向けに書き直し、ルビ markup を埋め込んだ本文。
  @override
  @JsonKey(name: 'child_body_with_ruby')
  String get childBodyWithRuby;

  /// Gemini が生成した子ども向けタイトル。
  @override
  @JsonKey(name: 'display_title')
  String get displayTitle;

  /// Gemini が生成したキャッチコピー。
  @override
  @JsonKey(name: 'display_tagline')
  String get displayTagline;

  /// 出典名（例: "NHK ニュース"）。interest_profile のスコアキーとして使用。
  @override
  @JsonKey(name: 'interest_context')
  String get interestContext;

  /// サムネイル設定。画像があれば generated モード、なければ text_overlay。
  @override
  @JsonKey(name: 'thumbnail_config')
  ThumbnailConfig get thumbnailConfig;

  /// Create a copy of NewsPool
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NewsPoolImplCopyWith<_$NewsPoolImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
