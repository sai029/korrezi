import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/personalized_feed_item.dart';

/// Child Mode フィードの状態管理（AsyncNotifier）。
///
/// 本来は Firestore `/users/{userId}/personalized_feed` を購読するが、
/// Firebase の認証/データ投入が未整備のため、現段階ではサンプルデータを返す。
/// TODO: Firestore ストリーム購読に差し替える（data層リポジトリ経由）。
class ChildFeedNotifier extends AsyncNotifier<List<PersonalizedFeedItem>> {
  @override
  Future<List<PersonalizedFeedItem>> build() async {
    // TODO: data層の FeedRepository.watchFeed(userId) に置き換える。
    return _sampleFeed;
  }

  /// Telemetry Agent: 記事の閲覧秒数を記録する。
  ///
  /// 現段階はローカル状態を更新するのみ。
  /// TODO: Firestore の該当ドキュメントへ view_duration_seconds / is_viewed を書き込む。
  void recordView(String newsId, int durationSeconds) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final item in current)
        if (item.newsId == newsId)
          item.copyWith(
            isViewed: true,
            viewDurationSeconds: item.viewDurationSeconds + durationSeconds,
          )
        else
          item,
    ]);
  }
}

final childFeedProvider =
    AsyncNotifierProvider<ChildFeedNotifier, List<PersonalizedFeedItem>>(
  ChildFeedNotifier.new,
);

// ----- 開発用サンプルデータ（Firestore連携までの仮データ）-----
const _sampleFeed = <PersonalizedFeedItem>[
  PersonalizedFeedItem(
    newsId: 'news_eco_stadium',
    interestContext: 'Soccer',
    displayTitle: 'エコ・スタジアム？サッカーが気候変動とたたかう方法',
    displayTagline: 'きみの大すきなスポーツが地球を救えるかも？',
    thumbnailConfig: ThumbnailConfig(
      mode: ThumbnailMode.textOverlay,
      baseAsset: 'assets/images/categories/soccer.png',
    ),
  ),
  PersonalizedFeedItem(
    newsId: 'news_space_food',
    interestContext: 'Space',
    displayTitle: '宇宙では何を食べるの？うちゅう飛行士のごはん大公開',
    displayTagline: '無重力でスープを飲むひみつのテクニック！',
    thumbnailConfig: ThumbnailConfig(
      mode: ThumbnailMode.textOverlay,
      baseAsset: 'assets/images/categories/space.png',
    ),
  ),
  PersonalizedFeedItem(
    newsId: 'news_env_rule',
    interestContext: 'Environment',
    displayTitle: '世界の環境を守る新しいルールができたよ',
    displayTagline: 'みんなの未来のために大人たちが決めたこと。',
    thumbnailConfig: ThumbnailConfig(
      mode: ThumbnailMode.textOverlay,
      baseAsset: 'assets/images/categories/environment.png',
    ),
  ),
];
