# 仕様書: AI Discovery Learning App

> 本ドキュメントは実装の元となる要件定義。進捗は [`PROGRESS.md`](PROGRESS.md) を参照。

## 1. ロール定義

Flutter (Dart) / GCP / Firebase / LLM エージェントアーキテクチャの専門家として、
自己最適化 AI エージェント基盤とレスポンシブクライアントを持つ、クロスプラットフォーム学習アプリを実装する。

**アーキテクチャ制約:**
- 状態管理: Riverpod（`Notifier` / `AsyncNotifier`）
- ナビゲーション: GoRouter（Push通知のディープリンク対応）
- バックエンド: Firebase Auth / Cloud Firestore / FCM / Cloud Functions
- AI: Gemini 2.0 / 2.5 Flash（Vertex AI / Cloud Functions 経由）
- 画像レイヤー: テキストオーバーレイ ⇔ 画像生成API（Imagen 3）をシームレスに切替可能な疎結合設計

## 2. 概要

子どもが TikTok / YouTube 風 UI で社会のできごとを探索するデジタル発見プラットフォーム。
AI エージェントがコンテンツのパーソナライズを自律最適化し、エンゲージメントを保護者向けの
共感的な会話プロンプトへ翻訳する。

**対象デバイス:**
- Child / Common Mode: タブレット（iPad等）— 縦/横 両対応
- Parent Mode: スマートフォン（iOS/Android）— 縦

**コアパッケージ:** `flutter_riverpod`, `riverpod_annotation`, `go_router`, `firebase_core`,
`firebase_auth`, `cloud_firestore`, `firebase_messaging`, `google_fonts`, `freezed_annotation`, `json_serializable`

## 3. デバイス別 UI 仕様

### ① Parent Mode（スマホ・縦）
- 目標: 冷たい「監視/グラフ」UI から、温かい「会話のきっかけ」UI へ
- **会話カタリスト・ダッシュボード**: 折れ線/円グラフの代わりに動的な「Interest Cloud / Topic Badges」
  （例: "最近の興味: 宇宙とサッカー！"）
- **親子トークプロンプト**: その日子どもが最も時間をかけて読んだ内容を元に AI が生成
- **大人向け要約**: 同じ日次5〜10記事を、簡潔な箇条書き `parent_summary` で表示
- **Push通知**: LINE/メールではなく FCM。深い興味のマイルストーン達成や新しい対話プロンプト準備時に通知

### ② Child Mode（タブレット・縦）
- **TikTok風エンドレスフィード**: `PageView.builder(scrollDirection: Axis.vertical)`。
  大型没入サムネ + 動的テキスト + アクションフック
- **YouTube風メディアグリッド**: タブレット最適化のグリッドで深掘り探索
- **Telemetry Agent**: 操作ログ（`view_duration_seconds`、スワイプ速度、探索選択）を Firestore へ静かに送信

### ③ Common Mode（タブレット・横）
- **物理トリガー**: `OrientationBuilder` で横向き遷移を検知
- **流動的スケーリング**: `commonModeTheme` へ切替。`AnimatedTheme` でフォント・行間を拡大し
  親子同時閲覧をサポート
- **分割レイアウト**: 2カラム（左: 動的ナビゲーショングリッド / 右: 記事リーダー + ルビ/Furigana）

## 4. AI エージェント DevOps & データパイプライン

Cloud Functions 内に **クローズドループ AI DevOps（自己評価・自動チューニング）** を実装する。

```
[子どものテレメトリ (滞在/スワイプ)]
        ↓
 【Analytics Agent】 → 数値的な興味プロファイルを最適化
        ↓
【Self-Evaluation DevOps Agent】
  - 子ども向けの分かりやすさ・Furigana精度を批評
  - パーソナライズタイトルの CTR を評価
        ↓
【Content Delivery Agent】 (システムプロンプト調整 & 次コンテキスト生成)
```

### 1st Stage: Curated Global Batch（1日1回）
Cloud Functions が世界のニュース 5〜10件を取得し、Gemini が以下を生成:
1. `child_body_with_ruby`: 子ども向けに書き直し、ルビ markup を埋め込んだ本文
2. `parent_summary`: 保護者向けの箇条書きダイジェスト

### 2nd Stage: リアルタイム動的ブレンド & 疎結合サムネ
セッション初期化時に `interest_profile` の上位ウェイトを取得。Gemini がタイトル/タグラインを
興味に合わせて翻訳（例: 経済 × サッカー）。
- **画像抽象化要件**: プレゼンテーション層は抽象的な `ImageProvider` を受け取る。既定はキャッシュ済み
  カテゴリイラストへの AIテキスト重ね。コスト検証後に Imagen 3 へ切替えるトグルを保持。

### 3rd Stage: 自律フィードバックループ（AI DevOps）
履歴テレメトリを解析する非同期 Cloud Function:
- **興味再較正**: 長い滞在時間が二次カテゴリへの拡張を正当化するか評価（例: サッカー → スポーツ科学 → 物理）
- **自己評価ステップ**: エージェントが自身の出力を監査。生成タイトルのテレメトリを読み
  （例: "サッカー×環境記事をスキップしたか？"）、スキップ率が高ければメタプロンプト/パラメータを
  自律的に変異させ、より良い教育的フックを探す（継続的自動 DevOps）

## 5. Firestore アーキテクチャ

### `/news_pool/{newsId}`
```json
{
  "original_title": "Global Environmental Regulations Strengthened",
  "published_at": "2026-06-16T00:00:00Z",
  "parent_summary": "Summary for adults. New regulations target carbon emissions...",
  "child_body_with_ruby": "〔世界｜せかい〕の〔環境｜かんきょう〕を守るルールが..."
}
```

### `/users/{userId}/personalized_feed/{newsId}`
```json
{
  "news_id": "newsId",
  "interest_context": "Soccer",
  "display_title": "Eco-Stadiums? How Soccer is Fighting Climate Change",
  "display_tagline": "Can your favorite sport save the planet?",
  "thumbnail_config": {
    "mode": "text_overlay",
    "base_asset": "assets/images/categories/soccer.png",
    "optional_generated_url": ""
  },
  "is_viewed": false,
  "view_duration_seconds": 0
}
```

### `/users/{userId}/interest_profile`
```json
{
  "current_interests": { "soccer": 85, "space": 40, "environment": 65 },
  "ai_agent_metadata": {
    "last_evaluation_cycle": "2026-06-16T12:00:00Z",
    "current_prompt_version": "v2.4_empathetic_sports_blend",
    "agent_notes": "Child responds heavily to sports metaphors but rejects purely political sub-contexts. Shifting weights to practical applied sciences."
  }
}
```

## 6. 実装ステップ

| Step | 内容 |
|---|---|
| 1 | `pubspec.yaml`（状態管理・ルーティング・Firebase/FCM） |
| 2 | feature フォルダ構造（`parent_dashboard`, `child_feed`, `common_view`, `shared/models`） |
| 3 | `theme.dart` の動的アニメーションテーマ切替（向き変化でフォント/レイアウト調整） |
| 4 | Freezed データモデル（`interest_profile` の AIエージェントメタデータ含む） |
| 5 | Child Mode プレゼンテーション（縦スクロール `PageView.builder`） |
