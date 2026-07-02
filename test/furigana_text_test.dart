// FuriganaText の 〔漢字｜よみ〕 markup 解析テスト。
//
// Gemini が生成するルビ markup は形式が揺れることがあるため、
// 「漢字にはルビが付く」「かなのみはルビなし」「壊れた markup でも落ちない」を保証する。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/shared/widgets/furigana_text.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

/// FuriganaText 直下の RichText が描画する平文（WidgetSpan は ￼ になる）。
String _plainText(WidgetTester tester) {
  final rich = tester.widget<RichText>(
    find
        .descendant(
          of: find.byType(FuriganaText),
          matching: find.byType(RichText),
        )
        .first,
  );
  return rich.text.toPlainText();
}

void main() {
  testWidgets('漢字の markup は base と読みが両方描画される', (tester) async {
    await tester.pumpWidget(_wrap(const FuriganaText('〔環境｜かんきょう〕を守るルール')));

    // ルビ部分は独立した Text ウィジェットとして描画される
    expect(find.text('環境'), findsOneWidget);
    expect(find.text('かんきょう'), findsOneWidget);
    // markup の外側の平文はそのまま残る
    expect(_plainText(tester), contains('を守るルール'));
  });

  testWidgets('複数の markup をすべて解析する', (tester) async {
    await tester.pumpWidget(
      _wrap(const FuriganaText('〔世界｜せかい〕の〔環境｜かんきょう〕')),
    );

    expect(find.text('世界'), findsOneWidget);
    expect(find.text('せかい'), findsOneWidget);
    expect(find.text('環境'), findsOneWidget);
    expect(find.text('かんきょう'), findsOneWidget);
  });

  testWidgets('かな・カタカナのみの base はルビを付けない', (tester) async {
    await tester.pumpWidget(_wrap(const FuriganaText('〔リンゴ｜りんご〕はおいしい')));

    // ルビ用の独立 Text は生成されず、平文に展開される
    expect(find.text('リンゴ'), findsNothing);
    expect(find.text('りんご'), findsNothing);
    expect(_plainText(tester), 'リンゴはおいしい');
  });

  testWidgets('markup なしの平文はそのまま表示される', (tester) async {
    await tester.pumpWidget(_wrap(const FuriganaText('ふつうのテキスト')));

    expect(_plainText(tester), 'ふつうのテキスト');
  });

  testWidgets('閉じ括弧のない壊れた markup でも例外を出さない', (tester) async {
    await tester.pumpWidget(_wrap(const FuriganaText('〔環境｜かんきょうを守る')));

    // 解析できない部分は平文として残る（クラッシュしないことが重要）
    expect(tester.takeException(), isNull);
    expect(_plainText(tester), '〔環境｜かんきょうを守る');
  });

  testWidgets('空文字でも例外を出さない', (tester) async {
    await tester.pumpWidget(_wrap(const FuriganaText('')));

    expect(tester.takeException(), isNull);
  });
}
