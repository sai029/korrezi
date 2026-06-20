import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/models/personalized_feed_item.dart';
import '../data/feed_repository.dart';

/// Child Mode フィードの状態管理（AsyncNotifier）。
///
/// Firebase が利用可能なら Firestore `/users/{userId}/personalized_feed` を取得し、
/// 未初期化・データ無し・エラー時はサンプルデータにフォールバックする。
class ChildFeedNotifier extends AsyncNotifier<List<PersonalizedFeedItem>> {
  FeedRepository? _repo;
  String? _userId;

  @override
  Future<List<PersonalizedFeedItem>> build() async {
    // Firebase 未初期化時はサンプルデータで動作。
    if (!ref.watch(firebaseReadyProvider)) return _sampleFeed;

    _userId = await ref.watch(currentUserIdProvider.future);
    _repo = ref.watch(feedRepositoryProvider);
    try {
      final items = await _repo!.fetchFeed(_userId!);
      // 投入前など空のときはサンプルで開発を継続できるようにする。
      return items.isEmpty ? _sampleFeed : items;
    } catch (_) {
      // 権限不足・オフライン等はサンプルにフォールバック。
      return _sampleFeed;
    }
  }

  /// Telemetry Agent: 記事の閲覧秒数を記録する。
  ///
  /// ローカル状態を楽観的に更新したうえで、可能なら Firestore へ
  /// view_duration_seconds / is_viewed を反映する。
  Future<void> recordView(String newsId, int durationSeconds) async {
    final current = state.valueOrNull;
    if (current != null) {
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

    final repo = _repo;
    final userId = _userId;
    if (repo == null || userId == null) return;
    try {
      await repo.recordView(userId, newsId, durationSeconds);
    } catch (_) {
      // オフライン等は無視（ローカル状態は更新済み）。
    }
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
