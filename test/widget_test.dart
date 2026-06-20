// 基本的なスモークテスト。
//
// MyApp は app.dart に定義され、GoRouter で初期画面に Child Feed を表示する。
// ProviderScope で wrap して起動できることを確認する。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app.dart';

void main() {
  testWidgets('App builds and shows Child Feed placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // 初期ルート (/child) のプレースホルダが表示される。
    expect(find.text('Child Feed (TODO: Step 5)'), findsOneWidget);
  });
}
