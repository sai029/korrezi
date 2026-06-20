// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'interest_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AiAgentMetadata _$AiAgentMetadataFromJson(Map<String, dynamic> json) {
  return _AiAgentMetadata.fromJson(json);
}

/// @nodoc
mixin _$AiAgentMetadata {
  @TimestampConverter()
  @JsonKey(name: 'last_evaluation_cycle')
  DateTime get lastEvaluationCycle => throw _privateConstructorUsedError;

  /// 現在使用中のメタプロンプト版（例: "v2.4_empathetic_sports_blend"）。
  @JsonKey(name: 'current_prompt_version')
  String get currentPromptVersion => throw _privateConstructorUsedError;

  /// エージェントの自己評価メモ（自律的に書き換える内省ノート）。
  @JsonKey(name: 'agent_notes')
  String get agentNotes => throw _privateConstructorUsedError;

  /// Serializes this AiAgentMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AiAgentMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiAgentMetadataCopyWith<AiAgentMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiAgentMetadataCopyWith<$Res> {
  factory $AiAgentMetadataCopyWith(
    AiAgentMetadata value,
    $Res Function(AiAgentMetadata) then,
  ) = _$AiAgentMetadataCopyWithImpl<$Res, AiAgentMetadata>;
  @useResult
  $Res call({
    @TimestampConverter()
    @JsonKey(name: 'last_evaluation_cycle')
    DateTime lastEvaluationCycle,
    @JsonKey(name: 'current_prompt_version') String currentPromptVersion,
    @JsonKey(name: 'agent_notes') String agentNotes,
  });
}

/// @nodoc
class _$AiAgentMetadataCopyWithImpl<$Res, $Val extends AiAgentMetadata>
    implements $AiAgentMetadataCopyWith<$Res> {
  _$AiAgentMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiAgentMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lastEvaluationCycle = null,
    Object? currentPromptVersion = null,
    Object? agentNotes = null,
  }) {
    return _then(
      _value.copyWith(
            lastEvaluationCycle: null == lastEvaluationCycle
                ? _value.lastEvaluationCycle
                : lastEvaluationCycle // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            currentPromptVersion: null == currentPromptVersion
                ? _value.currentPromptVersion
                : currentPromptVersion // ignore: cast_nullable_to_non_nullable
                      as String,
            agentNotes: null == agentNotes
                ? _value.agentNotes
                : agentNotes // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AiAgentMetadataImplCopyWith<$Res>
    implements $AiAgentMetadataCopyWith<$Res> {
  factory _$$AiAgentMetadataImplCopyWith(
    _$AiAgentMetadataImpl value,
    $Res Function(_$AiAgentMetadataImpl) then,
  ) = __$$AiAgentMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @TimestampConverter()
    @JsonKey(name: 'last_evaluation_cycle')
    DateTime lastEvaluationCycle,
    @JsonKey(name: 'current_prompt_version') String currentPromptVersion,
    @JsonKey(name: 'agent_notes') String agentNotes,
  });
}

/// @nodoc
class __$$AiAgentMetadataImplCopyWithImpl<$Res>
    extends _$AiAgentMetadataCopyWithImpl<$Res, _$AiAgentMetadataImpl>
    implements _$$AiAgentMetadataImplCopyWith<$Res> {
  __$$AiAgentMetadataImplCopyWithImpl(
    _$AiAgentMetadataImpl _value,
    $Res Function(_$AiAgentMetadataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiAgentMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lastEvaluationCycle = null,
    Object? currentPromptVersion = null,
    Object? agentNotes = null,
  }) {
    return _then(
      _$AiAgentMetadataImpl(
        lastEvaluationCycle: null == lastEvaluationCycle
            ? _value.lastEvaluationCycle
            : lastEvaluationCycle // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        currentPromptVersion: null == currentPromptVersion
            ? _value.currentPromptVersion
            : currentPromptVersion // ignore: cast_nullable_to_non_nullable
                  as String,
        agentNotes: null == agentNotes
            ? _value.agentNotes
            : agentNotes // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AiAgentMetadataImpl implements _AiAgentMetadata {
  const _$AiAgentMetadataImpl({
    @TimestampConverter()
    @JsonKey(name: 'last_evaluation_cycle')
    required this.lastEvaluationCycle,
    @JsonKey(name: 'current_prompt_version') required this.currentPromptVersion,
    @JsonKey(name: 'agent_notes') this.agentNotes = '',
  });

  factory _$AiAgentMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$AiAgentMetadataImplFromJson(json);

  @override
  @TimestampConverter()
  @JsonKey(name: 'last_evaluation_cycle')
  final DateTime lastEvaluationCycle;

  /// 現在使用中のメタプロンプト版（例: "v2.4_empathetic_sports_blend"）。
  @override
  @JsonKey(name: 'current_prompt_version')
  final String currentPromptVersion;

  /// エージェントの自己評価メモ（自律的に書き換える内省ノート）。
  @override
  @JsonKey(name: 'agent_notes')
  final String agentNotes;

  @override
  String toString() {
    return 'AiAgentMetadata(lastEvaluationCycle: $lastEvaluationCycle, currentPromptVersion: $currentPromptVersion, agentNotes: $agentNotes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiAgentMetadataImpl &&
            (identical(other.lastEvaluationCycle, lastEvaluationCycle) ||
                other.lastEvaluationCycle == lastEvaluationCycle) &&
            (identical(other.currentPromptVersion, currentPromptVersion) ||
                other.currentPromptVersion == currentPromptVersion) &&
            (identical(other.agentNotes, agentNotes) ||
                other.agentNotes == agentNotes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    lastEvaluationCycle,
    currentPromptVersion,
    agentNotes,
  );

  /// Create a copy of AiAgentMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiAgentMetadataImplCopyWith<_$AiAgentMetadataImpl> get copyWith =>
      __$$AiAgentMetadataImplCopyWithImpl<_$AiAgentMetadataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AiAgentMetadataImplToJson(this);
  }
}

abstract class _AiAgentMetadata implements AiAgentMetadata {
  const factory _AiAgentMetadata({
    @TimestampConverter()
    @JsonKey(name: 'last_evaluation_cycle')
    required final DateTime lastEvaluationCycle,
    @JsonKey(name: 'current_prompt_version')
    required final String currentPromptVersion,
    @JsonKey(name: 'agent_notes') final String agentNotes,
  }) = _$AiAgentMetadataImpl;

  factory _AiAgentMetadata.fromJson(Map<String, dynamic> json) =
      _$AiAgentMetadataImpl.fromJson;

  @override
  @TimestampConverter()
  @JsonKey(name: 'last_evaluation_cycle')
  DateTime get lastEvaluationCycle;

  /// 現在使用中のメタプロンプト版（例: "v2.4_empathetic_sports_blend"）。
  @override
  @JsonKey(name: 'current_prompt_version')
  String get currentPromptVersion;

  /// エージェントの自己評価メモ（自律的に書き換える内省ノート）。
  @override
  @JsonKey(name: 'agent_notes')
  String get agentNotes;

  /// Create a copy of AiAgentMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiAgentMetadataImplCopyWith<_$AiAgentMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InterestProfile _$InterestProfileFromJson(Map<String, dynamic> json) {
  return _InterestProfile.fromJson(json);
}

/// @nodoc
mixin _$InterestProfile {
  /// カテゴリ名 → 関心スコア(0-100)。例: { "soccer": 85, "space": 40 }
  @JsonKey(name: 'current_interests')
  Map<String, int> get currentInterests => throw _privateConstructorUsedError;
  @JsonKey(name: 'ai_agent_metadata')
  AiAgentMetadata get aiAgentMetadata => throw _privateConstructorUsedError;

  /// Serializes this InterestProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InterestProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InterestProfileCopyWith<InterestProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InterestProfileCopyWith<$Res> {
  factory $InterestProfileCopyWith(
    InterestProfile value,
    $Res Function(InterestProfile) then,
  ) = _$InterestProfileCopyWithImpl<$Res, InterestProfile>;
  @useResult
  $Res call({
    @JsonKey(name: 'current_interests') Map<String, int> currentInterests,
    @JsonKey(name: 'ai_agent_metadata') AiAgentMetadata aiAgentMetadata,
  });

  $AiAgentMetadataCopyWith<$Res> get aiAgentMetadata;
}

/// @nodoc
class _$InterestProfileCopyWithImpl<$Res, $Val extends InterestProfile>
    implements $InterestProfileCopyWith<$Res> {
  _$InterestProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InterestProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? currentInterests = null, Object? aiAgentMetadata = null}) {
    return _then(
      _value.copyWith(
            currentInterests: null == currentInterests
                ? _value.currentInterests
                : currentInterests // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            aiAgentMetadata: null == aiAgentMetadata
                ? _value.aiAgentMetadata
                : aiAgentMetadata // ignore: cast_nullable_to_non_nullable
                      as AiAgentMetadata,
          )
          as $Val,
    );
  }

  /// Create a copy of InterestProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AiAgentMetadataCopyWith<$Res> get aiAgentMetadata {
    return $AiAgentMetadataCopyWith<$Res>(_value.aiAgentMetadata, (value) {
      return _then(_value.copyWith(aiAgentMetadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$InterestProfileImplCopyWith<$Res>
    implements $InterestProfileCopyWith<$Res> {
  factory _$$InterestProfileImplCopyWith(
    _$InterestProfileImpl value,
    $Res Function(_$InterestProfileImpl) then,
  ) = __$$InterestProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'current_interests') Map<String, int> currentInterests,
    @JsonKey(name: 'ai_agent_metadata') AiAgentMetadata aiAgentMetadata,
  });

  @override
  $AiAgentMetadataCopyWith<$Res> get aiAgentMetadata;
}

/// @nodoc
class __$$InterestProfileImplCopyWithImpl<$Res>
    extends _$InterestProfileCopyWithImpl<$Res, _$InterestProfileImpl>
    implements _$$InterestProfileImplCopyWith<$Res> {
  __$$InterestProfileImplCopyWithImpl(
    _$InterestProfileImpl _value,
    $Res Function(_$InterestProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InterestProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? currentInterests = null, Object? aiAgentMetadata = null}) {
    return _then(
      _$InterestProfileImpl(
        currentInterests: null == currentInterests
            ? _value._currentInterests
            : currentInterests // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        aiAgentMetadata: null == aiAgentMetadata
            ? _value.aiAgentMetadata
            : aiAgentMetadata // ignore: cast_nullable_to_non_nullable
                  as AiAgentMetadata,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InterestProfileImpl implements _InterestProfile {
  const _$InterestProfileImpl({
    @JsonKey(name: 'current_interests')
    final Map<String, int> currentInterests = const <String, int>{},
    @JsonKey(name: 'ai_agent_metadata') required this.aiAgentMetadata,
  }) : _currentInterests = currentInterests;

  factory _$InterestProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$InterestProfileImplFromJson(json);

  /// カテゴリ名 → 関心スコア(0-100)。例: { "soccer": 85, "space": 40 }
  final Map<String, int> _currentInterests;

  /// カテゴリ名 → 関心スコア(0-100)。例: { "soccer": 85, "space": 40 }
  @override
  @JsonKey(name: 'current_interests')
  Map<String, int> get currentInterests {
    if (_currentInterests is EqualUnmodifiableMapView) return _currentInterests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_currentInterests);
  }

  @override
  @JsonKey(name: 'ai_agent_metadata')
  final AiAgentMetadata aiAgentMetadata;

  @override
  String toString() {
    return 'InterestProfile(currentInterests: $currentInterests, aiAgentMetadata: $aiAgentMetadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InterestProfileImpl &&
            const DeepCollectionEquality().equals(
              other._currentInterests,
              _currentInterests,
            ) &&
            (identical(other.aiAgentMetadata, aiAgentMetadata) ||
                other.aiAgentMetadata == aiAgentMetadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_currentInterests),
    aiAgentMetadata,
  );

  /// Create a copy of InterestProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InterestProfileImplCopyWith<_$InterestProfileImpl> get copyWith =>
      __$$InterestProfileImplCopyWithImpl<_$InterestProfileImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$InterestProfileImplToJson(this);
  }
}

abstract class _InterestProfile implements InterestProfile {
  const factory _InterestProfile({
    @JsonKey(name: 'current_interests') final Map<String, int> currentInterests,
    @JsonKey(name: 'ai_agent_metadata')
    required final AiAgentMetadata aiAgentMetadata,
  }) = _$InterestProfileImpl;

  factory _InterestProfile.fromJson(Map<String, dynamic> json) =
      _$InterestProfileImpl.fromJson;

  /// カテゴリ名 → 関心スコア(0-100)。例: { "soccer": 85, "space": 40 }
  @override
  @JsonKey(name: 'current_interests')
  Map<String, int> get currentInterests;
  @override
  @JsonKey(name: 'ai_agent_metadata')
  AiAgentMetadata get aiAgentMetadata;

  /// Create a copy of InterestProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InterestProfileImplCopyWith<_$InterestProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
