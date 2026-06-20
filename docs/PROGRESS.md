# 進捗状況

> 最終更新: 2026-06-20 ／ 要件は [`SPECIFICATION.md`](SPECIFICATION.md) を参照。

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
| — | Cloud Functions（Gemini/AIパイプライン） | ⬜ 未着手 |

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
2. **FCM Push 受信**: 親子トークプロンプト準備・興味マイルストーン到達時の通知 + ディープリンク
3. **YouTube風メディアグリッド（仕様②）**: タブレット向けグリッド探索
4. **Firestore セキュリティルール**: `users/{uid}` を本人のみ、`news_pool` は読み取り専用に
5. **リアルタイム購読化**: 現状は `.get()` 一括取得。必要に応じて `snapshots()` ストリームへ

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

## 開発メモ

- モデル編集時: `dart run build_runner watch --delete-conflicting-outputs`
- 検証: `flutter analyze` / `flutter test`
- 秘密情報（service account 鍵・`.env`・AI APIキー）は **コミット禁止**（`.gitignore` 済み）
