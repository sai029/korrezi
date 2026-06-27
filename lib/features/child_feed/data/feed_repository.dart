import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/models/news_pool.dart';
import '../../../shared/models/personalized_feed_item.dart';

/// フィードの取得とテレメトリ書き込みを担うリポジトリ。
///
/// 読み取り: `/news_pool` — 全ユーザー共通のため新規ユーザーでも即座に表示。
/// 書き込み: `/users/{userId}/personalized_feed` — 閲覧ログのみ（テレメトリ）。
///           `/users/{userId}/interest_profile` — 関心スコア。
class FeedRepository {
  FeedRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _feedRef(String userId) =>
      _db.collection('users').doc(userId).collection('personalized_feed');

  /// news_pool から全記事を取得して PersonalizedFeedItem に変換する。
  ///
  /// 新規ユーザーも personalized_feed の有無に関係なく即座に表示できる。
  Future<List<PersonalizedFeedItem>> fetchFeed(String userId) async {
    final snap = await _db
        .collection('news_pool')
        .orderBy('published_at', descending: true)
        .limit(20)
        .get();
    final items = <PersonalizedFeedItem>[];
    for (final d in snap.docs) {
      try {
        final pool = NewsPool.fromJson(d.data());
        items.add(PersonalizedFeedItem(
          newsId: d.id,
          interestContext: pool.interestContext,
          displayTitle: pool.childTitleWithRuby.isNotEmpty
              ? pool.childTitleWithRuby
              : (pool.displayTitle.isNotEmpty
                  ? pool.displayTitle
                  : pool.originalTitle),
          displayTagline: pool.displayTagline,
          thumbnailConfig: pool.thumbnailConfig,
        ));
      } catch (_) {
        // フィールド欠損のドキュメントはスキップ
      }
    }
    return items;
  }

  /// personalized_feed が空か、最終パーソナライズから24時間以上経過していれば true を返す。
  Future<bool> needsPersonalization(String userId) async {
    final snap = await _feedRef(userId).limit(1).get();
    if (snap.docs.isEmpty) return true;

    final raw = snap.docs.first.data()['personalized_at'];
    if (raw == null) return true;

    final lastRun = (raw as Timestamp).toDate();
    return DateTime.now().difference(lastRun) > const Duration(hours: 24);
  }

  /// AI パーソナライズ済みフィードを personalized_feed から取得する。
  ///
  /// personalizeArticles Cloud Function が書き込んだ display_title / display_tagline を
  /// 読み込む。display_title が未設定のドキュメント（テレメトリのみ）はスキップする。
  Future<List<PersonalizedFeedItem>> fetchPersonalizedFeed(
      String userId) async {
    final snap = await _feedRef(userId).limit(20).get();

    final items = <PersonalizedFeedItem>[];
    for (final d in snap.docs) {
      final raw = d.data();
      // display_title が存在しないドキュメントはパーソナライズ前のテレメトリのみ
      if (raw['display_title'] == null) continue;
      final data = Map<String, dynamic>.from(raw);
      data['news_id'] = d.id;
      try {
        items.add(PersonalizedFeedItem.fromJson(data));
      } catch (_) {
        // フィールド欠損のドキュメントはスキップ
      }
    }
    return items;
  }

  /// Telemetry Agent: 記事の閲覧秒数と閲覧済みフラグを記録する。
  ///
  /// view_duration_seconds は累積（インクリメント）で更新する。
  Future<void> recordView(
    String userId,
    String newsId,
    int durationSeconds,
  ) async {
    await _feedRef(userId).doc(newsId).set(
      {
        'is_viewed': true,
        'view_duration_seconds': FieldValue.increment(durationSeconds),
      },
      SetOptions(merge: true),
    );
  }

  /// Analytics Agent: 関心カテゴリのスコアを滞在秒数分だけ加算する。
  ///
  /// `interest_profile/current` の `current_interests.{context}` を
  /// インクリメントする。ドキュメントが未作成でも自動生成される。
  Future<void> recordInterest(
    String userId,
    String interestContext,
    int durationSeconds,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('interest_profile')
        .doc('current')
        .set(
          {
            'current_interests': {
              interestContext: FieldValue.increment(durationSeconds),
            },
          },
          SetOptions(
            mergeFields: [FieldPath(['current_interests', interestContext])],
          ),
        );
  }
}

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepository(ref.watch(firestoreProvider)),
);
