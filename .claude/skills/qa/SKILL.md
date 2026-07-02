---
description: Run the full QA gate for flutter_application_1 — flutter analyze, flutter test, design-token check, and Cloud Functions TypeScript build — and report a pass/fail summary. Use before committing, after refactors, or when the user asks to "QA / 検証 / チェックして".
---

# QA Skill — flutter_application_1

コミット前・リファクタ後に回す品質ゲート。**4つのチェックを順に実行し、最後に必ずサマリー表を出す。**
途中で失敗しても止まらず、全チェックを実行してからまとめて報告する（修正の優先順位が付けられるように）。

## チェック一覧

### 1. 静的解析（Dart）

```bash
flutter analyze
```

- 期待: `No issues found!`
- 失敗時: エラー行を特定して修正 → 再実行。warning も残さない方針。

### 2. テスト（Dart）

```bash
flutter test
```

- 期待: `All tests passed!`
- 失敗時: 失敗テスト名と assertion を報告。**テストを弱めて通すのは禁止**
  （実装のバグかテストの期待値ずれかを先に切り分ける）。

### 3. デザイントークン違反（全 lib/ 走査）

```bash
bash scripts/design_check.sh --all
```

- 期待: 出力なし（exit 0）
- 失敗時: `lib/core/theme/tokens.dart` の AppColors / AppRadii / AppMotion に置き換える。
  例外にしたい行はその理由をユーザーに確認する（勝手に許容リストを作らない）。

### 4. Cloud Functions ビルド（TypeScript）

```bash
bash -c 'cd functions && npx tsc --noEmit'
```

- 期待: 出力なし（exit 0）
- `node_modules` が無い場合は先に `bash -c 'cd functions && npm ci'` を実行する。
- 失敗時: 型エラーを修正。**`any` へのキャストでの握りつぶしは禁止。**

## 最終レポート形式（必須）

```
## QA 結果

| チェック | 結果 | 備考 |
|---|---|---|
| flutter analyze | ✅ / ❌ | ... |
| flutter test | ✅ / ❌ | N passed |
| デザイントークン | ✅ / ❌ | 違反 N 件 |
| functions tsc | ✅ / ❌ | ... |

**総合判定: PASS / FAIL（コミット可否）**
```

## 注意

- QA は読み取り + ビルドのみで完結する。**デプロイ（firebase deploy）や Firestore への書き込みは行わない。**
- FAIL のままコミットを提案しない。修正 → 再実行で PASS にしてから。
- テスト追加が必要な変更（新ウィジェット・新ロジック）を検知したら、その旨をレポートに含める。
