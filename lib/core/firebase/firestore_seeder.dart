import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/interest_profile.dart';
import '../../shared/models/news_pool.dart';
import '../../shared/models/personalized_feed_item.dart';
import 'firebase_providers.dart';

/// 開発用に Firestore へサンプルデータを投入するシーダー。
///
/// Cloud Functions（Curated Global Batch / 動的ブレンド）が未実装のため、
/// 実データの代わりに以下を書き込む:
/// - `/news_pool/{id}`            … 全ユーザー共通の元記事
/// - `/users/{uid}/personalized_feed/{id}` … 個人向けにブレンドしたフィード
/// - `/users/{uid}/interest_profile/current` … 興味プロファイル
///
/// news_pool と personalized_feed は同じ doc id で対応づけている。
class FirestoreSeeder {
  FirestoreSeeder(this._db);

  final FirebaseFirestore _db;

  /// すべてのサンプルを1バッチで投入する。
  ///
  /// [userId] は実行時の（匿名）サインインユーザー。個人配下のデータは
  /// この uid に紐づくため、アプリ起動中の表示と一致する。
  Future<void> seedAll(String userId) async {
    final batch = _db.batch();

    for (final s in _seeds) {
      batch.set(_db.collection('news_pool').doc(s.id), s.news.toJson());
      batch.set(
        _db
            .collection('users')
            .doc(userId)
            .collection('personalized_feed')
            .doc(s.id),
        s.feed.toJson(),
      );
    }

    batch.set(
      _db
          .collection('users')
          .doc(userId)
          .collection('interest_profile')
          .doc('current'),
      _interestProfile.toJson(),
    );

    await batch.commit();
  }
}

final firestoreSeederProvider = Provider<FirestoreSeeder>(
  (ref) => FirestoreSeeder(ref.watch(firestoreProvider)),
);

// ----- サンプルデータ定義 -----

/// news_pool と personalized_feed を doc id で結びつける1件分。
class _Seed {
  const _Seed({required this.id, required this.news, required this.feed});
  final String id;
  final NewsPool news;
  final PersonalizedFeedItem feed;
}

final List<_Seed> _seeds = [
  _Seed(
    id: 'news_eco_stadium',
    news: NewsPool(
      originalTitle: 'Global Environmental Regulations Strengthened',
      publishedAt: DateTime.parse('2026-06-16T00:00:00Z'),
      parentSummary: '・各国が炭素排出の新しい規制を導入\n'
          '・スタジアム等の大型施設も対象\n'
          '・子ども世代への影響を見据えた長期目標',
      childBodyWithRuby: '〔世界｜せかい〕の〔環境｜かんきょう〕を守るため、'
          '〔大｜おお〕きなサッカー〔場｜じょう〕も〔工夫｜くふう〕をはじめたよ。'
          '〔太陽｜たいよう〕の〔光｜ひかり〕で〔電気｜でんき〕をつくるんだって。',
    ),
    feed: const PersonalizedFeedItem(
      newsId: 'news_eco_stadium',
      interestContext: 'Soccer',
      displayTitle: 'エコ・スタジアム？サッカーが気候変動とたたかう方法',
      displayTagline: 'きみの大すきなスポーツが地球を救えるかも？',
      thumbnailConfig: ThumbnailConfig(
        mode: ThumbnailMode.textOverlay,
        baseAsset: 'assets/images/categories/soccer.png',
      ),
    ),
  ),
  _Seed(
    id: 'news_space_food',
    news: NewsPool(
      originalTitle: 'Life Aboard the Space Station',
      publishedAt: DateTime.parse('2026-06-15T00:00:00Z'),
      parentSummary: '・宇宙飛行士の食事と無重力下の工夫\n'
          '・水分補給と栄養管理の最新事情',
      childBodyWithRuby: '〔宇宙｜うちゅう〕では〔体｜からだ〕がふわふわ〔浮｜う〕くよ。'
          'だから〔特別｜とくべつ〕なやり〔方｜かた〕でごはんを〔食｜た〕べるんだ。',
    ),
    feed: const PersonalizedFeedItem(
      newsId: 'news_space_food',
      interestContext: 'Space',
      displayTitle: '宇宙では何を食べるの？うちゅう飛行士のごはん大公開',
      displayTagline: '無重力でスープを飲むひみつのテクニック！',
      thumbnailConfig: ThumbnailConfig(
        mode: ThumbnailMode.textOverlay,
        baseAsset: 'assets/images/categories/space.png',
      ),
    ),
  ),
  _Seed(
    id: 'news_env_rule',
    news: NewsPool(
      originalTitle: 'Nations Agree on a Shared Future',
      publishedAt: DateTime.parse('2026-06-14T00:00:00Z'),
      parentSummary: '・国際的な合意形成のプロセス\n'
          '・次世代への影響を重視した長期的視点',
      childBodyWithRuby: 'たくさんの〔国｜くに〕が〔集｜あつ〕まって、'
          'みんなの〔未来｜みらい〕のための〔約束｜やくそく〕をしたよ。',
    ),
    feed: const PersonalizedFeedItem(
      newsId: 'news_env_rule',
      interestContext: 'Environment',
      displayTitle: '世界の環境を守る新しいルールができたよ',
      displayTagline: 'みんなの未来のために大人たちが決めたこと。',
      thumbnailConfig: ThumbnailConfig(
        mode: ThumbnailMode.textOverlay,
        baseAsset: 'assets/images/categories/environment.png',
      ),
    ),
  ),
];

final InterestProfile _interestProfile = InterestProfile(
  currentInterests: const {'soccer': 85, 'space': 40, 'environment': 65},
  aiAgentMetadata: AiAgentMetadata(
    lastEvaluationCycle: DateTime.parse('2026-06-16T12:00:00Z'),
    currentPromptVersion: 'v2.4_empathetic_sports_blend',
    agentNotes: '子どもはスポーツの比喩に強く反応。応用科学へ重みをシフト中。',
  ),
);
