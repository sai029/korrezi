# docs ディレクトリ・マップ

> 作成: 2026-07-02。新しいドキュメントを足したら必ずこの表に1行追加する。

## ドキュメント一覧と「何を正とするか」

| ファイル | 役割 | 鮮度の注意 |
|---|---|---|
| [`SPECIFICATION.md`](SPECIFICATION.md) | 当初の要件定義（実装の元） | 歴史的文書。現状と食い違う場合は ARCHITECTURE.md が正 |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | **システム全体像の正**（データフロー・スキーマ・インフラ） | スキーマ変更時は必ず更新 |
| [`ai_agents_spec.md`](ai_agents_spec.md) | AI エージェント3本の実装仕様（DISA・パーソナライズ・サムネ） | Functions 変更時は必ず更新 |
| [`CONTENT_QUALITY_GATE.md`](CONTENT_QUALITY_GATE.md) | 記事採点ゲートの方針と Firestore 記録形式 | 閾値運用開始時に更新 |
| [`OPERATIONS.md`](OPERATIONS.md) | **運用ランブック**（チェックリスト・デプロイSOP・障害対応・コスト） | 運用手順が変わったら更新 |
| [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) | デザインシステムの原則 | **カラー定義は古い（旧パープル案）。色・数値は `lib/core/theme/tokens.dart` が正** |
| [`PARENT_REDESIGN.md`](PARENT_REDESIGN.md) | 親画面リデザインの設計判断（既読強調の理由など） | — |
| [`PROGRESS.md`](PROGRESS.md) | 進捗と次の候補 | セッション終了時に更新 |
| [`IMPROVEMENT_REPORT_2026-07-02.md`](IMPROVEMENT_REPORT_2026-07-02.md) | 業務改善セッションの分析・改善案16件・実装記録 | 記録文書（更新しない） |

## 命名・保存ルール

- docs は `UPPER_SNAKE.md`（例: `CONTENT_QUALITY_GATE.md`）。例外は歴史的経緯の `ai_agents_spec.md`
- 各ドキュメント冒頭に `> 最終更新: YYYY-MM-DD` を書く
- 設計「判断」（なぜそうしたか）は消さずに残す。手順・状態は最新に上書きする
- コードとドキュメントを同時に変える PR にする（あとでまとめて直さない）

## コード側の規約（要点）

- feature-first 構成: `lib/features/<name>/{presentation,application,data}` + `lib/shared` + `lib/core`
- 色・角丸・余白・アニメ時間は `lib/core/theme/tokens.dart` のトークンのみ使用
  （`scripts/design_check.sh` が commit 時に検査。全量チェックは `--all`）
- テストは `test/<対象>_test.dart`。新ウィジェット・新ロジックにはテストを添える
- Freezed モデル変更後は `dart run build_runner build --delete-conflicting-outputs`
