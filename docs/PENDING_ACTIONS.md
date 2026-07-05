# 保留中アクション（要ユーザー操作・要判断）

> 自律作業中に「私（Claude）の許可では実行できない／勝手に進めるべきでない」と判断したものを
> ここに記録する。コード側で完結できたものは各コミットに含めている。
> 最終更新: 2026-07-03

## 🔴 要デプロイ（コマンド実行許可が必要）

| # | 対象 | 内容 | コマンド |
|---|---|---|---|
| ~~D1~~ | `personalizeArticles` | ~~Phase③ 再生成バグ修正（`44644f9`）~~ → **2026-07-04 デプロイ済み**。 | ✅ 完了 |

> 現在、未デプロイの関数変更はなし。P3 送信関数を実装したら再びここに追加する。

## 🟡 要判断（機能追加・プロダクト決定）

autonomous には進めず、方針確認が必要なもの。

| # | 箇所 | 内容 |
|---|---|---|
| P1 | `lib/features/parent_dashboard/application/parent_dashboard_provider.dart:57` | `talkPrompts`（親子トークプロンプト）を Cloud Functions(Gemini) で生成する CF が未実装。現状はサンプル固定。 |
| P2 | `lib/core/firebase/firestore_seeder.dart:11` | Curated Global Batch / 動的ブレンドの CF が未実装のためシーダーで代替中。 |
| P3 | FCM Push 通知 | **クライアント側は実装済み**（commit `8c1f1e5`）。残りは下記「P3 残タスク」参照。 |
| P4 | `lib/features/parent_dashboard/presentation/parent_dashboard_screen.dart:293` | 「お気に入り保存 / 後で話す」リスト追加が未実装（TODO）。 |
| P5 | パーソナライズ後タイトルのルビ振り直し | 書き換え後タイトルにルビが付かない。Gemini 側でルビ生成が必要。 |
| P6 | 品質ゲート閾値キャリブレーション | 採点実績 100〜200 件蓄積後に実施。手順は `docs/OPERATIONS.md §6`。データ待ち。 |
| P7 | `lib/core/ai/ai_agent_service.dart:31` `generateThumbnail()` / functions `generateThumbnail` onCall | クライアントメソッドは定義のみで**呼び出し無し**（サムネは ingest/personalize でサーバ生成する設計に移行済み）。デッドコード。削除するなら Dart メソッド + デプロイ済み onCall の両方を撤去（要デプロイ）。将来 UI から個別再生成する余地を残すなら保持。 |

## 📌 P3（FCM）残タスク

クライアント受信・ディープリンク遷移は実装済み（`lib/core/notifications/fcm_service.dart`）。
通知 data 契約は `{ "type": "article", "news_id": "<newsId>" }` → `/common/article/<id>` へ遷移。
トークンは `users/{uid}/fcm_tokens/{token}` に保存される。残りは以下。

### 要判断（送信側の設計 = プロダクト決定）
- **いつ通知するか**の契機を決める。候補: ①新着記事の ingest 完了時、②興味マイルストーン到達時
  （interest_profile 更新で閾値超え）、③保護者が「後で話す」に入れた記事のリマインド。
- 通知文面（タイトル/本文）と頻度・静音時間帯（子ども向けなので夜間抑制など）。

### 要実装＋要デプロイ（送信 Cloud Function）
送信の中身は決まれば小さい。`firebase-admin` の messaging で下記のように送る（トークンは上記パスから取得）:

```ts
import { getMessaging } from "firebase-admin/messaging";
// tokens: users/{uid}/fcm_tokens の doc id 配列
await getMessaging().sendEachForMulticast({
  tokens,
  notification: { title, body },
  data: { type: "article", news_id: newsId }, // ← クライアントのディープリンク契約
  android: { priority: "high" },
});
// 失効トークン（NotRegistered / invalid-argument）は該当 doc を削除してクリーンアップする。
```
- デプロイ: `firebase deploy --only functions:<新関数>`（送信契機を組み込んだ後）。

### 要許可・別対応
- **Firestore ルールのデプロイ**: `fcm_tokens` は既存ルールで許可済みだがコメント追記のみ変更。
  ルール自体の挙動は不変のため再デプロイ必須ではない（他のルール変更とまとめてで可）。
- **iOS**: APNs 証明書/キー設定が必要（現状 iOS 未構成）。
- **Web**: `firebase-messaging-sw.js`（Service Worker）+ VAPID 公開鍵が必要。現状は `kIsWeb` で
  スキップしている。Web でも通知するなら別途対応。
- **実機確認**: Android 実機で「通知タップ → 記事詳細へ遷移」を確認（foreground/background/終了状態の3系統）。

## ✅ 自律完了済み（参考）

- Phase③ 実装（`5ad9a96`, デプロイ済み）
- Phase③ 再生成バグ修正（`44644f9`, 2026-07-04 デプロイ済み）
- P3 FCM クライアント実装（`8c1f1e5`）: 受信・トークン保存・ディープリンク遷移・Android 権限
- QA ゲート全項目 PASS（analyze / test / design / tsc）
