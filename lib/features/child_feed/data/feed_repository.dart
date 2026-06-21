import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/models/personalized_feed_item.dart';

/// Firestore `/users/{userId}/personalized_feed` を扱うリポジトリ。
///
/// Child Mode のパーソナライズフィードの取得と、Telemetry Agent による
/// 閲覧ログ（view_duration_seconds / is_viewed）の書き込みを担う。
class FeedRepository {
  FeedRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _feedRef(String userId) =>
      _db.collection('users').doc(userId).collection('personalized_feed');

  /// パーソナライズフィードを1回取得する。
  Future<List<PersonalizedFeedItem>> fetchFeed(String userId) async {
    final snap = await _feedRef(userId).get();
    return snap.docs
        .map((d) => PersonalizedFeedItem.fromJson(d.data()))
        .toList();
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
