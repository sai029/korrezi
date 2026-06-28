# 親画面（Parent Dashboard）リデザイン方針

> 作成: 2026-06-24
> 対象: `lib/features/parent_dashboard/`
> 関連: [DESIGN_SYSTEM.md](./DESIGN_SYSTEM.md)（※カラー定義は後述の通り tokens.dart が最新）

## 0. 背景

- `lib/core/theme/tokens.dart` は既に **コミック・タブロイド（レトロモダン）テーマ** に刷新済み。
  ディープレッド `#D70026` ＋ ゴールデンアンバー `#EDB83D` ＋ 濃紺 `#000B29`、
  **太い黒ボーダー（`AppBorder`）／影なしフラット／小さめ角丸**が特徴。
  （`DESIGN_SYSTEM.md` 本文は旧パープル案のままで古い。色は tokens.dart を正とする。）
- 親画面はこの新テーマを活かしきれておらず、旧来のソフト影（現在は空）・淡いティント前提の地味な作り。

そこで本リデザインは **「大人もワクワクするレトロモダン新聞（ニュースピックス的）」** へ寄せつつ、
保護者が「子どもの今日」を一目で把握できる機能を足す。

## 1. 機能（最優先）

### 1-1. 今日の記事に「既読／未読」を表示

- 子どもが読んだか否か＝ `users/{uid}/personalized_feed/{newsId}.is_viewed`。
  `newsId` は `news_pool` のドキュメントID。
- リポジトリで news_pool を **doc id 付き**で取得し、閲覧済み newsId 集合と突き合わせて
  記事ごとに `isRead` を付与する（新クラス `ParentArticle`）。
- スタンプ表示: 既読＝「✓ よんだ」、未読＝「よんでない」。両方ハンコ風（わずかに回転）で
  カード上部に凡例も置く。

#### 強調の方向（重要な設計判断）

子どもが**読んだ記事こそ親に見にいってほしい**（会話のきっかけになる）ため、
一般的な「未読を目立たせる」UI とは**逆**にしている。

- **既読（よんだ）＝強調**: フルカラー＋太枠＋赤スタンプで目を引く。
- **未読（よんでない）＝抑える**: 彩度を落とし濃紺スタンプで落ち着かせる。

実装は `_ArticleCard` の `dim = !item.isRead` と `_ReadStamp` の色分岐で表現。

### 1-2. 各記事に「子どもの記事を見にいく」ボタン

- 全記事カードに full-width ボタンを設置。
- 押下で `selectedArticleIndexProvider`（common_view）にその記事の index をセットし、
  `/common`（親子で読む画面 ＝ 子どもが実際に読むルビ付きリーダー）へ遷移。
- 子フィードの「よんでみる」と同じ遷移なので、保護者は子どもが見る本文そのものを確認できる。
- index 整合: parent も common も news_pool を `published_at` 降順で取得するため
  先頭から index が一致する（parent limit=10 ≤ common limit=20）。

## 2. 見た目（レトロモダン新聞）

| 要素                                                                                    | 方針                                                                  |
| --------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| マストヘッド                                                                            | 画面冒頭に濃紺の新聞題字バナー（日付＋ワクワクするコピー）。          |
| セクション見出し                                                                        | 色付きブロック＋極太アンダーライン罫の「新聞見出し」スタイル。        |
| 記事カード                                                                              | 角丸小（`radiusSm`）＋太い濃紺ボーダー、影なし。左肩に `01/02…` の    |
| ランキング風ナンバー（ニュースピックス的）、赤いカテゴリ・キッカー、既読/未読スタンプ。 |
| トークカード                                                                            | 左に赤い極太バー＋引用符。会話の「見出し」感を出す。                  |
| 関心クラウド                                                                            | 角丸小の角ばったステッカー Chip。スコアでアンバーに着色＋細ボーダー。 |
| スタンプ                                                                                | わずかに回転（ハンコ風）させて遊び心を出す。                          |

calm content 原則は維持: 要約・本文は Noto Sans JP のまま、見出し系のみ M PLUS（Rounded系）。

## 3. 変更ファイル

- `data/parent_dashboard_repository.dart` — `fetchTodaysArticles` を doc id 付き record 返却に変更、
  `fetchViewedNewsIds` を追加。
- `application/parent_dashboard_provider.dart` — `ParentArticle` 追加、build で既読状態を結合、
  サンプルも既読/未読が混ざるよう更新。
- `presentation/parent_dashboard_screen.dart` — タブロイドUI＋スタンプ＋遷移ボタンへ全面刷新。

## 4. スコープ外 / TODO

- talkPrompts の本格生成（Cloud Functions / Gemini）は未実装のまま（既存 TODO 踏襲）。
- お気に入り（ピン）保存は未実装のまま。
- index ベースの記事突合は news_pool 並び順に依存する暫定実装。将来は newsId を
  画面間で受け渡す（GoRouter の path param 等）方式に置き換える余地あり。
