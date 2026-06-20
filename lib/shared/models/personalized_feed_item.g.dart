// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personalized_feed_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ThumbnailConfigImpl _$$ThumbnailConfigImplFromJson(
  Map<String, dynamic> json,
) => _$ThumbnailConfigImpl(
  mode:
      $enumDecodeNullable(_$ThumbnailModeEnumMap, json['mode']) ??
      ThumbnailMode.textOverlay,
  baseAsset: json['base_asset'] as String? ?? '',
  optionalGeneratedUrl: json['optional_generated_url'] as String? ?? '',
);

Map<String, dynamic> _$$ThumbnailConfigImplToJson(
  _$ThumbnailConfigImpl instance,
) => <String, dynamic>{
  'mode': _$ThumbnailModeEnumMap[instance.mode]!,
  'base_asset': instance.baseAsset,
  'optional_generated_url': instance.optionalGeneratedUrl,
};

const _$ThumbnailModeEnumMap = {
  ThumbnailMode.textOverlay: 'text_overlay',
  ThumbnailMode.generated: 'generated',
};

_$PersonalizedFeedItemImpl _$$PersonalizedFeedItemImplFromJson(
  Map<String, dynamic> json,
) => _$PersonalizedFeedItemImpl(
  newsId: json['news_id'] as String,
  interestContext: json['interest_context'] as String,
  displayTitle: json['display_title'] as String,
  displayTagline: json['display_tagline'] as String,
  thumbnailConfig: ThumbnailConfig.fromJson(
    json['thumbnail_config'] as Map<String, dynamic>,
  ),
  isViewed: json['is_viewed'] as bool? ?? false,
  viewDurationSeconds: (json['view_duration_seconds'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$PersonalizedFeedItemImplToJson(
  _$PersonalizedFeedItemImpl instance,
) => <String, dynamic>{
  'news_id': instance.newsId,
  'interest_context': instance.interestContext,
  'display_title': instance.displayTitle,
  'display_tagline': instance.displayTagline,
  'thumbnail_config': instance.thumbnailConfig,
  'is_viewed': instance.isViewed,
  'view_duration_seconds': instance.viewDurationSeconds,
};
