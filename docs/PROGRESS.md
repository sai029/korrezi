# 進捗状況

> 最終更新: 2026-06-28 ／ 要件は [`SPECIFICATION.md`](SPECIFICATION.md) を参照。

## 全体サマリ

| Step | 内容 | 状態 |
|---|---|---|
| 1 | pubspec（Riverpod/GoRouter/Firebase/FCM/Freezed） | ✅ 完了 |
| 2 | feature-first フォルダ構造 | ✅ 完了 |
| 3 | 動的テーマ切替（AnimatedTheme × 向き連動） | ✅ 完了 |
| 4 | Freezed モデル（Firestore スキーマ反映） | ✅ 完了 |
| 5 | Child Feed（縦 PageView + Telemetry 雛形） | ✅ 完了 |
| — | Parent Dashboard（骨格） | ✅ 完了 |
| — | Common View（骨格・2カラム + ルビ） | ✅ 完了 |
| — | 画面間ナビゲーション（AppDrawer） | ✅ 完了 |
| — | Firebase 初期化（main で initializeApp、失敗時はサンプルへ） | ✅ 完了 |
| — | Firestore 実連携（data層リポジトリ + 3画面プロバイダ接続） | ✅ 完了 |
| — | 認証（起動時ログイン画面 / Google・ゲスト / ログアウト） | ✅ 完了 |
| — | Cloud Functions: GNews 実記事取得 + Gemini 子ども向け変換 | ✅ 完了 |
| — | AI エージェント 3本（パーソナライズ・興味検知・サムネ生成） | ✅ 完了 |
| — | Firebase Storage + CORS 設定 | ✅ 完了 |

検証: `flutter analyze` → No issues ／ `flutter test` → All passed。

---

## 完了した内容

### Step 1-2: 基盤
- `pubspec.yaml` に Riverpod / GoRouter / Firebase / FCM / Freezed 等を追加
- feature-first 構成（`parent_dashboard` / `child_feed` / `common_view` を
  `presentation` / `application` / `data` の3層で）+ `shared/{models,widgets}`
- `core/theme`・`core/router`（GoRouter: `/child`・`/common`・`/parent`）

### Step 3: 動的テーマ（`lib/core/theme/theme.dart`）
- `childMode` / `parentMode` / `commonMode` の3テーマ（Noto Sans JP ベース）
- `OrientationResponsiveTheme`: 横向き→ Common Mode（フォント・行間拡大）を
  `AnimatedTheme` で滑らかに遷移。`app.dart` で全ルートに適用

### Step 4: Freezed モデル（`lib/shared/models/`）
- `NewsPool` / `PersonalizedFeedItem`(+`ThumbnailConfig`,`ThumbnailMode`) /
  `InterestProfile`(+`AiAgentMetadata`)
- `TimestampConverter`: Firestore `Timestamp` ⇔ `DateTime`
- `.freezed.dart` / `.g.dart` 生成済み（コミット対象）

### Step 5: Child Feed（`lib/features/child_feed/`）
- `child_feed_screen.dart`: `PageView.builder(scrollDirection: Axis.vertical)` の没入型UI、
  ページ滞在秒数を計測し Telemetry へ
- `child_feed_provider.dart`: `AsyncNotifier` + `recordView`（現状サンプルデータ）
- `shared/widgets/feed_thumbnail.dart`: 画像抽象化レイヤー
  （既定 text_overlay / `useGeneratedImages` で Imagen 3 切替）

### 追加ページ（骨格）
- **Parent Dashboard**（`features/parent_dashboard/`）: Interest Cloud（スコア可変バッジ）、
  親子トークプロンプト、保護者向け要約。`AsyncNotifier` + サンプルデータ
- **Common View**（`features/common_view/`）: 横幅に応じた2カラム分割
  （左=ナビゲーショングリッド / 右=記事リーダー）。`LayoutBuilder` で縦向きは1カラムへ
- **FuriganaText**（`shared/widgets/`）: `〔漢字｜よみ〕` markup をルビ表示
- **AppDrawer**（`shared/widgets/`）: 開発用に3モードを行き来する導線

### Firebase
- `flutterfire configure` で **Android 設定済み**（`firebase_options.dart` /
  `google-services.json` / `firebase.json`）
- GitHub: https://github.com/sai029/flutter_application_1 （Private）

---

## 未着手 / 次の候補

1. **Cloud Functions（仕様4章）**: `functions/` で Gemini 連携・3段階の AI DevOps パイプライン。
   合わせて `news_pool` / `personalized_feed` / `interest_profile` へ実データ投入
2. **記事品質ゲート（採点AI）**: GNews 取得記事を Gemini で4軸採点し、`toChildFriendly` の前段で
   フィルタ。安全性は即除外＋品質軸は記録のみ→閾値確定後に自動除外（ハイブリッド）。
   方針: [`CONTENT_QUALITY_GATE.md`](CONTENT_QUALITY_GATE.md)
3. **FCM Push 受信**: 親子トークプロンプト準備・興味マイルストーン到達時の通知 + ディープリンク
4. **YouTube風メディアグリッド（仕様②）**: タブレット向けグリッド探索
5. **Firestore セキュリティルール**: `users/{uid}` を本人のみ、`news_pool` は読み取り専用に
6. **リアルタイム購読化**: 現状は `.get()` 一括取得。必要に応じて `snapshots()` ストリームへ
1. **`interest_context` のトピック分類**: 現在は GNews のソース名（"NHK ニュース" 等）が入っている。Gemini でトピック分類（"Science", "Sports" 等）に変換すると、パーソナライズ精度とサムネ品質が向上する
2. **FCM Push 受信**: 親子トークプロンプト準備・興味マイルストーン到達時の通知 + ディープリンク
3. **YouTube風メディアグリッド（仕様②）**: タブレット向けグリッド探索
4. **Firestore セキュリティルール**: `users/{uid}` を本人のみ、`news_pool` は読み取り専用に強化
5. **リアルタイム購読化**: 現状は `.get()` 一括取得。必要に応じて `snapshots()` ストリームへ
6. **サムネコスト最適化**: `interest_score < 40` の記事は Imagen 生成をスキップ

### Firestore 実連携（完了）の内容
- `lib/core/firebase/firebase_providers.dart`: `firebaseReadyProvider` /
  `firestoreProvider` / `authProvider` / `currentUserIdProvider`（匿名認証、失敗時 `dev_local_user`）
- `data/` 層リポジトリ: `FeedRepository`(personalized_feed + recordView 書込) /
  `NewsRepository`(news_pool) / `ParentDashboardRepository`(interest_profile/current + news_pool)
- 3画面プロバイダを接続。**Firebase 未初期化・データ無し・エラー時はサンプルにフォールバック**するため、
  バックエンド未整備でも動作・テスト継続が可能
- `main.dart` で `Firebase.initializeApp` を try/catch、結果を `firebaseReadyProvider` に override
- データモデルのパス対応: `interest_profile` は単一オブジェクト想定のため
  `users/{uid}/interest_profile/current` ドキュメントとして格納

---

## 既知の課題・注意

- **iOS 未設定**: Android のみ。iPad/iPhone ビルドには `flutterfire configure` で ios 追加が必要
- **Android SDK**: Flutter は SDK 36 を要求（`flutter doctor` 要確認、ビルド時に更新が必要な場合あり）
- **削除した依存**: `custom_lint` / `riverpod_lint` / `riverpod_generator` は古い
  `analyzer_plugin` を引き込み build_runner と競合したため削除（プレーン Riverpod を使用中）
- **サムネ画像未配置**: `assets/images/categories/*.png` が無いため現状はグラデーション背景に
  フォールバック（画像を置けば自動表示）

---

## サンプルデータ投入（dev シーダー）

実データ（Cloud Functions）未実装のため、開発用に Firestore へサンプルを投入できる。

- 実装: `lib/core/firebase/firestore_seeder.dart`（`news_pool` / `personalized_feed` /
  `interest_profile/current` を1バッチ書込み。news_pool と personalized_feed は同一 doc id で対応）
- 実行: アプリ起動 → 左ドロワー → **「サンプルデータ投入 (dev)」** をタップ。投入後に3画面のプロバイダを
  自動 invalidate して再取得。個人配下データは実行時の（匿名）uid に紐づくため表示と一致する

**投入に必要な手動設定（Firebase 側、未実施なら要対応）:**
1. Firebase コンソール → Authentication → Sign-in method で **匿名（Anonymous）を有効化**
   （無効だと uid が取れず、ルールの `request.auth != null` が false になり書込み拒否）
2. Firestore セキュリティルールを反映: `firebase deploy --only firestore:rules`
   （ルールは `firestore.rules`。認証済みユーザーに news_pool 読み書き＋本人の users 配下のみ許可）

---

## GNews 実ニュース取得（Cloud Functions）

実記事（タイトル・本文・画像）を取り込むため、GNews.io を呼ぶ Cloud Function を用意した。
**まず「生記事のまま」投入**（子ども向けのルビ付与・やさしい言い換えは後フェーズの Gemini で対応）。

- 実装: `functions/src/index.ts` の `fetchNews`（v2 `onCall`、`asia-northeast1`）。
  GNews `top-headlines?lang=ja&country=jp&max=10` を取得し、`WriteBatch` で
  `news_pool/{id}`（id=記事 URL の sha1 先頭16桁）と呼び出しユーザーの
  `users/{uid}/personalized_feed/{id}` を書き込む。Admin SDK のためルールはバイパス
- マッピング: `original_title`=title / `parent_summary`=description /
  `child_body_with_ruby`=content（ルビ無し）。`image` があれば
  `thumbnail_config.mode=generated`+URL（`FeedThumbnail` が NetworkImage 表示）
- アプリ側: `core/firebase/news_fetch_service.dart`（`fetchNews` callable 呼び出し）、
  `functionsProvider`、ドロワー **「ニュース取得 (GNews)」** タイル。取得後に3画面を invalidate

**デプロイに必要な手順（未実施なら要対応）:**
1. **Blaze プラン**（Functions / Secret Manager / 外部API通信に必須。アップグレード済み）
2. **GNews API キー**を取得（https://gnews.io 無料サインアップ・100req/日）
3. シークレット登録: `firebase functions:secrets:set GNEWS_API_KEY`（対話でキーを貼り付け）
4. デプロイ: `firebase deploy --only functions`
5. 実機でログイン → ドロワー「ニュース取得 (GNews)」→「N 件取得しました」

**注意:** GNews 無料枠は `content` が途中まで（数百字）。定期実行（Cloud Scheduler）は未導入で、
現状は手動トリガのみ。

---

## 認証（起動時ログイン）

- 構成: `core/auth/auth_service.dart`（Google: `signInWithProvider` / ゲスト: 匿名 / signOut）、
  `core/firebase/firebase_providers.dart` の `authStateProvider` + `currentUserIdProvider`、
  `features/auth/presentation/login_screen.dart`、`core/router/app_router.dart` の redirect
- 挙動: Firebase 有効 & 未ログイン → `/login` へ。Firebase 未初期化時（テスト等）はゲート無効でサンプル動作
- Google ログインは `google_sign_in` 不要（`firebase_auth` の `signInWithProvider`）

**残作業 / 注意:**
- **iOS**: Google ログインに `ios/Runner/Info.plist` へ REVERSED_CLIENT_ID の URL スキーム追加が必要
  （`GoogleService-Info.plist` の取得・配置も）。現状 Android のみ設定済み
- リリースビルド用 SHA-1 を別途 Firebase に登録要（現状は debug キーのみ）
- Web/Windows デスクトップは `signInWithProvider` の Google フロー非対応のため、当面 Android/iOS で検証

---

## 開発メモ

- モデル編集時: `dart run build_runner watch --delete-conflicting-outputs`
- 検証: `flutter analyze` / `flutter test`
- 実機/エミュレータ確認: `flutter run`（Android 推奨）
- 秘密情報（service account 鍵・`.env`・AI APIキー）は **コミット禁止**（`.gitignore` 済み）
