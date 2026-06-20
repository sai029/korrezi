// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interest_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AiAgentMetadataImpl _$$AiAgentMetadataImplFromJson(
  Map<String, dynamic> json,
) => _$AiAgentMetadataImpl(
  lastEvaluationCycle: const TimestampConverter().fromJson(
    json['last_evaluation_cycle'],
  ),
  currentPromptVersion: json['current_prompt_version'] as String,
  agentNotes: json['agent_notes'] as String? ?? '',
);

Map<String, dynamic> _$$AiAgentMetadataImplToJson(
  _$AiAgentMetadataImpl instance,
) => <String, dynamic>{
  'last_evaluation_cycle': const TimestampConverter().toJson(
    instance.lastEvaluationCycle,
  ),
  'current_prompt_version': instance.currentPromptVersion,
  'agent_notes': instance.agentNotes,
};

_$InterestProfileImpl _$$InterestProfileImplFromJson(
  Map<String, dynamic> json,
) => _$InterestProfileImpl(
  currentInterests:
      (json['current_interests'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const <String, int>{},
  aiAgentMetadata: AiAgentMetadata.fromJson(
    json['ai_agent_metadata'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$$InterestProfileImplToJson(
  _$InterestProfileImpl instance,
) => <String, dynamic>{
  'current_interests': instance.currentInterests,
  'ai_agent_metadata': instance.aiAgentMetadata,
};
