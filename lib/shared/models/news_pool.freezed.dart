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
  /// 例: `〔世界｜せかい〕の〔環境｜かんきょう〕を守るルールが...`
  @JsonKey(name: 'child_body_with_ruby')
  String get childBodyWithRuby => throw _privateConstructorUsedError;

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
  });
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
          )
          as $Val,
    );
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
  });
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
  /// 例: `〔世界｜せかい〕の〔環境｜かんきょう〕を守るルールが...`
  @override
  @JsonKey(name: 'child_body_with_ruby')
  final String childBodyWithRuby;

  @override
  String toString() {
    return 'NewsPool(originalTitle: $originalTitle, publishedAt: $publishedAt, parentSummary: $parentSummary, childBodyWithRuby: $childBodyWithRuby)';
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
                other.childBodyWithRuby == childBodyWithRuby));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    originalTitle,
    publishedAt,
    parentSummary,
    childBodyWithRuby,
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
  /// 例: `〔世界｜せかい〕の〔環境｜かんきょう〕を守るルールが...`
  @override
  @JsonKey(name: 'child_body_with_ruby')
  String get childBodyWithRuby;

  /// Create a copy of NewsPool
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NewsPoolImplCopyWith<_$NewsPoolImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
