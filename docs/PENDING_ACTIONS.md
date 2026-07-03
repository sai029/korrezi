# 保留中アクション（要ユーザー操作・要判断）

> 自律作業中に「私（Claude）の許可では実行できない／勝手に進めるべきでない」と判断したものを
> ここに記録する。コード側で完結できたものは各コミットに含めている。
> 最終更新: 2026-07-03

## 🔴 要デプロイ（コマンド実行許可が必要）

| # | 対象 | 内容 | コマンド |
|---|---|---|---|
| D1 | `personalizeArticles` | **Phase③ の興味別サムネ再生成バグ修正**（commit `44644f9`）。再パーソナライズで専用サムネが共有画像に戻る不具合を修正済み。**未デプロイ**。 | `firebase deploy --only functions:personalizeArticles` |

> 注: Phase③ 本体（commit `5ad9a96`）は既にデプロイ済み。バグ修正 `44644f9` を上書きデプロイすれば最新になる。

## 🟡 要判断（機能追加・プロダクト決定）

autonomous には進めず、方針確認が必要なもの。

| # | 箇所 | 内容 |
|---|---|---|
| P1 | `lib/features/parent_dashboard/application/parent_dashboard_provider.dart:57` | `talkPrompts`（親子トークプロンプト）を Cloud Functions(Gemini) で生成する CF が未実装。現状はサンプル固定。 |
| P2 | `lib/core/firebase/firestore_seeder.dart:11` | Curated Global Batch / 動的ブレンドの CF が未実装のためシーダーで代替中。 |
| P3 | `lib/core/router/app_router.dart:22` | FCM Push 通知のディープリンク対応が未実装。 |
| P4 | `lib/features/parent_dashboard/presentation/parent_dashboard_screen.dart:293` | 「お気に入り保存 / 後で話す」リスト追加が未実装（TODO）。 |
| P5 | パーソナライズ後タイトルのルビ振り直し | 書き換え後タイトルにルビが付かない。Gemini 側でルビ生成が必要。 |
| P6 | 品質ゲート閾値キャリブレーション | 採点実績 100〜200 件蓄積後に実施。手順は `docs/OPERATIONS.md §6`。データ待ち。 |

## ✅ 自律完了済み（参考）

- Phase③ 実装（`5ad9a96`, デプロイ済み）
- Phase③ 再生成バグ修正（`44644f9`, **未デプロイ** → D1）
- QA ゲート全項目 PASS（analyze / test / design / tsc）
