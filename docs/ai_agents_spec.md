# AI エージェント仕様書

ブランチ: `main`  
更新日: 2026-06-28

---

## 概要

子ども向けニュースフィードを「子どもの興味」に自動適応させる、3つの AI エージェントの実装仕様。

| エージェント | 役割 |
|---|---|
| **興味検知 AI** | 閲覧行動を学習し、記事ごとの興味スコアを算出・更新する |
| **パーソナライズ AI** | 興味スコアをもとに記事のタイトル・タグラインを書き換える |
| **サムネ生成 AI** | Imagen 3 でタイトル・概要に合ったサムネイル画像を生成する |

---

## システム全体フロー

```
┌─────────────────────────────────────────────────────┐
│                   初回セッション                      │
│                                                     │
│  interest_profile が空 → デフォルトスコアで初回表示  │
└─────────────────────────────────────────────────────┘
                         ↓ 記事閲覧
┌─────────────────────────────────────────────────────┐
│              テレメトリ収集（リアルタイム）            │
│                                                     │
│  閲覧記録 → recordView（Firestore に累積）           │
│           → updateInterestModel（DISA スコア更新）   │
└─────────────────────────────────────────────────────┘
                         ↓ 次回セッション（24時間経過後）
┌─────────────────────────────────────────────────────┐
│           パーソナライズパイプライン実行               │
│                                                     │
│  personalizeArticles（Cloud Function）               │
│    1. interest_profile 取得・DISA 減衰補正            │
│    2. news_pool から最新20記事取得                    │
│    3. Gemini で各記事を評価・書き換え（並列）          │
│    4. personalized_feed に保存                       │
│    5. Imagen 3 でサムネ生成（バックグラウンド）        │
└─────────────────────────────────────────────────────┘
```

---

## Firestore データモデル

### `/news_pool/{newsId}` — 全ユーザー共通の原記事

| フィールド | 型 | 説明 |
|---|---|---|
| `news_id` | string | ドキュメント ID（`fromJson` 時に手動注入） |
| `original_title` | string | 元記事タイトル |
| `published_at` | Timestamp | 公開日時 |
| `display_title` | string | Gemini 生成の子ども向けタイトル |
| `child_title_with_ruby` | string | ルビ付き子ども向けタイトル（`〔漢字｜よみ〕` 形式） |
| `display_tagline` | string | Gemini 生成のキャッチコピー |
| `child_body_with_ruby` | string | ルビ付き子ども向け本文 |
| `parent_summary` | string | 保護者向け要約 |
| `interest_context` | string | トピック分類（採点ゲートの Gemini が固定タクソノミーから選択。例: "科学", "スポーツ"） |
| `source_name` | string | ニュースソース名（例: "NHK ニュース"）。2026-07-02 に interest_context から分離 |
| `char_count` | int | ルビ除去後の実文字数（DISA の T_exp 計算用） |
| `thumbnail_config` | object | サムネイル設定（下記参照） |
| `quiz` | object | 記事内容の4択クイズ（`generateQuiz` が初回アクセス時に生成しキャッシュ）。未生成なら存在しない |

#### `thumbnail_config` の構造

| フィールド | 型 | 値 |
|---|---|---|
| `mode` | string | `"text_overlay"` または `"generated"` |
| `base_asset` | string | カテゴリイラストのパス（text_overlay 時） |
| `optional_generated_url` | string | Imagen 3 生成画像の Download URL（generated 時） |

**重要**: `fetchNews` / `refreshNewsPool` は常に `mode: "text_overlay"` で保存する。
GNews 由来の画像 URL は CORS NG のため使用しない。サムネは `personalizeArticles` 内で Imagen 3 が生成する。

---

### `/users/{userId}/interest_profile/current` — ユーザーの興味プロファイル

| フィールド | 型 | 説明 |
|---|---|---|
| `current_interests.{cat}` | number | DISA スコア（指数減衰 + α×E(i) 加算） |
| `genuine_engagement_counts.{cat}` | int | genuine engagement 回数 N_k（フェーズ判定用） |
| `last_score_updated_at.{cat}` | Timestamp | 最終スコア更新日時（次回減衰計算の基準） |
| `ai_agent_metadata.last_evaluation_cycle` | Timestamp | 最終学習実行日時 |
| `ai_agent_metadata.current_prompt_version` | string | 使用プロンプトバージョン（現在 `v2.0_disa`） |
| `ai_agent_metadata.agent_notes` | string | Gemini が自律更新する興味傾向メモ |

---

### `/users/{userId}/personalized_feed/{newsId}` — パーソナライズ済みフィード

| フィールド | 型 | 説明 |
|---|---|---|
| `news_id` | string | 記事 ID |
| `interest_context` | string | カテゴリ |
| `display_title` | string | パーソナライズ後のタイトル |
| `display_tagline` | string | パーソナライズ後のタグライン |
| `thumbnail_config` | object | サムネイル設定（Imagen 3 生成後は `mode: "generated"`） |
| `interest_score` | int | Gemini が算出した興味スコア（0-100） |
| `personalized_at` | Timestamp | パーソナライズ実行日時（24時間チェック用） |
| `is_viewed` | bool | 閲覧済みフラグ（テレメトリ） |
| `view_duration_seconds` | int | 累積閲覧秒数（テレメトリ） |

---

## Cloud Functions 仕様

### SDK

| 項目 | 値 |
|---|---|
| パッケージ | `@google/genai ^2.10.0` |
| クラス | `GoogleGenAI` |
| 初期化 | `new GoogleGenAI({ vertexai: true, project, location })` |
| 呼び出し | `ai.models.generateContent({ model, contents, config })` |
| テキスト取得 | `result.text` |

> **注意**: 旧 `@google-cloud/vertexai` は 2026-06-24 に削除済み。`@google/genai` に移行済み。

---

### `personalizeArticles`

**概要**: 興味検知 AI + パーソナライズ AI + サムネ生成 AI の統合パイプライン

| 項目 | 値 |
|---|---|
| トリガー | `onCall`（Flutter から呼び出し） |
| 認証 | Firebase Auth 必須 |
| リージョン | `asia-northeast1` |
| タイムアウト | 300 秒 |
| メモリ | 512 MiB |

**レスポンス**: `{ "count": 20 }`

**処理フロー**:

1. `interest_profile/current` を取得し、DISA 減衰補正を適用して実効スコアを算出
2. 上位5カテゴリの要約文字列を生成（`personalizeOneArticle` に渡す）
3. `news_pool` から `published_at` 降順で最新20件を取得
4. 全記事に対して Gemini 呼び出し（`Promise.allSettled` で並列実行）
   - `interest_score`（0-100）を算出
   - 子どもの興味に合わせたタイトル・タグラインを生成
5. `personalized_feed` に `merge: true` で保存（テレメトリ値は保持）
6. **バックグラウンドサムネ生成**（`batch.commit()` 後）:
   - `needsThumbnail()` でスキップ判定（`mode: "generated"` かつ Firebase Storage URL なら再生成しない）
   - メタデータサーバーからアクセストークンを1回取得
   - 対象記事を並列で `generateOneThumbnail()` に渡す
   - `news_pool` と `personalized_feed` の両方を更新

**`needsThumbnail` ロジック**:
```typescript
const needsThumbnail = (config): boolean => {
  if (config.mode !== "generated") return true;
  // firebasestorage.googleapis.com/v0/... = 正しい形式 → スキップ
  // storage.googleapis.com/... = 旧 GCS 直 URL（CORS NG）→ 再生成
  return !config.optional_generated_url.startsWith("https://firebasestorage.googleapis.com");
};
```

**フォールバック**: Gemini 失敗時は元記事のタイトル・タグラインを使用し `interest_score: 50` を設定

---

### `generateThumbnail`

**概要**: サムネ生成 AI（単体呼び出し用）

| 項目 | 値 |
|---|---|
| トリガー | `onCall` |
| タイムアウト | 120 秒 |
| メモリ | 1 GiB |
| 画像モデル | `imagen-3.0-fast-generate-001`（Vertex AI REST API, `us-central1`） |

内部ヘルパー `generateOneThumbnail()` を共有。

---

### `generateOneThumbnail()` — 内部ヘルパー

**処理フロー**:

1. **Gemini でビジュアルプロンプトを英語生成**（Imagen は英語プロンプトの方が品質が高いため）
   ```
   Article title: {title}
   Article summary: {tagline}
   → describe ONE specific scene, bright colorful cartoon for kids, no text, 16:9
   ```
2. 生成したプロンプトで Imagen 3 REST API を呼び出し（16:9）
3. Base64 → Buffer に変換
4. Firebase Storage `thumbnails/{newsId}.jpg` に保存
   - `firebaseStorageDownloadTokens: randomUUID()` をメタデータに埋め込む
   - これにより Storage セキュリティルールに依存しない Download URL が発行される
5. Download URL 形式で返す:
   ```
   https://firebasestorage.googleapis.com/v0/b/{bucket}/o/thumbnails%2F{newsId}.jpg?alt=media&token={uuid}
   ```

> **CORS 対応**: `storage.googleapis.com` 直 URL は Flutter Web (CanvasKit) で CORS ブロックされる。
> `firebasestorage.googleapis.com/v0/...` URL を使い、GCS バケットに `gsutil cors set` で CORS 設定を適用する。

---

### `generateQuiz`

**概要**: 記事の内容理解を確かめる4択クイズ生成 AI（Common View「いっしょに」の記事詳細で出題）

| 項目 | 値 |
|---|---|
| トリガー | `onCall`（記事詳細を開いた時に Flutter から呼び出し） |
| 認証 | Firebase Auth 必須 |
| リージョン | `asia-northeast1` |
| タイムアウト | 60 秒 |
| メモリ | 256 MiB |

**リクエスト**: `{ "newsId": "<news_pool の doc id>" }`
**レスポンス**: `{ "quiz": { question, choices[4], answerIndex(0-3), explanation } }`

**処理フロー**:

1. `news_pool/{newsId}` を取得
2. `quiz` フィールドがあり妥当（choices が4つ・answerIndex が 0-3）ならそれを返す（**キャッシュヒット**）
3. 無ければ `child_body_with_ruby`（子どもが読む本文）から Gemini で1問生成
   - 本文に書かれた事実だけを問う（本文に無い知識・推測は問わない）
   - 選択肢4つ・正解1つ、question/choices/explanation にルビ markup を付与
   - `temperature: 0.4` / `responseMimeType: application/json`
4. 妥当性検証（`normalizeQuiz`）を通ったクイズだけ `news_pool/{newsId}.quiz` に `merge: true` で保存し返す

**設計意図（コスト）**: 「開かれた記事だけ・1回だけ」Gemini を呼ぶ遅延生成＋キャッシュ。既存記事にも即対応でき、閲覧されない記事にはコストを払わない。生成失敗・不正出力時は保存せず `HttpsError` を返す（未検証クイズをキャッシュしない）。

**Flutter 側**: `features/common_view/data/quiz_service.dart`（`Quiz` モデル + `QuizService` + `quizProvider` family）。記事詳細（`article_detail_screen.dart`）の本文下に `_QuizSection` を表示。回答すると即時に正誤を色分け（正解=success/誤答=error）し、解説を表示する。

---

### `updateInterestModel`

**概要**: 興味検知 AI の自己学習ループ（DISA アルゴリズム実装）

| 項目 | 値 |
|---|---|
| トリガー | `onCall`（閲覧記録後に fire-and-forget） |
| タイムアウト | 60 秒 |
| メモリ | 256 MiB |

**処理フロー**:

1. 早期バウンス除外: `viewDurationSeconds < 9` は Firestore 読み取り前に return
2. `news_pool/{newsId}` と `interest_profile/current` を並列取得
3. DISA Step 1: `char_count` から動的 `T_exp` を計算し E(i) を算出
4. E(i) = 0 なら return（記事の長さ考慮後のバウンス）
5. DISA Step 2-4: フェーズ推定 → 減衰計算 → スコア更新
6. Firestore に `current_interests`・`genuine_engagement_counts`・`last_score_updated_at` を更新
7. Gemini で `agent_notes`（定性メモ）を非同期更新（スコアには関与しない）

---

## Flutter 実装

### フィードアーキテクチャ（child_feed）

**news_pool を常に正とし、personalized_feed をオーバーレイする設計**。

```
build() 処理フロー:
  1. news_pool から全記事取得（common と同じソース・同じ順序）
       ↓ 空なら
  サンプルデータ（Firebase 未初期化 / オフライン時）

  2. personalized_feed を取得し、newsId をキーに title/tagline/thumbnail を上書き

  3. バックグラウンドで _schedulePersonalization() を起動（UIをブロックしない）
      ├─ needsPersonalization() が false → 何もしない
      └─ true → personalizeArticles() 実行 → 完了後に state を再フェッチ・更新
```

旧アーキテクチャ（`personalized_feed` 優先）から変更した理由:
- 新規ユーザーや personalized_feed が空のとき記事がゼロになる問題を解消
- child と common で同じ記事・同じ順序を保証する

### `_openInCommon()` — newsId ベースのナビゲーション

```dart
final idx = commonArticles.indexWhere((a) => a.newsId == item.newsId);
ref.read(selectedArticleIndexProvider.notifier).state = idx >= 0 ? idx : 0;
```

インデックスベースの参照をやめ、newsId で照合することで child/common 間のズレを解消。

### `NewsPool.newsId` フィールド

```dart
@JsonKey(name: 'news_id') @Default('') String newsId,
```

Firestore のドキュメント ID は JSON に含まれないため、リポジトリ側で手動注入する:

```dart
// news_repository.dart
data['news_id'] = d.id;
return NewsPool.fromJson(data);
```

### `feed_repository.dart` — displayTitle の優先順

```dart
displayTitle: pool.childTitleWithRuby.isNotEmpty
    ? pool.childTitleWithRuby        // ルビ付きタイトル（最優先）
    : (pool.displayTitle.isNotEmpty
        ? pool.displayTitle           // Gemini 生成タイトル
        : pool.originalTitle),        // 元記事タイトル（フォールバック）
```

---

## Firebase Storage 設定

### セキュリティルール

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /thumbnails/{imageId} {
      allow read: if true;   // サムネは公開読み取り
    }
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### CORS 設定（gsutil）

Flutter Web (CanvasKit) からの `NetworkImage` 読み込みに必要。

```sh
cat > cors.json << 'EOF'
[{"origin": ["*"], "method": ["GET"], "maxAgeSeconds": 3600}]
EOF
gsutil cors set cors.json gs://ai-discovery-app-b3a9d.firebasestorage.app
```

---

## 興味スコアリング — DISA アルゴリズム

論文: Hidi & Renninger (2006), Settles & Meeder / Duolingo (2016), Ardagelou & Arampatzis (2017), Wu et al. (2021)

### Step 1: エンゲージメント値 E(i) の算出

```
T_exp = (char_count / 260字/分) × 60秒      ← 記事ごとに動的計算
t_norm = viewDurationSeconds / T_exp

E(i) = 0                                    (t_norm < 0.2: 確実なバウンス)
E(i) = log(1 + t_norm) / log(1 + 1.2)     (0.2 ≤ t_norm ≤ 1.5: 正常読解)
E(i) = 0.3                                  (t_norm > 1.5: 放置・読解困難の可能性)
```

### Step 2: Hidi-Renninger 興味フェーズ

| フェーズ | 条件 | 半減期 |
|---|---|---|
| Phase 1 (TSI) | N_k < 3 | 1日 |
| Phase 2 (MSI) | 3 ≤ N_k < 7 | 3日 |
| Phase 3 (EII) | N_k ≥ 7 | 14日 |

### Step 3 & 4: スコア更新式

```
S(t_new) = S(t_prev) × e^(−λ × Δdays) + α × E(i)
λ = ln(2) / 半減期
α = 10
```

### Gemini の役割

スコア計算は決定論的な式のみ。Gemini は `agent_notes`（定性メモ）の更新のみに使用する。

---

## Gemini モデル設定

| 設定 | 値 |
|---|---|
| パッケージ | `@google/genai ^2.10.0` |
| モデル | `gemini-2.5-flash` |
| Vertex AI リージョン | `us-central1` |
| `temperature` | `0.7`（サムネプロンプト生成時は `0.8`） |
| `responseMimeType` | `application/json`（Imagen プロンプト生成時を除く） |

---

## セキュリティ

- 全 Cloud Functions は Firebase Auth 認証必須（`uid` 未取得時は `unauthenticated` エラー）
- サムネ画像は Download Token 付き URL で配信（Storage ルール非依存、有効期限なし）
- `personalized_feed` は Firestore ルールにより本人のみ読み書き可
- `news_pool` は全ユーザー読み取り可・書き込み不可（Cloud Functions 経由のみ）

---

## 既知の制約・今後の課題

| 項目 | 現状 | 今後 |
|---|---|---|
| `interest_context` | ✅ 採点ゲート（`scoreArticle`）が固定タクソノミー12分類（科学/宇宙/テクノロジー/自然・環境/動物/スポーツ/食べ物/音楽・アート/経済・お金/国際・世界/文化・歴史/社会・くらし）でトピック分類（2026-07-02） | 既存記事は再取得時に上書き。旧ソース名カテゴリの interest_profile スコアは DISA 減衰で自然消滅 |
| サムネ生成コスト | ✅ `interest_score < 40`（`THUMBNAIL_MIN_INTEREST_SCORE`）の記事は Imagen をスキップ（2026-07-02） | 閾値はコスト実績を見て調整 |
| `child_title_with_ruby` | パーソナライズ後にルビが更新されない | personalizeOneArticle 側でルビ振り直しを追加 |
| 興味スコア初期値 | 空（新規ユーザーは書き換えなし） | オンボーディングで初期カテゴリを選択させる |
| パーソナライズ更新頻度 | 24時間チェック ✅ | — |
