import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_providers.dart';

/// AI エージェント群（パーソナライズ・サムネ生成・興味自己学習）の
/// Cloud Functions 呼び出しサービス。
class AiAgentService {
  AiAgentService(this._functions);

  final FirebaseFunctions _functions;

  /// パーソナライズ AI + 興味検知 AI パイプラインを実行する。
  ///
  /// news_pool の全記事を子どもの interest_profile に合わせて書き換え、
  /// personalized_feed へ保存する。処理済み件数を返す。
  Future<int> personalizeArticles() async {
    final callable = _functions.httpsCallable(
      'personalizeArticles',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 300),
      ),
    );
    final result = await callable.call<Map<String, dynamic>>();
    return (result.data['count'] as num?)?.toInt() ?? 0;
  }

  /// サムネ生成 AI: Imagen 3 でサムネイルを生成し Storage に保存する。
  ///
  /// 生成した画像 URL を返す。失敗時は空文字を返す。
  Future<String> generateThumbnail({
    required String newsId,
    required String title,
    required String tagline,
    required String category,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'generateThumbnail',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 120),
        ),
      );
      final result = await callable.call<Map<String, dynamic>>({
        'newsId': newsId,
        'title': title,
        'tagline': tagline,
        'category': category,
      });
      return result.data['imageUrl'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  /// 興味検知 AI 自己学習: 閲覧データで interest_profile を Gemini が更新する。
  ///
  /// Fire-and-forget でよい（失敗してもフィード表示に影響しない）。
  Future<void> updateInterestModel({
    required String newsId,
    required int viewDurationSeconds,
  }) async {
    try {
      final callable = _functions.httpsCallable('updateInterestModel');
      await callable.call<void>({
        'newsId': newsId,
        'viewDurationSeconds': viewDurationSeconds,
      });
    } catch (_) {
      // フォールバックは Cloud Function 側で実施済み。エラーは無視。
    }
  }
}

final aiAgentServiceProvider = Provider<AiAgentService>(
  (ref) => AiAgentService(ref.watch(functionsProvider)),
);
