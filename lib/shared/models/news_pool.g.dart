// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_pool.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NewsPoolImpl _$$NewsPoolImplFromJson(Map<String, dynamic> json) =>
    _$NewsPoolImpl(
      originalTitle: json['original_title'] as String,
      publishedAt: const TimestampConverter().fromJson(json['published_at']),
      parentSummary: json['parent_summary'] as String,
      childBodyWithRuby: json['child_body_with_ruby'] as String,
      displayTitle: json['display_title'] as String? ?? '',
      displayTagline: json['display_tagline'] as String? ?? '',
      interestContext: json['interest_context'] as String? ?? 'ニュース',
      thumbnailConfig: json['thumbnail_config'] == null
          ? const ThumbnailConfig()
          : ThumbnailConfig.fromJson(
              json['thumbnail_config'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$$NewsPoolImplToJson(_$NewsPoolImpl instance) =>
    <String, dynamic>{
      'original_title': instance.originalTitle,
      'published_at': const TimestampConverter().toJson(instance.publishedAt),
      'parent_summary': instance.parentSummary,
      'child_body_with_ruby': instance.childBodyWithRuby,
      'display_title': instance.displayTitle,
      'display_tagline': instance.displayTagline,
      'interest_context': instance.interestContext,
      'thumbnail_config': instance.thumbnailConfig.toJson(),
    };
