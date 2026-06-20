import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'interest_profile.freezed.dart';
part 'interest_profile.g.dart';

/// 自己最適化AIエージェントのメタデータ。
///
/// 3rd Stage の自律フィードバックループ（AI DevOps）が更新する。
@freezed
class AiAgentMetadata with _$AiAgentMetadata {
  const factory AiAgentMetadata({
    @TimestampConverter()
    @JsonKey(name: 'last_evaluation_cycle')
    required DateTime lastEvaluationCycle,

    /// 現在使用中のメタプロンプト版（例: "v2.4_empathetic_sports_blend"）。
    @JsonKey(name: 'current_prompt_version') required String currentPromptVersion,

    /// エージェントの自己評価メモ（自律的に書き換える内省ノート）。
    @JsonKey(name: 'agent_notes') @Default('') String agentNotes,
  }) = _AiAgentMetadata;

  factory AiAgentMetadata.fromJson(Map<String, dynamic> json) =>
      _$AiAgentMetadataFromJson(json);
}

/// Firestore `/users/{userId}/interest_profile` に対応するモデル。
///
/// Analytics Agent が数値化した関心プロファイル + AIエージェントの稼働メタ情報。
@freezed
class InterestProfile with _$InterestProfile {
  const factory InterestProfile({
    /// カテゴリ名 → 関心スコア(0-100)。例: { "soccer": 85, "space": 40 }
    @JsonKey(name: 'current_interests')
    @Default(<String, int>{})
    Map<String, int> currentInterests,
    @JsonKey(name: 'ai_agent_metadata') required AiAgentMetadata aiAgentMetadata,
  }) = _InterestProfile;

  factory InterestProfile.fromJson(Map<String, dynamic> json) =>
      _$InterestProfileFromJson(json);
}
