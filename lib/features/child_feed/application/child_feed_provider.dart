import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_agent_service.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/models/personalized_feed_item.dart';
import '../data/feed_repository.dart';

/// Child Mode フィードの状態管理（AsyncNotifier）。
///
/// ロード順:
///   1. personalized_feed（AI パーソナライズ済みキャッシュ）
///   2. personalized_feed が空なら personalizeArticles を実行して再取得
///   3. それでも空なら news_pool（生記事）にフォールバック
///   4. Firebase 未初期化時はサンプルデータにフォールバック
class ChildFeedNotifier extends AsyncNotifier<List<PersonalizedFeedItem>> {
  FeedRepository? _repo;
  AiAgentService? _ai;
  String? _userId;

  @override
  Future<List<PersonalizedFeedItem>> build() async {
    if (!ref.watch(firebaseReadyProvider)) return _sampleFeed;

    _userId = ref.watch(currentUserIdProvider);
    _repo = ref.watch(feedRepositoryProvider);
    _ai = ref.watch(aiAgentServiceProvider);

    // Step 1: news_pool から実記事を取得（common と完全に同じソース・同じ順序）
    List<PersonalizedFeedItem> raw = [];
    try {
      raw = await _repo!.fetchFeed(_userId!);
    } catch (_) {}

    if (raw.isEmpty) return _sampleFeed;

    // Step 2: 閲覧済みフラグを Firestore から反映する。
    // fetchFeed は news_pool から生成するため isViewed が常に false になる。
    // personalized_feed の is_viewed で上書きすることで既読状態を復元する。
    try {
      final viewedIds = await _repo!.fetchViewedNewsIds(_userId!);
      if (viewedIds.isNotEmpty) {
        raw = raw
            .map((item) => viewedIds.contains(item.newsId)
                ? item.copyWith(isViewed: true)
                : item)
            .toList();
      }
    } catch (_) {}

    // Step 4: パーソナライズ済みデータをオーバーレイ（任意）
    // personalized_feed のタイトル・タグライン・生成サムネを上書きし、
    // 記事の順序・件数は常に news_pool のものを使う。
    try {
      final personalized = await _repo!.fetchPersonalizedFeed(_userId!);
      if (personalized.isNotEmpty) {
        final pMap = {for (final p in personalized) p.newsId: p};
        raw = raw.map((item) {
          final p = pMap[item.newsId];
          if (p == null) return item;
          return item.copyWith(
            displayTitle: p.displayTitle.isNotEmpty
                ? p.displayTitle
                : item.displayTitle,
            displayTagline: p.displayTagline.isNotEmpty
                ? p.displayTagline
                : item.displayTagline,
            // 生成サムネがあれば上書き（Imagen 3 が生成済みの場合）
            thumbnailConfig:
                p.thumbnailConfig.optionalGeneratedUrl.isNotEmpty
                    ? p.thumbnailConfig
                    : item.thumbnailConfig,
          );
        }).toList();
      }
    } catch (_) {}

    // Step 5: バックグラウンドでパーソナライズを更新（UIをブロックしない）
    _schedulePersonalization();

    return raw;
  }

  /// バックグラウンドで24時間チェックを行い、必要なら personalizeArticles を実行する。
  ///
  /// 完了後に personalized_feed（サムネ含む）を再取得して state を更新するため、
  /// 生成されたサムネが即座にフィードに反映される。
  void _schedulePersonalization() {
    Future.microtask(() async {
      final repo = _repo;
      final userId = _userId;
      if (repo == null || userId == null) return;

      try {
        final shouldPersonalize = await repo.needsPersonalization(userId);
        if (!shouldPersonalize) return;

        await _ai?.personalizeArticles();
      } catch (_) {
        return; // パーソナライズ失敗 → state 更新しない
      }

      // パーソナライズ成功 → フィードを再取得して state を更新
      try {
        List<PersonalizedFeedItem> fresh = await repo.fetchFeed(userId);
        if (fresh.isEmpty) return;

        final personalized = await repo.fetchPersonalizedFeed(userId);
        if (personalized.isNotEmpty) {
          final pMap = {for (final p in personalized) p.newsId: p};
          fresh = fresh.map((item) {
            final p = pMap[item.newsId];
            if (p == null) return item;
            return item.copyWith(
              displayTitle: p.displayTitle.isNotEmpty
                  ? p.displayTitle
                  : item.displayTitle,
              displayTagline: p.displayTagline.isNotEmpty
                  ? p.displayTagline
                  : item.displayTagline,
              thumbnailConfig:
                  p.thumbnailConfig.optionalGeneratedUrl.isNotEmpty
                      ? p.thumbnailConfig
                      : item.thumbnailConfig,
            );
          }).toList();
        }

        state = AsyncData(fresh);
      } catch (_) {}
    });
  }

  /// Telemetry Agent: 記事の閲覧秒数を記録する（is_viewed は変更しない）。
  ///
  /// ローカル状態（viewDurationSeconds）を楽観的に更新したうえで Firestore に反映し、
  /// 興味検知 AI の自己学習ループも起動する。
  /// 既読フラグは markAsViewed が担う。
  Future<void> recordView(String newsId, int durationSeconds) async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData([
        for (final item in current)
          if (item.newsId == newsId)
            item.copyWith(
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

      // DISA: スコア計算は Cloud Function に委譲（fire-and-forget）。
      _ai?.updateInterestModel(
        newsId: newsId,
        viewDurationSeconds: durationSeconds,
      );
    } catch (_) {}
  }

  /// 記事詳細を開いたときに既読フラグを立てる。
  ///
  /// ローカル状態を即座に更新し（楽観的）、Firestore にも非同期で反映する。
  Future<void> markAsViewed(String newsId) async {
    final current = state.valueOrNull;
    if (current != null && current.any((i) => i.newsId == newsId)) {
      state = AsyncData([
        for (final item in current)
          if (item.newsId == newsId) item.copyWith(isViewed: true) else item,
      ]);
    }

    if (!ref.read(firebaseReadyProvider)) return;

    try {
      final userId = ref.read(currentUserIdProvider);
      await ref.read(feedRepositoryProvider).markAsViewed(userId, newsId);
    } catch (_) {}
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
