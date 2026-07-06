// Quiz.fromMap のパーステスト。
//
// generateQuiz callable のレスポンスは Map<Object?, Object?> / List<Object?> と
// 緩い型で届く。想定外の型でも落ちず、正誤判定が正しいことを保証する。

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/features/common_view/data/quiz_service.dart';

void main() {
  group('Quiz.fromMap', () {
    test('正常なレスポンスをパースできる', () {
      final quiz = Quiz.fromMap(<Object?, Object?>{
        'question': '記事のテーマは何ですか？',
        'choices': <Object?>['環境', '宇宙', 'スポーツ', '料理'],
        'answerIndex': 0,
        'explanation': '本文で環境の話をしていたから。',
      });

      expect(quiz.question, '記事のテーマは何ですか？');
      expect(quiz.choices, hasLength(4));
      expect(quiz.choices.first, '環境');
      expect(quiz.answerIndex, 0);
      expect(quiz.isCorrect(0), isTrue);
      expect(quiz.isCorrect(1), isFalse);
    });

    test('answerIndex が文字列でも整数に変換される', () {
      final quiz = Quiz.fromMap(<Object?, Object?>{
        'question': 'Q',
        'choices': <Object?>['a', 'b', 'c', 'd'],
        'answerIndex': '2',
        'explanation': 'E',
      });

      expect(quiz.answerIndex, 2);
      expect(quiz.isCorrect(2), isTrue);
    });

    test('choices が非配列でも空リストになり例外を出さない', () {
      final quiz = Quiz.fromMap(<Object?, Object?>{
        'question': 'Q',
        'choices': null,
        'answerIndex': 0,
        'explanation': '',
      });

      expect(quiz.choices, isEmpty);
      expect(quiz.explanation, '');
    });

    test('欠落フィールドは既定値になる', () {
      final quiz = Quiz.fromMap(const <Object?, Object?>{});

      expect(quiz.question, '');
      expect(quiz.choices, isEmpty);
      expect(quiz.answerIndex, 0);
      expect(quiz.explanation, '');
    });
  });
}
