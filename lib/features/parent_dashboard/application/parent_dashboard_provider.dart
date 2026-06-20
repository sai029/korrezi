import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/models/interest_profile.dart';
import '../../../shared/models/news_pool.dart';
import '../data/parent_dashboard_repository.dart';

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

  /// 当日の記事（大人向け要約 parent_summary を表示）。
  final List<NewsPool> articles;
}

/// Parent Dashboard の状態管理。
///
/// Firebase が利用可能なら Firestore の interest_profile と news_pool を取得する。
/// 未初期化・データ無し・エラー時はサンプルにフォールバックする。
///
/// TODO: talkPrompts は本来 Cloud Functions(Gemini) が生成する。CF 未実装のため
/// 現状はプロファイルと記事から簡易生成（[_buildTalkPrompts]）している。
class ParentDashboardNotifier extends AsyncNotifier<ParentDashboardData> {
  @override
  Future<ParentDashboardData> build() async {
    if (!ref.watch(firebaseReadyProvider)) return _sample;

    try {
      final userId = await ref.watch(currentUserIdProvider.future);
      final repo = ref.watch(parentDashboardRepositoryProvider);
      final profile =
          await repo.fetchInterestProfile(userId) ?? _sample.profile;
      final fetched = await repo.fetchTodaysArticles();
      final articles = fetched.isEmpty ? _sample.articles : fetched;
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
    List<NewsPool> articles,
  ) {
    final prompts = <String>[
      for (final a in articles.take(3))
        '「${a.originalTitle}」について、どう思うか聞いてみよう。',
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

// ----- 開発用サンプルデータ -----
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
    NewsPool(
      originalTitle: 'Global Environmental Regulations Strengthened',
      publishedAt: DateTime.parse('2026-06-16T00:00:00Z'),
      parentSummary: '・各国が炭素排出の新しい規制を導入\n・スタジアム等の大型施設も対象\n・子ども世代への影響を見据えた長期目標',
      childBodyWithRuby: '〔世界｜せかい〕の〔環境｜かんきょう〕を守るルールができたよ。',
    ),
    NewsPool(
      originalTitle: 'Life Aboard the Space Station',
      publishedAt: DateTime.parse('2026-06-15T00:00:00Z'),
      parentSummary: '・宇宙飛行士の食事と無重力下の工夫\n・水分補給と栄養管理の最新事情',
      childBodyWithRuby: '〔宇宙｜うちゅう〕では〔特別｜とくべつ〕なごはんを〔食｜た〕べるよ。',
    ),
  ],
);
