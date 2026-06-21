# システム全体像

> 最終更新: 2026-06-21

## 概要

子ども向けAI学習発見アプリ。ニュース記事を Gemini で子ども向けに変換し、
TikTok風の縦スクロールフィードで提供する Flutter アプリ。

---

## 全体データフロー

```
GNews.io API
    │  日本語トップニュース (lang=ja, country=jp, max=10)
    ▼
Cloud Functions (fetchNews)          ← Firebase App Drawer からトリガー
    │  1. GNews から生記事を取得
    │  2. 各記事を Gemini (gemini-2.5-flash) で子ども向けに並列変換
    │     └─ 変換失敗時は生記事にフォールバック
    │  3. WriteBatch で Firestore へ書き込み
    ▼
Firestore
    ├── /news_pool/{newsId}                    共通記事プール
    └── /users/{uid}/personalized_feed/{newsId} ユーザー別フィード
    ▼
Flutter アプリ (Riverpod)
    ├── ChildFeedScreen (縦スクロール・TikTok風)
    ├── CommonView (2カラム記事リーダー)
    └── ParentDashboard (保護者向けダイジェスト)
```

---

## レイヤー詳細

### 1. データ取得層 — Cloud Functions (`functions/src/index.ts`)

**`fetchNews`** (v2 onCall, asia-northeast1, timeout 300s, memory 512MiB)

| ステップ | 処理 |
|---|---|
| 認証確認 | `request.auth?.uid` が無ければ `unauthenticated` エラー |
| GNews 取得 | `https://gnews.io/api/v4/top-headlines?lang=ja&country=jp&max=10` |
| Gemini 変換 | `Promise.all(articles.map(toChildFriendly))` で並列変換 |
| Firestore 書込 | WriteBatch で `news_pool` + `personalized_feed` を一括コミット |

**`toChildFriendly(article)`** — Gemini 変換関数

```
入力: GNewsArticle { title, description, content, url, image, publishedAt, source }

Gemini プロンプト:
  - 役割: 小学生向けニュース編集者
  - 対象: 6〜10歳
  - 出力: JSON (4キー固定)
    - display_title      : 子ども向けタイトル (20文字以内)
    - display_tagline    : 興味を引く一言 (30文字以内)
    - child_body_with_ruby: 本文2〜4文 + 〔漢字｜よみ〕ルビ
    - parent_summary     : 保護者向け箇条書き (・で始まる2〜3項目)

出力: ChildFriendly { displayTitle, displayTagline, childBodyWithRuby, parentSummary }
失敗時: rawFallback() → 生記事をそのままマッピング
```

**Vertex AI 設定**
- モデル: `gemini-2.5-flash` (us-central1)
- 認証: ADC (Application Default Credentials) — API キー不要
- クライアントはインスタンス内でキャッシュ (`cachedModel`)

**doc ID 生成**
```
newsIdFromUrl(url) = "news_" + sha1(url).slice(0, 16)
→ 同じ記事を再取得しても冪等に上書きされる
```

---

### 2. Firestore スキーマ

#### `/news_pool/{newsId}`
全ユーザー共通の変換済み記事。

| フィールド | 型 | 内容 |
|---|---|---|
| `original_title` | string | 元の記事タイトル |
| `published_at` | Timestamp | 記事の公開日時 |
| `child_body_with_ruby` | string | Gemini が生成した子ども向け本文 (ルビ付き) |
| `parent_summary` | string | Gemini が生成した保護者向け箇条書き |

#### `/users/{uid}/personalized_feed/{newsId}`
ログインユーザーごとのフィードアイテム。

| フィールド | 型 | 内容 |
|---|---|---|
| `news_id` | string | `news_pool` の参照キー |
| `interest_context` | string | 出典名 (例: "NHK ニュース") |
| `display_title` | string | Gemini 生成の子ども向けタイトル |
| `display_tagline` | string | Gemini 生成のキャッチコピー |
| `thumbnail_config` | map | サムネイル設定 (下記) |
| `is_viewed` | bool | 閲覧済みフラグ |
| `view_duration_seconds` | number | 滞在秒数 (累積) |

**`thumbnail_config`**

| 画像あり | 画像なし |
|---|---|
| `mode: "generated"` | `mode: "text_overlay"` |
| `optional_generated_url: <GNews画像URL>` | テキストオーバーレイで表示 |

#### `/users/{uid}/interest_profile/current`
ユーザーの興味プロファイル (現状はサンプルシーダーのみ更新)。

---

### 3. Flutter アプリ層

#### データモデル (`lib/shared/models/`)

```
NewsPool               ← /news_pool/{id} に対応 (Freezed + json_serializable)
PersonalizedFeedItem   ← /personalized_feed/{id} に対応
  └── ThumbnailConfig  ← thumbnail_config に対応 (ThumbnailMode enum)
InterestProfile        ← /interest_profile/current に対応
  └── AiAgentMetadata
TimestampConverter     ← Firestore Timestamp ⇔ DateTime 変換
```

> `build.yaml` で `explicit_to_json: true` を設定済み
> (ネストモデルの Firestore シリアライズに必要)

#### Riverpod プロバイダ構成

```
firebaseReadyProvider   (bool)     Firebase 初期化成否 — main.dart でオーバーライド
firestoreProvider       Firestore  Firestore インスタンス
authProvider            FirebaseAuth
functionsProvider       FirebaseFunctions  (region: asia-northeast1)
authStateProvider       Stream<User?>
currentUserIdProvider   String     uid | "dev_local_user" (未認証時)

feedRepositoryProvider  FeedRepository     personalized_feed の読み書き
newsFetchServiceProvider NewsFetchService  fetchNews callable 呼び出し

childFeedProvider       AsyncNotifier<List<PersonalizedFeedItem>>
commonViewProvider      AsyncNotifier
parentDashboardProvider AsyncNotifier
```

#### フォールバック戦略

Firebase 未初期化・データなし・エラー → **ハードコードされたサンプルデータで継続動作**
→ バックエンド未整備でも Flutter 側の開発・UI検証が可能

#### 画面構成 (`GoRouter`)

| パス | 画面 | 用途 |
|---|---|---|
| `/login` | LoginScreen | 起動時認証 (Google / ゲスト) |
| `/child` | ChildFeedScreen | タブレット縦・TikTok風フィード |
| `/common` | CommonViewScreen | タブレット横・2カラム記事リーダー |
| `/parent` | ParentDashboardScreen | スマホ縦・保護者ダイジェスト |

**ChildFeedScreen の主な実装ポイント**
- `PageView.builder(scrollDirection: Axis.vertical)` で1記事=1ページ
- `_FastPageScrollPhysics` : 軽いスワイプで即スナップ (stiffness: 360, minFlingVelocity: 30)
- `_feedNotifier` を dispose 前にキャッシュ → 破棄後の `onPageChanged` でも安全に `recordView` を呼べる
- `recordView(newsId, seconds)` : 楽観的ローカル更新 + Firestore 書き込み (`FieldValue.increment`)

#### ルビ表示 (`FuriganaText`)

```
〔漢字｜よみ〕 markup を解析して漢字の上に読みを重ねる。
例: 〔環境｜かんきょう〕 → "環境" の上に小さく "かんきょう"

child_body_with_ruby を FuriganaText に渡せばそのまま描画される。
```

---

### 4. 認証フロー

```
アプリ起動
    │
    ├── Firebase 初期化成功?
    │       No → firebaseReadyProvider = false
    │               → ログイン画面スキップ、サンプルデータで動作
    │       Yes → authStateProvider 購読開始
    │
    ├── ログイン済み? → /child へ
    └── 未ログイン → /login へ
            ├── Google ログイン (firebase_auth signInWithProvider)
            └── ゲスト (anonymous signIn)
```

---

### 5. 手動トリガー (AppDrawer)

```
AppDrawer
    ├── サンプルデータ投入 (dev)  → firestoreSeeder.seedAll(uid)
    └── ニュース取得 (GNews)      → newsFetchService.fetchNews()
                                       → Cloud Functions fetchNews callable
                                       → 完了後に3画面プロバイダを invalidate
```

**注意:** `Navigator.pop()` でドロワーが破棄された後も async 処理が続くため、
`ProviderScope.containerOf(context)` を pop 前に取得し `ref` の代わりに使う。

---

## インフラ構成

| リソース | 設定 |
|---|---|
| Firebase プロジェクト | `ai-discovery-app-b3a9d` |
| Cloud Functions リージョン | `asia-northeast1` (東京) |
| Vertex AI リージョン | `us-central1` |
| Gemini モデル | `gemini-2.5-flash` |
| GNews API | `lang=ja, country=jp, max=10` (無料100req/日) |
| Secret Manager | `GNEWS_API_KEY` |
| 認証 | ADC (Cloud Functions 実行サービスアカウント) |

---

## 未実装 / 次の候補

| 項目 | 概要 |
|---|---|
| Cloud Scheduler | fetchNews の定期実行 (現状は手動トリガーのみ) |
| interest_profile 更新 | 閲覧履歴から興味スコアを更新する AI パイプライン |
| FCM Push 通知 | 親子トークプロンプト・マイルストーン到達通知 |
| Firestore セキュリティルール | `users/{uid}` を本人のみ、`news_pool` は読み取り専用 |
| Common View ↔ Child Feed 連携 | 「よんでみる」ボタンで記事リーダーへ遷移 |
| iOS 対応 | `flutterfire configure` で iOS 追加、REVERSED_CLIENT_ID 設定 |
