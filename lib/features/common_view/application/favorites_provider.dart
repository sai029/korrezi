import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../child_feed/data/feed_repository.dart';

/// ユーザーのお気に入り記事 newsId 集合を管理する。
///
/// toggle() で楽観的更新 → Firestore 書き込み。失敗時はロールバック。
class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    if (!ref.watch(firebaseReadyProvider)) return {};
    final userId = ref.watch(currentUserIdProvider);
    return ref.watch(feedRepositoryProvider).fetchFavoriteNewsIds(userId);
  }

  Future<void> toggle(String newsId) async {
    final prev = state.valueOrNull ?? {};
    final wasFavorited = prev.contains(newsId);

    // 楽観的更新
    final next = Set<String>.from(prev);
    wasFavorited ? next.remove(newsId) : next.add(newsId);
    state = AsyncData(next);

    try {
      await ref.read(feedRepositoryProvider).toggleFavorite(
            ref.read(currentUserIdProvider),
            newsId,
            !wasFavorited,
          );
    } catch (_) {
      state = AsyncData(prev); // ロールバック
    }
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);
