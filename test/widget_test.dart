// 基本的なスモークテスト。
//
// MyApp は app.dart に定義され、GoRouter で初期画面に Child Feed を表示する。
// サンプルフィードの先頭記事が描画されることを確認する。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app.dart';

void main() {
  testWidgets('App builds and shows Child Feed first item', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // 初期ルート (/child) で先頭記事のアクションフックとバッジが表示される。
    expect(find.text('よんでみる'), findsOneWidget);
    expect(find.text('#Soccer'), findsOneWidget);
  });
}
