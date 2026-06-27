# システム全体像

> 最終更新: 2026-06-21

## 概要

子ども向けAI学習発見アプリ。ニュース記事を Gemini で子ども向けに変換し、
TikTok風の縦スクロールフィードで提供する Flutter アプリ。

---

## 全体データフロー

```
【自動】毎朝6時 JST                    【手動】ドロワー「ニュース取得」
Cloud Scheduler                         アプリ内ボタン
    │                                       │
    ▼                                       ▼
refreshNewsPool (onSchedule)           fetchNews (onCall)
    │ news_pool のみ更新                    │ news_pool + personalized_feed 更新
    │                                       │
    └──────────────┬────────────────────────┘
                   │
                   ▼ GNews.io API (lang=ja, country=jp, max=10)
                   │ 生記事取得
                   │
                   ▼ Gemini (gemini-2.5-flash, us-central1)
                   │ 子ども向けに変換 (並列, 失敗時は生記事フォールバック)
                   │
                   ▼ Firestore WriteBatch
                   │
          ┌────────┴──────────────────┐
          ▼                           ▼
  /news_pool/{newsId}     /users/{uid}/personalized_feed/{newsId}
  (全ユーザー共通)         (呼び出しユーザーのみ / fetchNews のみ)
          │                           │
          └────────────┬──────────────┘
                       ▼
              Flutter アプリ (Riverpod)
              ├── ChildFeedScreen  (縦スクロール・TikTok風)
              ├── CommonView       (2カラム記事リーダー)
              └── ParentDashboard (保護者向けダイジェスト)
```

---

## Cloud Scheduler の停止について

**Scheduler を一時停止してもアプリのエラーは出ない。**

| 状態 | 影響 |
|---|---|
| Scheduler **動作中** | 毎朝6時に `news_pool` が自動更新される |
| Scheduler **一時停止中** | `news_pool` の自動更新が止まる。既存データはそのまま残る |
| Scheduler **停止中でも** | ドロワー「ニュース取得」を手動タップすれば更新可能 |

**一時停止・再開の方法:**
```
GCP コンソール → Cloud Scheduler
https://console.cloud.google.com/cloudscheduler?project=ai-discovery-app-b3a9d
→ refreshNewsPool の行 → ⋮ → 「一時停止」/「再開」
```

**注意:** GNews 無料枠は **100 req/日**。Scheduler を毎日動かすとほぼ全消費するため、
開発中は一時停止推奨。本番運用時に再開する。

---

## レイヤー詳細

### 1. Cloud Functions (`functions/src/index.ts`)

#### `fetchNews` — 手動トリガー (onCall)
- リージョン: `asia-northeast1` / timeout: 300s / memory: 512MiB
- 認証必須 (`request.auth?.uid` がなければ `unauthenticated` エラー)
- `news_pool` と呼び出しユーザーの `personalized_feed` を両方更新する

#### `refreshNewsPool` — 自動実行 (onSchedule)
- スケジュール: 毎朝6時 JST (`0 6 * * *`, Asia/Tokyo)
- `news_pool` **のみ**更新（`personalized_feed` は更新しない）
- ユーザーコンテキストが無いため特定ユーザーへの書き込みは行わない

#### `toChildFriendly(article)` — Gemini 変換
```
入力: GNewsArticle { title, description, content, url, image, publishedAt, source }

Gemini プロンプト (gemini-2.5-flash):
  - 役割: 小学生向けニュース編集者 / 対象: 6〜10歳
  - 出力 JSON (4キー):
      display_title       : 子ども向けタイトル (20文字以内)
      display_tagline     : 興味を引く一言 (30文字以内)
      child_body_with_ruby: 本文2〜4文 + 〔漢字｜よみ〕ルビ
      parent_summary      : 保護者向け箇条書き (・で始まる2〜3項目)

失敗時: rawFallback() → 生記事をそのままマッピング
```

- Vertex AI 認証: ADC (Cloud Functions 実行サービスアカウント) — API キー不要
- doc ID: `"news_" + sha1(url).slice(0, 16)` → 再取得時は冪等に上書き

---

### 2. Firestore スキーマ

#### `/news_pool/{newsId}` — 全ユーザー共通
| フィールド | 型 | 内容 |
|---|---|---|
| `original_title` | string | 元の記事タイトル |
| `published_at` | Timestamp | 記事の公開日時 |
| `child_body_with_ruby` | string | Gemini 生成の子ども向け本文 (ルビ付き) |
| `parent_summary` | string | Gemini 生成の保護者向け箇条書き |

書き込み: Cloud Functions (Admin SDK) のみ。クライアントからは読み取り専用。

#### `/users/{uid}/personalized_feed/{newsId}` — ユーザー別
| フィールド | 型 | 内容 |
|---|---|---|
| `news_id` | string | `news_pool` の参照キー |
| `interest_context` | string | 出典名 (例: "NHK ニュース") |
| `display_title` | string | Gemini 生成の子ども向けタイトル |
| `display_tagline` | string | Gemini 生成のキャッチコピー |
| `thumbnail_config` | map | `{ mode, base_asset, optional_generated_url }` |
| `is_viewed` | bool | 閲覧済みフラグ |
| `view_duration_seconds` | number | 滞在秒数 (累積) |

書き込み: Cloud Functions (Admin SDK) のみ。クライアントからは読み取り専用。

#### `/users/{uid}/interest_profile/current` — 興味プロファイル
| フィールド | 型 | 内容 |
|---|---|---|
| `current_interests` | map | `{ "カテゴリ名": 滞在秒数合計 }` |
| `ai_agent_metadata` | map | エージェント稼働情報 (将来用) |

書き込み: クライアントから直接更新可 (スワイプ時に `FieldValue.increment` で加算)。

**interest_profile 更新の仕組み:**
```
記事を3秒以上見てスワイプ
  → ChildFeedNotifier.recordView(newsId, durationSeconds)
  → FeedRepository.recordInterest(userId, interestContext, durationSeconds)
  → current_interests.{interestContext} += durationSeconds
```
3秒未満は誤スワイプとみなしてスコア加算しない。

---

### 3. Flutter アプリ層

#### データモデル (`lib/shared/models/`)
```
NewsPool               ← /news_pool/{id}
PersonalizedFeedItem   ← /personalized_feed/{id}
  └── ThumbnailConfig  ← thumbnail_config (ThumbnailMode enum)
InterestProfile        ← /interest_profile/current
  └── AiAgentMetadata
TimestampConverter     ← Firestore Timestamp ⇔ DateTime
```
> `build.yaml`: `explicit_to_json: true` 設定済み (ネストモデルのシリアライズに必要)

#### Riverpod プロバイダ構成
```
firebaseReadyProvider    bool              Firebase 初期化成否 — main.dart でオーバーライド
firestoreProvider        FirebaseFirestore
authProvider             FirebaseAuth
functionsProvider        FirebaseFunctions  (region: asia-northeast1)
authStateProvider        Stream<User?>
currentUserIdProvider    String            uid | "dev_local_user" (未認証時)

feedRepositoryProvider      FeedRepository      personalized_feed 読み書き + interest_profile 更新
newsFetchServiceProvider    NewsFetchService    fetchNews callable 呼び出し
parentDashboardRepositoryProvider  ParentDashboardRepository

childFeedProvider        AsyncNotifier<List<PersonalizedFeedItem>>
commonViewProvider       AsyncNotifier
parentDashboardProvider  AsyncNotifier
```

#### フォールバック戦略
Firebase 未初期化・データなし・エラー → **ハードコードされたサンプルデータで継続動作**
→ バックエンド未整備でも Flutter 側の開発・UI検証が可能

#### 画面構成 (GoRouter)
| パス | 画面 | 用途 |
|---|---|---|
| `/login` | LoginScreen | 起動時認証 (Google / ゲスト) |
| `/child` | ChildFeedScreen | タブレット縦・TikTok風フィード |
| `/common` | CommonViewScreen | タブレット横・2カラム記事リーダー |
| `/parent` | ParentDashboardScreen | スマホ縦・保護者ダイジェスト |

**ChildFeedScreen の実装ポイント:**
- `PageView.builder(scrollDirection: Axis.vertical)` で1記事=1ページ
- `_FastPageScrollPhysics`: 軽いスワイプで即スナップ (stiffness: 360, minFlingVelocity: 30)
- `_feedNotifier` を dispose 前にキャッシュ → 破棄後の `onPageChanged` でも安全に `recordView` を呼べる

#### ルビ表示 (FuriganaText)
```
〔漢字｜よみ〕 markup を解析して漢字の上に読みを重ねる
例: 〔環境｜かんきょう〕 → "環境" の上に小さく "かんきょう"
```

---

### 4. 認証フロー

```
アプリ起動
    │
    ├── Firebase 初期化成功?
    │       No  → firebaseReadyProvider = false
    │               → ログイン画面スキップ、サンプルデータで動作
    │       Yes → authStateProvider 購読開始
    │
    ├── ログイン済み? → /child へ
    └── 未ログイン   → /login へ
            ├── Google ログイン (firebase_auth signInWithProvider)
            └── ゲスト (anonymous signIn)
```

---

### 5. 手動トリガー (AppDrawer)

```
AppDrawer (左ドロワー)
    ├── サンプルデータ投入 (dev)  → firestoreSeeder.seedAll(uid)
    └── ニュース取得 (GNews)      → newsFetchService.fetchNews()
                                       → Cloud Functions fetchNews (onCall)
                                       → 完了後に3画面プロバイダを invalidate
```

**実装上の注意:** `Navigator.pop()` でドロワーが破棄された後も async 処理が続くため、
`ProviderScope.containerOf(context)` を pop 前に取得し `ref` の代わりに使う。

---

## インフラ構成

| リソース | 設定 |
|---|---|
| Firebase プロジェクト | `ai-discovery-app-b3a9d` |
| Cloud Functions リージョン | `asia-northeast1` (東京) |
| Cloud Functions ランタイム | Node.js 22 |
| Vertex AI リージョン | `us-central1` |
| Gemini モデル | `gemini-2.5-flash` |
| GNews API | `lang=ja, country=jp, max=10` (無料100req/日) |
| Secret Manager | `GNEWS_API_KEY` |
| Vertex AI 認証 | ADC (Cloud Functions 実行サービスアカウント) |
| Firestore ルール | `news_pool`: 読み取り専用 / `personalized_feed`: 読み取り専用 / `interest_profile`: 本人のみ読み書き |
| Cloud Scheduler | 現在**一時停止中** (開発中はGNews無料枠節約のため) |

---

## 未実装 / 次の候補

| 項目 | 概要 |
|---|---|
| 記事品質ゲート（採点AI） | GNews 取得記事を Gemini で4軸採点し、変換前にフィルタ。詳細は [`CONTENT_QUALITY_GATE.md`](CONTENT_QUALITY_GATE.md) |
| personalized_feed 個別配信 | `interest_profile` スコアを元に Gemini がフィードをユーザー別最適化 |
| Common View 記事リーダー | 「よんでみる」ボタンの遷移先・記事本文表示の実装 |
| Parent Dashboard 実データ | `interest_profile` の現スコアをグラフ表示 |
| FCM Push 通知 | 親子トークプロンプト・マイルストーン到達通知 |
| iOS 実機ビルド | Mac + Xcode で Team 署名 (GoogleService-Info.plist・URL スキームは設定済み) |
