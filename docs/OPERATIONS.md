# 運用ランブック（OPERATIONS）

> 作成: 2026-07-02 ／ 対象: AI Discovery Learning App の開発・運用者
> 関連: [`ARCHITECTURE.md`](ARCHITECTURE.md) ・ [`ai_agents_spec.md`](ai_agents_spec.md) ・ [`CONTENT_QUALITY_GATE.md`](CONTENT_QUALITY_GATE.md)

このアプリの「動かし続けるための知識」を1か所に集約する。**課金・削除・デプロイなど不可逆な操作は、実行前にこのランブックの該当チェックリストを必ず通す。**

---

## 1. システム状態 早見表

| 確認したいこと | 場所 |
|---|---|
| Cloud Functions ログ | `firebase functions:log` または GCP コンソール → Cloud Functions |
| Cloud Scheduler 状態 | https://console.cloud.google.com/cloudscheduler?project=ai-discovery-app-b3a9d |
| Firestore データ | Firebase コンソール → Firestore（`news_pool` / `rejected_articles` / `users`） |
| 請求額 | GCP コンソール → お支払い（Blaze プラン） |
| GNews 残クォータ | https://gnews.io ダッシュボード（無料 100 req/日） |

**現在の運用モード（2026-07-02 時点）:** Cloud Scheduler `refreshNewsPool` は**一時停止中**（開発中の GNews 枠節約）。ニュース取得はアプリ内ドロワー「ニュース取得 (GNews)」の手動トリガーのみ。

---

## 2. 定期チェックリスト

### 開発セッション開始時
- [ ] `git pull` して最新化
- [ ] `/qa` Skill を実行（analyze / test / design token / tsc の4点）
- [ ] アプリ起動後、**「サンプルきじを ひょうじちゅう」バナーが出ていないか**確認
      （出ていたら Firebase 接続か Firestore データに問題がある → §5-3）

### 週次（本番運用を始めたら）
- [ ] `rejected_articles` を確認: 誤除外（良記事が safety NG 扱い）がないか
- [ ] `quality_review.scores` の分布を確認（§6 閾値キャリブレーション）
- [ ] GCP 請求額を確認（前週比で急増していないか → §3）
- [ ] Functions ログのエラー率を確認（`scoreArticle failed` / `thumbnail generation failed` の頻度）

---

## 3. コスト管理

### 呼び出し1回あたりの AI 使用量

| 操作 | Gemini 呼び出し | Imagen 呼び出し |
|---|---|---|
| `fetchNews` / `refreshNewsPool`（記事10件） | 採点10 + 変換≤10 = **≤20回** | 0 |
| `personalizeArticles`（記事20件） | 書き換え20 + サムネプロンプト≤20 = **≤40回** | **≤20回**（`interest_score < 40` はスキップ） |
| `updateInterestModel`（閲覧1回） | agent_notes 1回 | 0 |
| `generateQuiz`（記事詳細を開く） | **記事ごとに初回のみ1回**（2回目以降はキャッシュで0） | 0 |

### コストを増やす操作（実行前に立ち止まる）
- **Scheduler の再開** → 毎日 GNews 10 req + Gemini ≤20回が自動で走る
- **`personalizeArticles` の多用** → Imagen が最も高価。24時間チェックが効いているか確認
- **ユーザー数の増加** → `personalized_feed` と Imagen はユーザー数に比例

### 節約設定（実装済み）
- サムネ生成は `interest_score >= 40` の記事のみ（`THUMBNAIL_MIN_INTEREST_SCORE`）
- 生成済みサムネ（`firebasestorage.googleapis.com` URL）は再生成しない（冪等）
- 採点ゲートで落ちた記事には変換コストを払わない

---

## 4. デプロイ SOP（Cloud Functions）

**デプロイは本番に即反映される。以下を順番に。**

### 事前チェック
- [ ] `/qa` Skill が PASS（特に `npx tsc --noEmit`）
- [ ] スキーマを変えた場合: Dart モデル（`lib/shared/models/`）が新旧両方のデータを読めるか
      （フィールド追加はデフォルト値付きなら安全。削除・リネームは要注意）
- [ ] docs（`ARCHITECTURE.md` / `ai_agents_spec.md`）を変更に合わせて更新済み
- [ ] 秘密情報（API キー等）がコードに入っていない

### 実行
```sh
cd functions
npm run build          # tsc でビルド確認
firebase deploy --only functions
```

### 事後確認
- [ ] アプリからドロワー「ニュース取得 (GNews)」→「N 件取得しました」が出る
- [ ] Firebase コンソールで `news_pool` の新ドキュメントに期待どおりのフィールドがある
- [ ] `firebase functions:log` にエラーがない

### ロールバック
Functions に自動ロールバックはない。**直前のコミットに戻して再デプロイ**が最速:
```sh
git log --oneline functions/   # 戻したいコミットを確認
git checkout <commit> -- functions/src
cd functions && npm run build && firebase deploy --only functions
```

---

## 5. インシデント対応プレイブック

### 5-1. フィードに新しい記事が入らない
1. GNews クォータ切れ？ → gnews.io ダッシュボード確認（100 req/日）
2. 採点ゲートが全落とし？ → `firebase functions:log` で `quality gate dropped N/N` を確認。
   Gemini 障害時は **fail-closed で全記事除外される仕様**（安全側）。`rejected_articles` の
   `rejected_reason: "scoring_failed"` が並んでいたら Gemini/Vertex 側の障害を疑う
3. Scheduler 停止中？ → 仕様どおり（手動取得で代替）。§1 の早見表参照

### 5-2. サムネイルが表示されない（グラデーション背景のまま）
1. `interest_score < 40` のスキップ対象 → 正常動作（閲覧されればスコアが上がり次回生成）
2. URL 形式を確認: `firebasestorage.googleapis.com/v0/...?token=...` が正。
   `storage.googleapis.com/...` 直 URL は Flutter Web で CORS NG（次回 personalize で自動再生成）
3. CORS 設定が消えた場合: `gsutil cors set cors.json gs://ai-discovery-app-b3a9d.firebasestorage.app`

### 5-3. 「サンプルきじを ひょうじちゅう」バナーが本番で出る
サンプルフォールバックは **Firebase 未初期化 / news_pool 空 / 取得エラー** の3経路。
1. ログイン状態を確認（未認証だと Firestore ルールで読めない）
2. Firebase コンソールで `news_pool` にドキュメントがあるか確認 → 無ければ手動「ニュース取得」
3. ブラウザ/デバイスのネットワークを確認

### 5-4. 記事のカテゴリ（#バッジ）がおかしい
- 2026-07-02 以降の記事: 採点ゲートの `topic` 分類（12分類）。`quality_review.topic` を確認
- それ以前の記事: ソース名（"NHK ニュース"等）が残っている。再取得（同 URL は同 ID で上書き）
  すれば新分類になる。**interest_profile に残る旧カテゴリスコアは DISA 減衰で自然消滅する**ので
  手動削除は不要

---

## 6. 品質ゲート閾値キャリブレーション（自動除外への移行手順）

品質3軸（①教育的価値 ②思考フック ③信頼性）は現在「記録のみ」。自動除外に移行する条件と手順:

1. **採点実績 100〜200 件**たまるまで待つ（毎日自動取得なら2〜3週間、手動連打なら数日）
2. Firebase コンソールで `news_pool` の `quality_review.scores` と `rejected_articles` を眺め、
   「これは載せたくない」と感じた記事のスコアをメモする
3. 軸ごとに閾値案を決める（例: `educationalValue <= 2 を除外`。②は null 許容のまま）
4. `functions/src/index.ts` の `ingestArticles` の振り分け条件に品質閾値を追加してデプロイ
5. 1週間は `rejected_articles` を毎日確認し、誤除外があれば閾値を緩める

---

## 7. 秘密情報・安全ルール

- API キー・サービスアカウント鍵・`.env` は**コミット禁止**（`.gitignore` 済み）。
  GNews キーは Secret Manager（`firebase functions:secrets:set GNEWS_API_KEY`）のみ
- `rejected_articles` はクライアント非公開（firestore.rules で deny）を維持する
- 子どもに見せる前のデータを緩める変更（安全ゲートの無効化・fail-open 化）は**単独判断でやらない**
- Firestore の一括削除・ルール変更・課金プラン変更は実行前にバックアップと影響範囲を確認

---

## 8. 関連コマンド集

```sh
# QA 一括実行（Claude Code 内では /qa Skill）
flutter analyze && flutter test
bash scripts/design_check.sh --all
cd functions && npx tsc --noEmit

# モデル変更後のコード生成
dart run build_runner build --delete-conflicting-outputs

# Functions ログ
firebase functions:log

# Scheduler 一時停止/再開（gcloud）
gcloud scheduler jobs pause  firebase-schedule-refreshNewsPool-asia-northeast1 --project=ai-discovery-app-b3a9d
gcloud scheduler jobs resume firebase-schedule-refreshNewsPool-asia-northeast1 --project=ai-discovery-app-b3a9d
```
