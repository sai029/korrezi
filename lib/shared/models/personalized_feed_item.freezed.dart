// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personalized_feed_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ThumbnailConfig _$ThumbnailConfigFromJson(Map<String, dynamic> json) {
  return _ThumbnailConfig.fromJson(json);
}

/// @nodoc
mixin _$ThumbnailConfig {
  @JsonKey(name: 'mode')
  ThumbnailMode get mode => throw _privateConstructorUsedError;

  /// text_overlay モードで使うカテゴリ別イラスト。
  /// 例: `assets/images/categories/soccer.png`
  @JsonKey(name: 'base_asset')
  String get baseAsset => throw _privateConstructorUsedError;

  /// generated モードで使う Imagen 3 生成画像の URL（未使用時は空）。
  @JsonKey(name: 'optional_generated_url')
  String get optionalGeneratedUrl => throw _privateConstructorUsedError;

  /// Serializes this ThumbnailConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ThumbnailConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ThumbnailConfigCopyWith<ThumbnailConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThumbnailConfigCopyWith<$Res> {
  factory $ThumbnailConfigCopyWith(
    ThumbnailConfig value,
    $Res Function(ThumbnailConfig) then,
  ) = _$ThumbnailConfigCopyWithImpl<$Res, ThumbnailConfig>;
  @useResult
  $Res call({
    @JsonKey(name: 'mode') ThumbnailMode mode,
    @JsonKey(name: 'base_asset') String baseAsset,
    @JsonKey(name: 'optional_generated_url') String optionalGeneratedUrl,
  });
}

/// @nodoc
class _$ThumbnailConfigCopyWithImpl<$Res, $Val extends ThumbnailConfig>
    implements $ThumbnailConfigCopyWith<$Res> {
  _$ThumbnailConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ThumbnailConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? baseAsset = null,
    Object? optionalGeneratedUrl = null,
  }) {
    return _then(
      _value.copyWith(
            mode: null == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as ThumbnailMode,
            baseAsset: null == baseAsset
                ? _value.baseAsset
                : baseAsset // ignore: cast_nullable_to_non_nullable
                      as String,
            optionalGeneratedUrl: null == optionalGeneratedUrl
                ? _value.optionalGeneratedUrl
                : optionalGeneratedUrl // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ThumbnailConfigImplCopyWith<$Res>
    implements $ThumbnailConfigCopyWith<$Res> {
  factory _$$ThumbnailConfigImplCopyWith(
    _$ThumbnailConfigImpl value,
    $Res Function(_$ThumbnailConfigImpl) then,
  ) = __$$ThumbnailConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'mode') ThumbnailMode mode,
    @JsonKey(name: 'base_asset') String baseAsset,
    @JsonKey(name: 'optional_generated_url') String optionalGeneratedUrl,
  });
}

/// @nodoc
class __$$ThumbnailConfigImplCopyWithImpl<$Res>
    extends _$ThumbnailConfigCopyWithImpl<$Res, _$ThumbnailConfigImpl>
    implements _$$ThumbnailConfigImplCopyWith<$Res> {
  __$$ThumbnailConfigImplCopyWithImpl(
    _$ThumbnailConfigImpl _value,
    $Res Function(_$ThumbnailConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ThumbnailConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? baseAsset = null,
    Object? optionalGeneratedUrl = null,
  }) {
    return _then(
      _$ThumbnailConfigImpl(
        mode: null == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as ThumbnailMode,
        baseAsset: null == baseAsset
            ? _value.baseAsset
            : baseAsset // ignore: cast_nullable_to_non_nullable
                  as String,
        optionalGeneratedUrl: null == optionalGeneratedUrl
            ? _value.optionalGeneratedUrl
            : optionalGeneratedUrl // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ThumbnailConfigImpl implements _ThumbnailConfig {
  const _$ThumbnailConfigImpl({
    @JsonKey(name: 'mode') this.mode = ThumbnailMode.textOverlay,
    @JsonKey(name: 'base_asset') this.baseAsset = '',
    @JsonKey(name: 'optional_generated_url') this.optionalGeneratedUrl = '',
  });

  factory _$ThumbnailConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThumbnailConfigImplFromJson(json);

  @override
  @JsonKey(name: 'mode')
  final ThumbnailMode mode;

  /// text_overlay モードで使うカテゴリ別イラスト。
  /// 例: `assets/images/categories/soccer.png`
  @override
  @JsonKey(name: 'base_asset')
  final String baseAsset;

  /// generated モードで使う Imagen 3 生成画像の URL（未使用時は空）。
  @override
  @JsonKey(name: 'optional_generated_url')
  final String optionalGeneratedUrl;

  @override
  String toString() {
    return 'ThumbnailConfig(mode: $mode, baseAsset: $baseAsset, optionalGeneratedUrl: $optionalGeneratedUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThumbnailConfigImpl &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.baseAsset, baseAsset) ||
                other.baseAsset == baseAsset) &&
            (identical(other.optionalGeneratedUrl, optionalGeneratedUrl) ||
                other.optionalGeneratedUrl == optionalGeneratedUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, mode, baseAsset, optionalGeneratedUrl);

  /// Create a copy of ThumbnailConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThumbnailConfigImplCopyWith<_$ThumbnailConfigImpl> get copyWith =>
      __$$ThumbnailConfigImplCopyWithImpl<_$ThumbnailConfigImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ThumbnailConfigImplToJson(this);
  }
}

abstract class _ThumbnailConfig implements ThumbnailConfig {
  const factory _ThumbnailConfig({
    @JsonKey(name: 'mode') final ThumbnailMode mode,
    @JsonKey(name: 'base_asset') final String baseAsset,
    @JsonKey(name: 'optional_generated_url') final String optionalGeneratedUrl,
  }) = _$ThumbnailConfigImpl;

  factory _ThumbnailConfig.fromJson(Map<String, dynamic> json) =
      _$ThumbnailConfigImpl.fromJson;

  @override
  @JsonKey(name: 'mode')
  ThumbnailMode get mode;

  /// text_overlay モードで使うカテゴリ別イラスト。
  /// 例: `assets/images/categories/soccer.png`
  @override
  @JsonKey(name: 'base_asset')
  String get baseAsset;

  /// generated モードで使う Imagen 3 生成画像の URL（未使用時は空）。
  @override
  @JsonKey(name: 'optional_generated_url')
  String get optionalGeneratedUrl;

  /// Create a copy of ThumbnailConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThumbnailConfigImplCopyWith<_$ThumbnailConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PersonalizedFeedItem _$PersonalizedFeedItemFromJson(Map<String, dynamic> json) {
  return _PersonalizedFeedItem.fromJson(json);
}

/// @nodoc
mixin _$PersonalizedFeedItem {
  @JsonKey(name: 'news_id')
  String get newsId => throw _privateConstructorUsedError;

  /// ブレンドに使った関心コンテキスト（例: "Soccer"）。
  @JsonKey(name: 'interest_context')
  String get interestContext => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_title')
  String get displayTitle => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_tagline')
  String get displayTagline => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail_config')
  ThumbnailConfig get thumbnailConfig => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_viewed')
  bool get isViewed => throw _privateConstructorUsedError;

  /// Telemetry Agent が記録する閲覧秒数。
  @JsonKey(name: 'view_duration_seconds')
  int get viewDurationSeconds => throw _privateConstructorUsedError;

  /// Serializes this PersonalizedFeedItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PersonalizedFeedItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PersonalizedFeedItemCopyWith<PersonalizedFeedItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonalizedFeedItemCopyWith<$Res> {
  factory $PersonalizedFeedItemCopyWith(
    PersonalizedFeedItem value,
    $Res Function(PersonalizedFeedItem) then,
  ) = _$PersonalizedFeedItemCopyWithImpl<$Res, PersonalizedFeedItem>;
  @useResult
  $Res call({
    @JsonKey(name: 'news_id') String newsId,
    @JsonKey(name: 'interest_context') String interestContext,
    @JsonKey(name: 'display_title') String displayTitle,
    @JsonKey(name: 'display_tagline') String displayTagline,
    @JsonKey(name: 'thumbnail_config') ThumbnailConfig thumbnailConfig,
    @JsonKey(name: 'is_viewed') bool isViewed,
    @JsonKey(name: 'view_duration_seconds') int viewDurationSeconds,
  });

  $ThumbnailConfigCopyWith<$Res> get thumbnailConfig;
}

/// @nodoc
class _$PersonalizedFeedItemCopyWithImpl<
  $Res,
  $Val extends PersonalizedFeedItem
>
    implements $PersonalizedFeedItemCopyWith<$Res> {
  _$PersonalizedFeedItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PersonalizedFeedItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? newsId = null,
    Object? interestContext = null,
    Object? displayTitle = null,
    Object? displayTagline = null,
    Object? thumbnailConfig = null,
    Object? isViewed = null,
    Object? viewDurationSeconds = null,
  }) {
    return _then(
      _value.copyWith(
            newsId: null == newsId
                ? _value.newsId
                : newsId // ignore: cast_nullable_to_non_nullable
                      as String,
            interestContext: null == interestContext
                ? _value.interestContext
                : interestContext // ignore: cast_nullable_to_non_nullable
                      as String,
            displayTitle: null == displayTitle
                ? _value.displayTitle
                : displayTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            displayTagline: null == displayTagline
                ? _value.displayTagline
                : displayTagline // ignore: cast_nullable_to_non_nullable
                      as String,
            thumbnailConfig: null == thumbnailConfig
                ? _value.thumbnailConfig
                : thumbnailConfig // ignore: cast_nullable_to_non_nullable
                      as ThumbnailConfig,
            isViewed: null == isViewed
                ? _value.isViewed
                : isViewed // ignore: cast_nullable_to_non_nullable
                      as bool,
            viewDurationSeconds: null == viewDurationSeconds
                ? _value.viewDurationSeconds
                : viewDurationSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }

  /// Create a copy of PersonalizedFeedItem
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
abstract class _$$PersonalizedFeedItemImplCopyWith<$Res>
    implements $PersonalizedFeedItemCopyWith<$Res> {
  factory _$$PersonalizedFeedItemImplCopyWith(
    _$PersonalizedFeedItemImpl value,
    $Res Function(_$PersonalizedFeedItemImpl) then,
  ) = __$$PersonalizedFeedItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'news_id') String newsId,
    @JsonKey(name: 'interest_context') String interestContext,
    @JsonKey(name: 'display_title') String displayTitle,
    @JsonKey(name: 'display_tagline') String displayTagline,
    @JsonKey(name: 'thumbnail_config') ThumbnailConfig thumbnailConfig,
    @JsonKey(name: 'is_viewed') bool isViewed,
    @JsonKey(name: 'view_duration_seconds') int viewDurationSeconds,
  });

  @override
  $ThumbnailConfigCopyWith<$Res> get thumbnailConfig;
}

/// @nodoc
class __$$PersonalizedFeedItemImplCopyWithImpl<$Res>
    extends _$PersonalizedFeedItemCopyWithImpl<$Res, _$PersonalizedFeedItemImpl>
    implements _$$PersonalizedFeedItemImplCopyWith<$Res> {
  __$$PersonalizedFeedItemImplCopyWithImpl(
    _$PersonalizedFeedItemImpl _value,
    $Res Function(_$PersonalizedFeedItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PersonalizedFeedItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? newsId = null,
    Object? interestContext = null,
    Object? displayTitle = null,
    Object? displayTagline = null,
    Object? thumbnailConfig = null,
    Object? isViewed = null,
    Object? viewDurationSeconds = null,
  }) {
    return _then(
      _$PersonalizedFeedItemImpl(
        newsId: null == newsId
            ? _value.newsId
            : newsId // ignore: cast_nullable_to_non_nullable
                  as String,
        interestContext: null == interestContext
            ? _value.interestContext
            : interestContext // ignore: cast_nullable_to_non_nullable
                  as String,
        displayTitle: null == displayTitle
            ? _value.displayTitle
            : displayTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        displayTagline: null == displayTagline
            ? _value.displayTagline
            : displayTagline // ignore: cast_nullable_to_non_nullable
                  as String,
        thumbnailConfig: null == thumbnailConfig
            ? _value.thumbnailConfig
            : thumbnailConfig // ignore: cast_nullable_to_non_nullable
                  as ThumbnailConfig,
        isViewed: null == isViewed
            ? _value.isViewed
            : isViewed // ignore: cast_nullable_to_non_nullable
                  as bool,
        viewDurationSeconds: null == viewDurationSeconds
            ? _value.viewDurationSeconds
            : viewDurationSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PersonalizedFeedItemImpl implements _PersonalizedFeedItem {
  const _$PersonalizedFeedItemImpl({
    @JsonKey(name: 'news_id') required this.newsId,
    @JsonKey(name: 'interest_context') required this.interestContext,
    @JsonKey(name: 'display_title') required this.displayTitle,
    @JsonKey(name: 'display_tagline') required this.displayTagline,
    @JsonKey(name: 'thumbnail_config') required this.thumbnailConfig,
    @JsonKey(name: 'is_viewed') this.isViewed = false,
    @JsonKey(name: 'view_duration_seconds') this.viewDurationSeconds = 0,
  });

  factory _$PersonalizedFeedItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonalizedFeedItemImplFromJson(json);

  @override
  @JsonKey(name: 'news_id')
  final String newsId;

  /// ブレンドに使った関心コンテキスト（例: "Soccer"）。
  @override
  @JsonKey(name: 'interest_context')
  final String interestContext;
  @override
  @JsonKey(name: 'display_title')
  final String displayTitle;
  @override
  @JsonKey(name: 'display_tagline')
  final String displayTagline;
  @override
  @JsonKey(name: 'thumbnail_config')
  final ThumbnailConfig thumbnailConfig;
  @override
  @JsonKey(name: 'is_viewed')
  final bool isViewed;

  /// Telemetry Agent が記録する閲覧秒数。
  @override
  @JsonKey(name: 'view_duration_seconds')
  final int viewDurationSeconds;

  @override
  String toString() {
    return 'PersonalizedFeedItem(newsId: $newsId, interestContext: $interestContext, displayTitle: $displayTitle, displayTagline: $displayTagline, thumbnailConfig: $thumbnailConfig, isViewed: $isViewed, viewDurationSeconds: $viewDurationSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonalizedFeedItemImpl &&
            (identical(other.newsId, newsId) || other.newsId == newsId) &&
            (identical(other.interestContext, interestContext) ||
                other.interestContext == interestContext) &&
            (identical(other.displayTitle, displayTitle) ||
                other.displayTitle == displayTitle) &&
            (identical(other.displayTagline, displayTagline) ||
                other.displayTagline == displayTagline) &&
            (identical(other.thumbnailConfig, thumbnailConfig) ||
                other.thumbnailConfig == thumbnailConfig) &&
            (identical(other.isViewed, isViewed) ||
                other.isViewed == isViewed) &&
            (identical(other.viewDurationSeconds, viewDurationSeconds) ||
                other.viewDurationSeconds == viewDurationSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    newsId,
    interestContext,
    displayTitle,
    displayTagline,
    thumbnailConfig,
    isViewed,
    viewDurationSeconds,
  );

  /// Create a copy of PersonalizedFeedItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonalizedFeedItemImplCopyWith<_$PersonalizedFeedItemImpl>
  get copyWith =>
      __$$PersonalizedFeedItemImplCopyWithImpl<_$PersonalizedFeedItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonalizedFeedItemImplToJson(this);
  }
}

abstract class _PersonalizedFeedItem implements PersonalizedFeedItem {
  const factory _PersonalizedFeedItem({
    @JsonKey(name: 'news_id') required final String newsId,
    @JsonKey(name: 'interest_context') required final String interestContext,
    @JsonKey(name: 'display_title') required final String displayTitle,
    @JsonKey(name: 'display_tagline') required final String displayTagline,
    @JsonKey(name: 'thumbnail_config')
    required final ThumbnailConfig thumbnailConfig,
    @JsonKey(name: 'is_viewed') final bool isViewed,
    @JsonKey(name: 'view_duration_seconds') final int viewDurationSeconds,
  }) = _$PersonalizedFeedItemImpl;

  factory _PersonalizedFeedItem.fromJson(Map<String, dynamic> json) =
      _$PersonalizedFeedItemImpl.fromJson;

  @override
  @JsonKey(name: 'news_id')
  String get newsId;

  /// ブレンドに使った関心コンテキスト（例: "Soccer"）。
  @override
  @JsonKey(name: 'interest_context')
  String get interestContext;
  @override
  @JsonKey(name: 'display_title')
  String get displayTitle;
  @override
  @JsonKey(name: 'display_tagline')
  String get displayTagline;
  @override
  @JsonKey(name: 'thumbnail_config')
  ThumbnailConfig get thumbnailConfig;
  @override
  @JsonKey(name: 'is_viewed')
  bool get isViewed;

  /// Telemetry Agent が記録する閲覧秒数。
  @override
  @JsonKey(name: 'view_duration_seconds')
  int get viewDurationSeconds;

  /// Create a copy of PersonalizedFeedItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PersonalizedFeedItemImplCopyWith<_$PersonalizedFeedItemImpl>
  get copyWith => throw _privateConstructorUsedError;
}
