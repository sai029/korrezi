import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/interest_profile.dart';
import '../../../shared/models/news_pool.dart';

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
/// TODO: Firestore `/users/{userId}/interest_profile` と `/news_pool` を購読し、
/// talkPrompts は Cloud Functions(Gemini) 生成値に差し替える。
class ParentDashboardNotifier extends AsyncNotifier<ParentDashboardData> {
  @override
  Future<ParentDashboardData> build() async => _sample;
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
