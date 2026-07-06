import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/models/interest_profile.dart';
import '../../../shared/models/news_pool.dart';
import '../data/parent_dashboard_repository.dart';

/// 親画面で1記事を表すビューモデル。
///
/// news_pool の記事本体に、子ども画面へ遷移するための並び順 index（[feedIndex]）
/// を付与したもの。
///
/// 既読/未読は「1つの真実の源」に統一するため、この VM には持たせず、
/// 表示時に [viewedNewsIdsProvider]（＝childFeedProvider 由来）と突合して求める。
/// こうすることで、子どもが記事を読むと親画面の既読表示も即座に連動する。
class ParentArticle {
  const ParentArticle({
    required this.newsId,
    required this.article,
    required this.feedIndex,
  });

  /// news_pool のドキュメント ID。
  final String newsId;

  /// 記事本体（タイトル・保護者向け要約など）。
  final NewsPool article;

  /// Common View（子どもが読む画面）での記事 index。遷移時に使う。
  final int feedIndex;
}

/// Parent Dashboard 表示に必要なデータ束。
class ParentDashboardData {
  const ParentDashboardData({
    required this.profile,
    required this.talkPrompts,
    required this.articles,
  });

  /// 興味プロファイル（Interest Cloud / Topic Badges のもと）。
  final InterestProfile profile;

  /// AI生成の親子トークプロンプト。
  final List<String> talkPrompts;

  /// 当日の記事（遷移 index 付き）。
  final List<ParentArticle> articles;

  /// 当日記事の総数。
  int get totalCount => articles.length;

  /// 当日記事のうち子どもが読んだ件数（[viewed] は viewedNewsIdsProvider の集合）。
  int readCount(Set<String> viewed) =>
      articles.where((a) => viewed.contains(a.newsId)).length;

  /// 当日の既読率(0.0–1.0)。「きょうの よみの木」の生い茂り具合を決める指標。
  /// 記事0件の日は 0（＝種・芽の状態）。
  double readRatio(Set<String> viewed) =>
      totalCount == 0 ? 0 : readCount(viewed) / totalCount;
}

/// Parent Dashboard の状態管理。
///
/// Firebase が利用可能なら Firestore の interest_profile / news_pool /
/// personalized_feed(既読) を取得して結合する。
/// 未初期化・データ無し・エラー時はサンプルにフォールバックする。
///
/// TODO: talkPrompts は本来 Cloud Functions(Gemini) が生成する。CF 未実装のため
/// 現状はプロファイルと記事から簡易生成（[_buildTalkPrompts]）している。
class ParentDashboardNotifier extends AsyncNotifier<ParentDashboardData> {
  @override
  Future<ParentDashboardData> build() async {
    if (!ref.watch(firebaseReadyProvider)) return _sample;

    try {
      final userId = ref.watch(currentUserIdProvider);
      final repo = ref.watch(parentDashboardRepositoryProvider);

      // 興味プロファイルの取得・パース失敗（例: ai_agent_metadata 未書き込み）で
      // 記事一覧まで巻き添えにしてサンプルへ落ちないよう、ここで隔離する。
      InterestProfile profile;
      try {
        profile = await repo.fetchInterestProfile(userId) ?? _sample.profile;
      } catch (_) {
        profile = _sample.profile;
      }

      final fetched = await repo.fetchTodaysArticles();
      if (fetched.isEmpty) return _sample.copyForArticles(profile);

      // 既読/未読は viewedNewsIdsProvider（childFeedProvider 由来）で表示時に
      // 突合するため、ここでは付与しない。
      final articles = [
        for (final (index, row) in fetched.indexed)
          ParentArticle(
            newsId: row.newsId,
            article: row.article,
            feedIndex: index,
          ),
      ];
      return ParentDashboardData(
        profile: profile,
        articles: articles,
        talkPrompts: _buildTalkPrompts(profile, articles),
      );
    } catch (_) {
      return _sample;
    }
  }

  /// 興味プロファイルと当日記事から親子トークの問いかけを簡易生成する。
  ///
  /// Cloud Functions(Gemini) 連携までの暫定実装。記事タイトルを「？」付きの
  /// 開かれた問いに変換し、上位の関心カテゴリにも触れる。
  List<String> _buildTalkPrompts(
    InterestProfile profile,
    List<ParentArticle> articles,
  ) {
    final prompts = <String>[
      for (final a in articles.take(3))
        '「${a.article.originalTitle}」について、どう思うか聞いてみよう。',
    ];

    final top = (profile.currentInterests.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .map((e) => e.key)
        .take(2)
        .toList();
    if (top.isNotEmpty) {
      prompts.add('最近は ${top.join(' と ')} に夢中みたい。一緒に話してみよう。');
    }
    return prompts.isEmpty ? _sample.talkPrompts : prompts;
  }
}

final parentDashboardProvider =
    AsyncNotifierProvider<ParentDashboardNotifier, ParentDashboardData>(
  ParentDashboardNotifier.new,
);

extension on ParentDashboardData {
  /// 取得した profile で差し替えた（記事はサンプルのままの）束を作る。
  ParentDashboardData copyForArticles(InterestProfile profile) =>
      ParentDashboardData(
        profile: profile,
        talkPrompts: talkPrompts,
        articles: articles,
      );
}

// ----- 開発用サンプルデータ -----
// Firebase 未接続でもデザイン確認できるよう、既読/未読を混在させている。
final _sample = ParentDashboardData(
  profile: InterestProfile(
    currentInterests: const {'soccer': 85, 'space': 40, 'environment': 65},
    aiAgentMetadata: AiAgentMetadata(
      lastEvaluationCycle: DateTime.parse('2026-06-16T12:00:00Z'),
      currentPromptVersion: 'v2.4_empathetic_sports_blend',
      agentNotes: '子どもはスポーツの比喩に強く反応。応用科学へ重みをシフト中。',
    ),
  ),
  talkPrompts: const [
    'サッカー場が環境にやさしくなってるんだって。どんな工夫だと思う？',
    'もし宇宙でごはんを食べるなら、何が一番むずかしいと思う？',
    '世界の国が力を合わせるのって、どうして大事なのかな？',
  ],
  articles: [
    ParentArticle(
      newsId: 'news_env_rule',
      feedIndex: 0,
      article: NewsPool(
        originalTitle: 'Global Environmental Regulations Strengthened',
        publishedAt: DateTime.parse('2026-06-16T00:00:00Z'),
        interestContext: 'Environment',
        parentSummary: '・各国が炭素排出の新しい規制を導入\n・スタジアム等の大型施設も対象\n・子ども世代への影響を見据えた長期目標',
        childBodyWithRuby: '〔世界｜せかい〕の〔環境｜かんきょう〕を守るルールができたよ。',
      ),
    ),
    ParentArticle(
      newsId: 'news_space_food',
      feedIndex: 1,
      article: NewsPool(
        originalTitle: 'Life Aboard the Space Station',
        publishedAt: DateTime.parse('2026-06-15T00:00:00Z'),
        interestContext: 'Space',
        parentSummary: '・宇宙飛行士の食事と無重力下の工夫\n・水分補給と栄養管理の最新事情',
        childBodyWithRuby: '〔宇宙｜うちゅう〕では〔特別｜とくべつ〕なごはんを〔食｜た〕べるよ。',
      ),
    ),
  ],
);
