# 業務改善レポート（2026-07-02）

> 実施: Claude Fable 5 による体験設計・AIエージェント・運用の総合改善セッション
> 関連: [`OPERATIONS.md`](OPERATIONS.md) ・ [`ARCHITECTURE.md`](ARCHITECTURE.md) ・ [`ai_agents_spec.md`](ai_agents_spec.md) ・ [`PROGRESS.md`](PROGRESS.md)

---

## 業務改善サマリー

- **一番大きいボトルネック:** `interest_context` にニュースソース名（"NHK ニュース"）が入っていたこと。
  興味学習（DISA）・パーソナライズ・サムネ生成の3エージェント全てがこの値を土台にしており、
  「子どもの興味」ではなく「よく見る放送局」を学習していた。
- **最優先で直すべきこと:** 上記は修正済み（採点ゲートの既存 Gemini 呼び出しに `topic` を追加、
  追加 API コストゼロで12分類）。**ただし `firebase deploy --only functions` が未実行**。
  次点は「本番障害がサンプル表示に化けて気づけない」問題で、SampleDataBanner により可視化済み。
- **今回作ったもの:** QA一括ゲート（/qa Skill）、テスト14件、トピック分類、Imagen コストスキップ、
  共通エラー/空状態 UI + サンプルバナー、運用ランブック、ドキュメントマップ。
- **次に作るべきもの:** 親子トークプロンプトの実生成（Parent Dashboard の中核価値が未完）。

---

## STEP 1: パイプライン分析（ロードマップ）

| # | 工程 | 入力 | 処理 | 出力 | 使うツール | 詰まりやすい点 |
|---|---|---|---|---|---|---|
| 1 | 記事取得 | GNews API（ja/jp/max10） | `fetchNews`(手動) / `refreshNewsPool`(毎朝6時・停止中) | 生記事10件 | Cloud Functions, Secret Manager | 無料枠100req/日。Scheduler 停止状態の把握が属人的 |
| 2 | 品質ゲート | 生記事 | `scoreArticle`: Gemini 4軸採点 + トピック分類（temp=0） | 合格記事 + `rejected_articles` | Gemini 2.5 Flash | fail-closed でフィードが空になりうる。閾値調整用の集計が手作業 |
| 3 | 子ども向け変換 | 合格記事 | `toChildFriendly`: ルビ付き書き換え | `news_pool` | Gemini | JSON 崩れ→生記事フォールバック（ルビなし混入） |
| 4 | パーソナライズ | `news_pool` + `interest_profile` | `personalizeArticles`: 興味スコア + タイトル書き換え | `personalized_feed` | Gemini | ~~interest_context がソース名~~（今回修正） |
| 5 | サムネ生成 | パーソナライズ結果 | Gemini 英語プロンプト → Imagen 3 | Storage + Download URL | Imagen 3 Fast | ~~20記事全部に生成~~（今回 score<40 スキップ） |
| 6 | 興味学習 | 閲覧テレメトリ | DISA（決定論式）+ agent_notes(Gemini) | `interest_profile` | Cloud Functions | ~~カテゴリ=ソース名で学習が歪む~~（今回修正） |
| 7 | 表示 | Firestore | Riverpod AsyncNotifier → 3画面 | Child/Common/Parent UI | Flutter | エラーを握りつぶしサンプルへ静かにフォールバック（今回バナーで可視化） |
| 8 | QA | コード変更 | analyze / test / design_check | 合否 | flutter, bash | ~~テスト1本・一括コマンドなし~~（今回 /qa + 14テスト） |

### 人間の判断 vs AI に任せられる作業

| 人間がやるべき判断 | AI に任せられる作業 |
|---|---|
| 品質ゲート閾値の最終決定（①②③軸の除外開始） | 採点実績の集計・閾値候補の提案 |
| Scheduler 再開・課金操作・デプロイの承認 | デプロイ前チェックリストの消化・ビルド検証 |
| 子どもに見せるカテゴリタクソノミーの承認 | 記事のトピック分類そのもの（Gemini） |
| デザイントーンの方向性 | トークン違反検出（hook 化済み）・修正 |
| サンプルフォールバックの本番での扱い | エラー検知・フォールバック状態の可視化 |

---

## STEP 2: 改善候補16案の評価

**凡例:** 難易度=低/中/高、優先度=P1(最優先)〜P3

| # | 改善案 | 解決する課題 | 期待効果 | 作るもの | 難易度 | 所要 | リスク | 優先度 |
|---|---|---|---|---|---|---|---|---|
| 1 | interest_context のトピック分類（採点ゲートの同一 Gemini 呼び出しに topic 追加） | DISA・パーソナライズ・サムネがソース名で汚染 | 3エージェント全ての精度が根本改善。追加 API コストゼロ | functions 修正 | 中 | 1h | 旧カテゴリスコアと不連続（減衰で自然消滅） | **P1 ✅実装** |
| 2 | Imagen スキップ（interest_score<40） | 20記事全てにサムネ生成＝コスト最大要因 | Imagen コスト約3〜5割減 | functions 修正 | 低 | 15m | 低スコア記事がグラデ背景（デザイン済み） | **P1 ✅実装** |
| 3 | /qa Skill（analyze+test+design_check+tsc 一括） | QA が個別コマンド頼み・実行漏れ | コミット前品質の標準化 | `.claude/skills/qa/` | 低 | 30m | なし | **P1 ✅実装** |
| 4 | テスト拡充（FuriganaText パーサ・モデル変換） | スモークテスト1本のみ | AI 生成 markup の表示保証 | `test/*.dart` | 低 | 1h | なし | **P1 ✅実装** |
| 5 | 共通エラー/空状態ウィジェット + サンプルデータバナー | エラー握りつぶしで本番障害が「サンプル表示」に化ける | 障害の可視化・再試行導線 | `status_views.dart` + 画面適用 | 中 | 1.5h | なし | **P1 ✅実装** |
| 6 | 運用ランブック | Scheduler 状態・GNews 枠・デプロイ手順が暗黙知 | 運用の属人化解消・事故防止 | `OPERATIONS.md` | 低 | 1h | なし | **P1 ✅実装** |
| 7 | 品質ゲート閾値キャリブレーション支援スクリプト | 採点実績の集計が手作業 | 自動除外への移行判断が数分で可能 | quality_review 集計スクリプト | 中 | 1.5h | Firestore 読み取りに認証が必要 | P2 |
| 8 | 親子トークプロンプト実生成 | Parent Dashboard の中核価値がサンプルのまま | 保護者体験の完成 | `generateTalkPrompts` function | 中 | 3h | Gemini コスト増（1日1回/ユーザー） | P2 |
| 9 | オンボーディング興味選択画面 | 新規ユーザーの初回フィードが無個性 | コールドスタート解消 | 選択 UI + profile 初期値 | 中 | 3h | タクソノミー確定（#1）が前提→今回解消 | P2 |
| 10 | パーソナライズ後タイトルのルビ振り直し | 書き換え後タイトルにルビがない | 子ども向け表示の一貫性 | `personalizeOneArticle` プロンプト修正 | 低 | 30m | 出力トークン微増 | P2 |
| 11 | docs 整合性の定期監査 | docs とコードのドリフト（DESIGN_SYSTEM.md が旧パープル案等） | 誤読防止 | `docs/README.md` | 低 | 30m | なし | **P2 ✅実装** |
| 12 | FCM Push（トークプロンプト通知 + ディープリンク） | 保護者の再訪導線がない | エンゲージメント向上 | FCM + GoRouter ディープリンク | 高 | 1日 | iOS 未対応・通知疲れ | P3 |
| 13 | Firestore リアルタイム購読化 | 手動 invalidate 頼み | サムネ生成完了が自動反映 | リポジトリの Stream 化 | 中 | 3h | 読み取り課金増 | P3 |
| 14 | 自己評価 DevOps エージェント（CTR 監査→メタプロンプト変異） | 仕様書 3rd Stage 未着手 | パーソナライズの自律改善 | スケジュール関数 + プロンプト版数管理 | 高 | 2〜3日 | 暴走時のロールバック設計必須 | P3 |
| 15 | E2E QA 自動化（integration_test + エミュレータ） | 実機確認が手動 | リグレッション自動検知 | `integration_test/` + Emulator Suite | 高 | 1〜2日 | CI 構築コスト | P3 |
| 16 | 運用コストダッシュボード（AI 呼び出しカウンタ） | コストが請求書まで見えない | 予算超過の早期検知 | functions 内カウンタ + 集計 | 中 | 2h | なし | P2 |

## STEP 3: 優先順位の3分類

1. **今日すぐ作るべき Quick Win:** #2 Imagen スキップ、#3 /qa Skill、#4 テスト拡充、#6 ランブック、#11 docs マップ
2. **今後ずっと効く改善:** #1 トピック分類、#5 エラー可視化、#7 閾値キャリブレーション、#10 ルビ振り直し、#16 コストカウンタ
3. **Fable 5 の今こそ挑戦すべき高難度:** #14 自己評価 DevOps エージェント、#12 FCM+ディープリンク、#15 E2E 自動化

**着手した3本と理由:**
1. **#1+#2（トピック分類 + Imagen スキップ）** — 興味学習の土台の歪みを、既存 Gemini 呼び出しへの1フィールド追加だけで修正でき、効果対コストが全候補中最大。
2. **#3+#4（/qa + テスト）** — 以後の全変更（今回含む）の安全網。先に作れば今日から効く。
3. **#5+#6（エラー可視化 + ランブック）** — 「障害がサンプル表示に化ける」のは子ども向けアプリとして最も危険な運用リスク。

---

## STEP 4: 実装内容（変更ファイル一覧）

### 新規作成

| ファイル | 内容 |
|---|---|
| `.claude/skills/qa/SKILL.md` | QA 一括ゲート（analyze / test / design token / tsc → サマリー表） |
| `test/furigana_text_test.dart` | ルビ解析テスト6件（漢字ルビ・かな除外・壊れた markup 耐性等） |
| `test/models_test.dart` | モデル変換テスト8件（欠落フィールド耐性・Timestamp 変換等） |
| `lib/shared/widgets/status_views.dart` | ErrorRetryView / EmptyStateView / SampleDataBanner |
| `docs/OPERATIONS.md` | 運用ランブック（チェックリスト・デプロイ SOP・障害対応・コスト管理） |
| `docs/README.md` | docs マップ + 命名/保存ルール + 「何を正とするか」 |

### 変更

| ファイル | 内容 |
|---|---|
| `functions/src/index.ts` | ①採点ゲートにトピック分類追加（12分類タクソノミー・フォールバック付き・schema_version 2）②`interest_context` にトピック、出典名は `source_name` に分離 ③`interest_score < 40` の Imagen スキップ（`THUMBNAIL_MIN_INTEREST_SCORE`） |
| `scripts/design_check.sh` | `--all` オプション追加（lib/ 全量チェック。無引数は従来どおりステージ済みのみ） |
| `lib/features/child_feed/presentation/child_feed_screen.dart` | エラー/空状態を共通ウィジェット化・サンプルバナー表示・トークン違反3件解消 |
| `lib/features/child_feed/application/child_feed_provider.dart` | `isSampleFeed()` 判定関数を追加 |
| `lib/features/common_view/presentation/article_detail_screen.dart` | トークン違反1件解消（`Colors.black` → `AppColors.ink900`） |
| `lib/shared/models/news_pool.dart` | `interestContext` のドキュメントコメント更新 |
| `docs/ARCHITECTURE.md` / `docs/ai_agents_spec.md` / `docs/PROGRESS.md` | スキーマ変更・完了項目を反映 |

### トピック分類タクソノミー（12分類）

科学 / 宇宙 / テクノロジー / 自然・環境 / 動物 / スポーツ / 食べ物 / 音楽・アート / 経済・お金 / 国際・世界 / 文化・歴史 / 社会・くらし

- アプリ側 `categoryIcon()`（feed_thumbnail.dart）の日本語キーワードと部分一致するよう命名
- 分類不能・タクソノミー外の語は「社会・くらし」へフォールバック
- 旧ソース名カテゴリの interest_profile スコアは DISA 減衰で自然消滅（手動移行不要）

## STEP 5: QA 結果

| チェック | 結果 | 備考 |
|---|---|---|
| flutter analyze | ✅ | No issues found |
| flutter test | ✅ | 15件パス（新規14 + 既存1） |
| デザイントークン（--all 全量） | ✅ | 既存違反4件も解消 |
| functions tsc --noEmit | ✅ | 型エラーなし |

**安全性の確認:**
- スキーマは追加のみ（`source_name` / `quality_review.topic`）。Dart モデルは未知フィールドを無視するため旧データ・旧アプリとも互換
- Gemini がタクソノミー外の語を返してもコード側で検証しフォールバック（二重防御）
- 外部投稿・課金操作・データ削除は一切なし。`firebase deploy` は未実行

---

## 自動化候補一覧（今後）

| 候補 | 状態 | 効果 |
|---|---|---|
| QA 一括実行 | ✅ 実装（/qa） | コミット前品質の標準化 |
| トピック分類 | ✅ 実装・**要デプロイ** | 3エージェントの精度の土台 |
| Imagen コストスキップ | ✅ 実装・**要デプロイ** | サムネコスト約3〜5割減 |
| デザイントークン検査 | ✅ hook + --all | デザイン一貫性 |
| 品質ゲート閾値の集計スクリプト | 手順書のみ（OPERATIONS §6） | 自動除外への移行判断 |
| トークプロンプト日次生成 | 未着手 | 保護者体験の完成 |
| コストカウンタ | 未着手 | 予算超過の早期検知 |
| 自己評価 DevOps エージェント | 未着手（高難度） | パーソナライズの自律改善 |

## 今回作成した資産の使い方

| 資産 | 置き場所 | 次回の呼び出し方 |
|---|---|---|
| QA ゲート | `.claude/skills/qa/SKILL.md` | Claude Code で **`/qa`** と入力 |
| 回帰テスト | `test/furigana_text_test.dart` ほか | `flutter test`（/qa に含まれる） |
| トピック分類 + Imagen スキップ | `functions/src/index.ts` | `firebase deploy --only functions` 後に自動動作 |
| 共通ステータス UI | `lib/shared/widgets/status_views.dart` | `ErrorRetryView` / `EmptyStateView` / `SampleDataBanner` を import |
| 運用ランブック | `docs/OPERATIONS.md` | 運用操作（デプロイ・課金・障害対応）の前に開く |
| docs マップ | `docs/README.md` | 新セッションの最初に開く |
| トークン全量検査 | `scripts/design_check.sh` | `bash scripts/design_check.sh --all` |

## 追加で作ると効果が大きいもの

1. **親子トークプロンプト実生成** — 既読記事 + interest_profile から Gemini が会話のきっかけを日次生成する Cloud Function。アプリの提供価値（親子の会話）の中核が現状サンプルのまま。
2. **オンボーディング興味選択画面** — 今回の12分類タクソノミーをそのまま選択肢にでき、新規ユーザーのコールドスタートを解消。実装の前提が今日整った。
3. **品質ゲート閾値キャリブレーションスクリプト** — `quality_review.scores` を集計して軸ごとの分布を出すスクリプト。採点実績100件超（2〜3週間後）で自動除外へ移行できる。

---

## 残っている人間の判断

1. **デプロイ:** functions の変更は tsc 検証済みだが未デプロイ。`firebase deploy --only functions`（手順: OPERATIONS.md §4）
2. **コミット:** 変更16ファイルは未コミット（pre-commit のデザインチェックは通る状態）
