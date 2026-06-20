import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/models/news_pool.dart';
import '../data/news_repository.dart';

/// Common View で読む記事一覧（左ナビゲーショングリッドのもと）。
///
/// Firebase が利用可能なら Firestore `/news_pool` を取得し、
/// 未初期化・データ無し・エラー時はサンプルにフォールバックする。
class CommonViewNotifier extends AsyncNotifier<List<NewsPool>> {
  @override
  Future<List<NewsPool>> build() async {
    if (!ref.watch(firebaseReadyProvider)) return _sample;
    try {
      final articles = await ref.watch(newsRepositoryProvider).fetchNewsPool();
      return articles.isEmpty ? _sample : articles;
    } catch (_) {
      return _sample;
    }
  }
}

final commonViewProvider =
    AsyncNotifierProvider<CommonViewNotifier, List<NewsPool>>(
  CommonViewNotifier.new,
);

/// 右ペインで表示中の記事インデックス。
final selectedArticleIndexProvider = StateProvider<int>((ref) => 0);

// ----- 開発用サンプルデータ -----
final _sample = [
  NewsPool(
    originalTitle: 'エコ・スタジアム',
    publishedAt: DateTime.parse('2026-06-16T00:00:00Z'),
    parentSummary: 'スタジアムの環境配慮の取り組み。',
    childBodyWithRuby:
        '〔世界｜せかい〕の〔環境｜かんきょう〕を守るため、〔大｜おお〕きな'
        'サッカー〔場｜じょう〕も〔工夫｜くふう〕をはじめたよ。'
        '〔太陽｜たいよう〕の〔光｜ひかり〕で〔電気｜でんき〕をつくるんだって。',
  ),
  NewsPool(
    originalTitle: 'うちゅうのごはん',
    publishedAt: DateTime.parse('2026-06-15T00:00:00Z'),
    parentSummary: '宇宙飛行士の食事の工夫。',
    childBodyWithRuby:
        '〔宇宙｜うちゅう〕では〔体｜からだ〕がふわふわ〔浮｜う〕くよ。'
        'だから〔特別｜とくべつ〕なやり〔方｜かた〕でごはんを〔食｜た〕べるんだ。',
  ),
  NewsPool(
    originalTitle: 'みんなで決めるルール',
    publishedAt: DateTime.parse('2026-06-14T00:00:00Z'),
    parentSummary: '国際的な合意形成について。',
    childBodyWithRuby:
        'たくさんの〔国｜くに〕が〔集｜あつ〕まって、'
        'みんなの〔未来｜みらい〕のための〔約束｜やくそく〕をしたよ。',
  ),
];
