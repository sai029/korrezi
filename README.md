# AI Discovery Learning App

子ども向けの「ニュース発見」学習アプリ。TikTok / YouTube 風の UI で社会のできごとを探索し、
自己最適化する AI エージェントがコンテンツのパーソナライズと、保護者向けの「会話のきっかけ」生成を行う。

> 📄 詳細な要件は [`docs/SPECIFICATION.md`](docs/SPECIFICATION.md)、開発の進捗は
> [`docs/PROGRESS.md`](docs/PROGRESS.md) を参照。

---

## 技術スタック

| 領域 | 採用技術 |
|---|---|
| 状態管理 | Riverpod (`AsyncNotifier` / `Notifier`) |
| ナビゲーション | GoRouter（Push通知のディープリンク対応予定） |
| バックエンド | Firebase Auth / Cloud Firestore / FCM / Cloud Functions |
| AI | Gemini 2.0 / 2.5 Flash（Vertex AI / Cloud Functions 経由） |
| 画像 | テキストオーバーレイ ⇔ Imagen 3 を切替可能な抽象レイヤー |
| モデル | Freezed + json_serializable |

## 対象デバイス

- **Child / Common Mode**: タブレット（iPad等）— 縦/横 両対応
- **Parent Mode**: スマートフォン（iOS/Android）— 縦

---

## セットアップ（メンバー向け）

```bash
git clone https://github.com/sai029/flutter_application_1.git
cd flutter_application_1
flutter pub get
```

- `lib/firebase_options.dart` はコミット済みのため、`flutterfire configure` の再実行は **不要**。
- Firestore / Auth / FCM を使うには、**Firebase コンソールでメンバー招待**が必要
  （プロジェクト設定 → ユーザーと権限）。
- コード生成をやり直す場合:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

### 既知の前提・注意

- **iOS 未設定**: 現在 Android のみ。iPad/iPhone でビルドするなら `flutterfire configure` で ios を追加。
- **Android SDK**: Flutter は SDK 36 を要求（環境により要更新）。
- **秘密情報**: service account 鍵 / `.env` / Gemini等のAPIキーは **絶対にコミットしない**
  （`.gitignore` で除外済み）。

---

## フォルダ構成（feature-first）

```
lib/
├── app.dart                  # MaterialApp.router + 向き連動テーマ
├── main.dart                 # ProviderScope エントリ
├── core/
│   ├── theme/theme.dart      # child/parent/common テーマ + OrientationResponsiveTheme
│   └── router/app_router.dart# GoRouter ルート定義
├── features/
│   ├── parent_dashboard/     # 保護者向けダッシュボード（presentation/application/data）
│   ├── child_feed/           # 子ども向け縦スクロールフィード
│   └── common_view/          # 親子同時閲覧（横向き2カラム）
└── shared/
    ├── models/               # Freezed モデル（Firestore スキーマ反映）
    └── widgets/              # 共有ウィジェット（画像抽象化レイヤー等）
```

---

## 開発コマンド

```bash
flutter analyze          # 静的解析
flutter test             # テスト
flutter run              # 実行（要 実機/エミュレータ）
dart run build_runner watch --delete-conflicting-outputs  # モデル編集中の自動生成
```
