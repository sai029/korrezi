import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';

/// 記事の内容理解クイズ（1問・4択）。
///
/// Cloud Functions `generateQuiz` の戻り値をパースしたもの。
/// 各テキストは `〔漢字｜よみ〕` ルビ markup を含みうる（FuriganaText が描画する）。
class Quiz {
  const Quiz({
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
  });

  final String question;
  final List<String> choices;
  final int answerIndex;
  final String explanation;

  bool isCorrect(int index) => index == answerIndex;

  /// callable のレスポンス（`Map<Object?, Object?>`）から生成する。
  /// 想定外の型でも落ちないよう緩く受ける。
  factory Quiz.fromMap(Map<Object?, Object?> map) {
    final choicesRaw = map['choices'];
    final choices = choicesRaw is List
        ? choicesRaw.map((e) => '$e').toList(growable: false)
        : const <String>[];
    final idx = map['answerIndex'];
    return Quiz(
      question: '${map['question'] ?? ''}',
      choices: choices,
      answerIndex: idx is int ? idx : (int.tryParse('$idx') ?? 0),
      explanation: '${map['explanation'] ?? ''}',
    );
  }
}

/// Cloud Functions `generateQuiz` を呼び出してクイズを取得する。
///
/// 関数側が news_pool/{newsId}.quiz にキャッシュするため、2回目以降は
/// Gemini を呼ばず保存済みを即返す。
class QuizService {
  QuizService(this._functions);

  final FirebaseFunctions _functions;

  Future<Quiz> fetchQuiz(String newsId) async {
    final callable = _functions.httpsCallable('generateQuiz');
    final result = await callable.call<Map<String, dynamic>>({'newsId': newsId});
    final quizRaw = result.data['quiz'];
    if (quizRaw is! Map) {
      throw StateError('クイズのレスポンスが不正です。');
    }
    return Quiz.fromMap(quizRaw);
  }
}

final quizServiceProvider = Provider<QuizService>(
  (ref) => QuizService(ref.watch(functionsProvider)),
);

/// 記事 ID ごとにクイズを取得する。family でキャッシュされ、同じ記事を
/// 開き直しても再取得しない（画面セッション内）。
final quizProvider = FutureProvider.family<Quiz, String>((ref, newsId) async {
  return ref.watch(quizServiceProvider).fetchQuiz(newsId);
});
