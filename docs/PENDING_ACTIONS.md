# 保留中アクション（要ユーザー操作・要判断）

> 自律作業中に「私（Claude）の許可では実行できない／勝手に進めるべきでない」と判断したものを
> ここに記録する。コード側で完結できたものは各コミットに含めている。
> 最終更新: 2026-07-04

## 🔴 要デプロイ（コマンド実行許可が必要）

| # | 対象 | 内容 | コマンド |
|---|---|---|---|
| ~~D1~~ | `personalizeArticles` | ~~Phase③ 再生成バグ修正（`44644f9`）~~ → **2026-07-04 デプロイ済み**。 | ✅ 完了 |
| **D2** | `refreshNewsPool` / `sendParentDigest`（新規）/ `updateInterestModel` / `fetchNews` | **P3 送信側**（commit `66af1fa`）。通知①新着（refreshNewsPool 内）・通知②日次ダイジェスト（新スケジュール関数 sendParentDigest 18時JST）・利用刻印（updateInterestModel）。**未デプロイ**。 | `firebase deploy --only functions` |

> `sendParentDigest` は**新規のスケジュール関数**なので `functions:sendParentDigest` 単体でも可だが、
> 既存関数の変更（refreshNewsPool/updateInterestModel/fetchNews）も含むため `--only functions` 一括が確実。

## 🟡 要判断（機能追加・プロダクト決定）

autonomous には進めず、方針確認が必要なもの。

| # | 箇所 | 内容 |
|---|---|---|
| P1 | `lib/features/parent_dashboard/application/parent_dashboard_provider.dart:57` | `talkPrompts`（親子トークプロンプト）を Cloud Functions(Gemini) で生成する CF が未実装。現状はサンプル固定。 |
| P2 | `lib/core/firebase/firestore_seeder.dart:11` | Curated Global Batch / 動的ブレンドの CF が未実装のためシーダーで代替中。 |
| P3 | FCM Push 通知 | **クライアント＋送信側とも実装済み**（`8c1f1e5` / `66af1fa`）。残りはデプロイ(D2)・実機確認・iOS/Web。下記「P3 残タスク」参照。 |
| P4 | `lib/features/parent_dashboard/presentation/parent_dashboard_screen.dart:293` | 「お気に入り保存 / 後で話す」リスト追加が未実装（TODO）。 |
| P5 | パーソナライズ後タイトルのルビ振り直し | 書き換え後タイトルにルビが付かない。Gemini 側でルビ生成が必要。 |
| P6 | 品質ゲート閾値キャリブレーション | 採点実績 100〜200 件蓄積後に実施。手順は `docs/OPERATIONS.md §6`。データ待ち。 |
| P7 | `lib/core/ai/ai_agent_service.dart:31` `generateThumbnail()` / functions `generateThumbnail` onCall | クライアントメソッドは定義のみで**呼び出し無し**（サムネは ingest/personalize でサーバ生成する設計に移行済み）。デッドコード。削除するなら Dart メソッド + デプロイ済み onCall の両方を撤去（要デプロイ）。将来 UI から個別再生成する余地を残すなら保持。 |

## 📌 P3（FCM）残タスク

受信・送信ともに実装済み。実装した仕様は以下。

### 実装済みの通知（2種類）
- **通知①・子ども向け新着**（`refreshNewsPool` 内 → `notifyNewArticles`）: 毎朝6時JST の記事取得で
  **初めて追加された記事**があれば、トークンを持つ全端末へ「新しいニュースがとどいたよ」を送信。
  data `{ type:"feed" }` → `/child`。手動 `fetchNews` は在アプリ操作のため通知しない。
- **通知②・保護者向け日次**（新スケジュール関数 `sendParentDigest`・毎日18時JST）: その日に
  子どもがアプリを使った家庭（`users/{uid}.last_active_at` が本日）へ「今日のまなびレポート」を送信。
  data `{ type:"parent_digest" }` → `/parent`。「本日利用」は `updateInterestModel` 先頭で刻む。
- 共通: `sendToTokens` が multicast(最大500)送信＋失効トークンの自動掃除を行う。
  クライアント `_handleDeepLink` は `article` / `feed` / `parent_digest` の3契約に対応。

### ⚠️ 既知の制約（要判断・将来対応）
- **端末ロール区別なし**: 現状はファミリー単位の単一アカウント（uid）で、parent/child の
  端末を区別しない。よって**通知①も②も同一 uid の全端末に届く**（親の想定＝別スマホで受信、が
  現状は保証されない）。分けるには「端末ごとの role（child/parent）」を fcm_tokens に持たせ、
  送信時に絞り込む拡張が必要。要プロダクト判断。
- **静音時間帯**: 通知①は朝6時発火なので実害小。将来、夜間抑制や頻度制御を入れるかは未検討。

### 要デプロイ（D2）
`firebase deploy --only functions`。`sendParentDigest` は新規スケジュール関数のため
初回デプロイで Cloud Scheduler ジョブが作成される。

### 要許可・別対応
- **iOS**: APNs 証明書/キー設定が必要（現状 iOS 未構成）。
- **Web**: `firebase-messaging-sw.js`（Service Worker）+ VAPID 公開鍵が必要。現状は `kIsWeb` で
  スキップ。Web でも通知するなら別途対応。
- **実機確認**: Android 実機で3系統（foreground / background / 終了状態）の通知タップ→遷移を確認。
  通知②のダイジェストは実データ（当日利用ユーザー）が要るため、`last_active_at` を持つ状態で 18時JST を待つか、
  一時的に手動トリガ（Cloud Console の Scheduler「今すぐ実行」）で確認する。

## ✅ 自律完了済み（参考）

- Phase③ 実装（`5ad9a96`, デプロイ済み）
- Phase③ 再生成バグ修正（`44644f9`, 2026-07-04 デプロイ済み）
- P3 FCM クライアント実装（`8c1f1e5`）: 受信・トークン保存・ディープリンク遷移・Android 権限
- P3 FCM 送信側実装（`66af1fa`）: 子ども向け新着通知・保護者向け日次ダイジェスト（**未デプロイ D2**）
- QA ゲート全項目 PASS（analyze / test / design / tsc）
