# コレッジ（Koledge）

**子どもの「なぜ？」を育てる、自律進化型 AI ニュース発見アプリ。**

複数の AI エージェントが子ども一人ひとりの興味を自律的に学習し、世界のニュースを「その子だけの発見体験」へと毎日つくり変えます。子どもはショート動画アプリのような直感的なフィードで社会のできごとに出会い、保護者にはその日子どもが読んだ記事の「まなびレポート」（保護者向け要約＋読書状況）が届きます。

> 名前の由来：**子ども（Kid） × 知識（Knowledge）**。Google Cloud を活用した AI エージェントのハッカソン作品として開発しました。

---

## 主な機能

- **やさしいニュース変換** — 難しい世界のニュースを、6〜10 歳向けに「やさしい言葉＋ふりがな」へ自動変換
- **自律パーソナライズ** — 読むほどにフィードがその子の興味へ最適化。同じニュースでも「その子が夢中な切り口」でタイトル・サムネイルが変化
- **AI 生成クイズ** — 記事内容から自動生成される 4 択クイズで、理解を「いっしょに」確認
- **まなびレポート（保護者向け）** — 今日子どもが読んだ記事の要約と読書状況を、保護者のスマホへ
- **多層セーフティ** — AI による品質採点とガードレールで、有害・低質なコンテンツを子どもに届く前に除外

### 3 つのモード

| モード | 端末・向き | 役割 |
|---|---|---|
| **Child** | タブレット・縦 | ショート動画風の縦スクロールでニュースを探索 |
| **Common** | タブレット・横 | 親子で読む 2 カラムの記事リーダー＋クイズ（「いっしょに」） |
| **Parent** | スマホ・縦 | 「まなびレポート」ダッシュボード |

---

## AI エージェントの仕組み

バックエンド（Cloud Functions）上で、役割の異なる複数の AI エージェントが連携して 1 つのニュース体験を組み上げます。

| エージェント | 役割 |
|---|---|
| 記事変換 AI | ニュースを子ども向けの文章＋ふりがな＋保護者向け要約に書き換える |
| 品質採点 AI | 教育的価値・安全性などを採点し、不適切な記事を除外する（LLM-as-a-Judge） |
| 興味検知 AI | 閲覧行動（滞在時間）から興味を学習する（DISA アルゴリズム） |
| パーソナライズ AI | 学習した興味に合わせてタイトル・タグラインを書き換える |
| サムネ生成 AI | 記事に合ったサムネイル画像を生成する（Imagen 3） |
| クイズ生成 AI | 記事本文から 4 択クイズを生成する |

**設計のポイント**：興味スコアの更新は決定論的な数式で行い、LLM は文章生成と定性メモの更新のみを担当します。これにより「再現性（学習の妥当性）」と「創発性（毎日新しい発見）」を両立し、エージェントが暴走しないようガードレールを設けています。

詳しくは [`docs/ai_agents_spec.md`](docs/ai_agents_spec.md) / [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) を参照してください。

---

## 技術スタック

- **インフラ / バックエンド**：Google Cloud（Cloud Functions 第2世代 / Cloud Scheduler / Secret Manager）
- **AI・LLM**：Gemini API（`gemini-2.5-flash`）, Imagen 3（Vertex AI 経由）
- **フロントエンド**：Flutter（Dart, Riverpod, GoRouter）
- **データベース / 認証**：Firebase（Cloud Firestore, Authentication, Cloud Storage, FCM）
- **モデル生成**：Freezed + json_serializable
- **外部 API**：GNews API（ニュースソース取得）

---

## はじめかた

### 必要なもの

- [Flutter SDK](https://docs.flutter.dev/get-started/install)（安定版）

### クローンして起動

```bash
git clone https://github.com/sai029/flutter_application_1.git
cd flutter_application_1
flutter pub get
flutter run
```

> **バックエンドなしでも動きます。** Firebase 未接続時はハードコードされたサンプルデータにフォールバックするため、UI やデザインをすぐに確認できます。

### バックエンドまで動かす場合

実データ（ニュース取得・パーソナライズ・通知など）を有効にするには、**自分の Firebase / Google Cloud プロジェクト**と外部 API キーが必要です。

- `flutterfire configure` で自分のプロジェクトの `lib/firebase_options.dart` を生成
- `functions/` を `firebase deploy --only functions` でデプロイ
- GNews API キーを Secret Manager に登録
- Vertex AI（Gemini / Imagen）を利用可能にする

> **秘密情報はコミットしないでください。** service account 鍵 / `.env` / 各種 API キーは `.gitignore` で除外しています。

### コード生成（モデルを編集したとき）

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## プロジェクト構成（feature-first）

```
lib/
├── main.dart                 # ProviderScope エントリ
├── app.dart                  # MaterialApp.router
├── core/                     # テーマ / ルーター / Firebase / 通知 / 端末ロール など横断機能
├── features/
│   ├── child_feed/           # 子ども向け縦スクロールフィード
│   ├── common_view/          # 親子同時閲覧（横向き2カラム＋クイズ）
│   ├── parent_dashboard/     # 保護者向け「まなびレポート」
│   ├── auth/                 # 認証（ログイン / オンボーディング）
│   └── settings/             # 設定
└── shared/
    ├── models/               # Freezed モデル（Firestore スキーマ反映）
    └── widgets/              # 共有ウィジェット

functions/                    # Cloud Functions（AI エージェント群 / TypeScript）
docs/                         # 仕様・アーキテクチャ・運用ドキュメント
```

---

## 開発コマンド

```bash
flutter analyze          # 静的解析
flutter test             # テスト
flutter run              # 実行（要 実機 / エミュレータ / Chrome）
dart run build_runner watch --delete-conflicting-outputs  # モデル編集中の自動生成
```

---

## ドキュメント

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — システム全体像・データフロー
- [`docs/ai_agents_spec.md`](docs/ai_agents_spec.md) — AI エージェントの仕様
- [`docs/SPECIFICATION.md`](docs/SPECIFICATION.md) — 要件定義
- [`docs/CONTENT_QUALITY_GATE.md`](docs/CONTENT_QUALITY_GATE.md) — 記事品質ゲート（採点 AI）の方針

---

## 注記

本リポジトリは学習・ハッカソン目的で公開しているプロトタイプです。ニュース記事の権利は各配信元に帰属します。
