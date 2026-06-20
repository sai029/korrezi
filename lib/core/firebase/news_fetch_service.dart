import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_providers.dart';

/// Cloud Functions の `fetchNews` を呼び出して GNews の実記事を Firestore へ
/// 取り込む dev 用サービス。
///
/// 関数側が `news_pool` と呼び出しユーザーの `personalized_feed` を更新するため、
/// 呼び出し後に各画面のプロバイダを invalidate すれば反映される。
class NewsFetchService {
  NewsFetchService(this._functions);

  final FirebaseFunctions _functions;

  /// GNews から記事を取得して書き込み、取り込んだ件数を返す。
  Future<int> fetchNews() async {
    final callable = _functions.httpsCallable('fetchNews');
    final result = await callable.call<Map<String, dynamic>>();
    final count = result.data['count'];
    return count is int ? count : int.tryParse('$count') ?? 0;
  }
}

final newsFetchServiceProvider = Provider<NewsFetchService>(
  (ref) => NewsFetchService(ref.watch(functionsProvider)),
);
