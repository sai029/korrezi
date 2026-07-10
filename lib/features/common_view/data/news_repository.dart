import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/models/news_pool.dart';

/// Firestore `/news_pool` を扱うリポジトリ。
///
/// 1日1回の Curated Global Batch で生成される、全ユーザー共通の元記事プール。
/// Common View（親子で読む）の記事一覧の供給源。
class NewsRepository {
  NewsRepository(this._db);

  final FirebaseFirestore _db;

  /// 公開日の新しい順にニュースプールを取得する。
  Future<List<NewsPool>> fetchNewsPool({int limit = 40}) async {
    final snap = await _db
        .collection('news_pool')
        .orderBy('published_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['news_id'] = d.id;
      return NewsPool.fromJson(data);
    }).toList();
  }
}

final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => NewsRepository(ref.watch(firestoreProvider)),
);
