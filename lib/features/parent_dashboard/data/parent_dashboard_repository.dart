import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/models/interest_profile.dart';
import '../../../shared/models/news_pool.dart';

/// Parent Dashboard 用の Firestore アクセス。
///
/// 興味プロファイル（`/users/{userId}/interest_profile/current`）と
/// 当日記事（`/news_pool`）を取得する。
///
/// 注: 仕様では `interest_profile` を単一オブジェクトとして表現しているため、
/// well-known な doc id `current` を持つドキュメントとして格納する。
class ParentDashboardRepository {
  ParentDashboardRepository(this._db);

  final FirebaseFirestore _db;

  /// 興味プロファイルを取得する。未作成なら null。
  Future<InterestProfile?> fetchInterestProfile(String userId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('interest_profile')
        .doc('current')
        .get();
    final data = doc.data();
    if (data == null) return null;
    return InterestProfile.fromJson(data);
  }

  /// 保護者向け要約を表示する当日の記事を doc id 付きで取得する。
  ///
  /// doc id（= newsId）は子どもの閲覧状況（personalized_feed）との突合に使う。
  Future<List<({String newsId, NewsPool article})>> fetchTodaysArticles({
    int limit = 10,
  }) async {
    final snap = await _db
        .collection('news_pool')
        .orderBy('published_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => (newsId: d.id, article: NewsPool.fromJson(d.data())))
        .toList();
  }

  /// 子どもが閲覧済みの記事 ID 集合を取得する。
  ///
  /// `users/{userId}/personalized_feed` のうち `is_viewed == true` の doc id を返す。
  Future<Set<String>> fetchViewedNewsIds(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('personalized_feed')
        .where('is_viewed', isEqualTo: true)
        .get();
    return snap.docs.map((d) => d.id).toSet();
  }
}

final parentDashboardRepositoryProvider = Provider<ParentDashboardRepository>(
  (ref) => ParentDashboardRepository(ref.watch(firestoreProvider)),
);
