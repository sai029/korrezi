# デザインシステム設計書

> 最終更新: 2026-06-21
> この文書は UI 実装の単一の指針（source of truth）。実装は末尾の「実装チェックリスト」に従う。

## 0. このアプリのデザイン方向

子ども 6〜10 歳と保護者が一緒に使う、ニュース発見の学習アプリ。
方向性は **「あそべる・元気」** ＋ **「統一ブランド ＋ モード差し色」**。

### デザイン原則
1. **Playful chrome, calm content（外枠は楽しく、本文は穏やかに）**
   バッジ・ボタン・フィードなどの UI 外枠は元気に弾ませる。一方、Common View（親子で長文を読む画面）と
   Parent の要約本文は、**可読性を最優先**して落ち着かせる。元気さと読みやすさの衝突をこの原則で解消する。
2. **ひとつのブランド、3つの表情**
   ブランド色（グレープ・パープル）は全モードで不変。モードごとに変えるのは **accent（差し色）だけ**。
3. **大きく・丸く・触りやすく**
   子どもの指で押せるよう最小タップ領域 48dp。大きな角丸で親しみを出す。
4. **ぽよん、と返す**
   操作に弾むフィードバック（押下で縮んで overshoot で戻る）を与え、楽しさを演出する。
5. **ルビは一級市民**
   `〔漢字｜よみ〕` 本文の可読性・行間を最優先する。装飾より読みやすさ。

---

## 1. カラートークン

### 1-1. ブランド（全モード共通・不変）
| トークン | 値 | 用途 |
|---|---|---|
| `brandPrimary` | `#6C5CE7` グレープ・パープル | 主要アクション / アプリ識別 / Primary ボタン |
| `brandPrimaryInk` | `#FFFFFF` | brandPrimary 上の文字・アイコン |
| `brandSecondary` | `#FFC93C` サンシャイン黄 | 強調・お気に入り（♥）・装飾の差し色 |
| `brandTertiary` | `#FF6B9D` コーラルピンク | 補助アクセント・ハイライト |

### 1-2. モード差し色（accent）
ブランド色は固定のまま、チップ／選択状態／フィードのグラデーション等を以下の accent で色づける。
| モード | デバイス・体験 | `accent` | 意図 |
|---|---|---|---|
| **Child** | タブレット縦・没入フィード | `#4FC3F7` スカイ | 活発・エネルギー |
| **Common** | タブレット横・親子読書 | `#2EC4B6` ティール | 穏やか・集中（彩度を抑え可読性寄り） |
| **Parent** | スマホ縦・会話喚起 | `#FF8A65` コーラル | 温かみ・対話 |

### 1-3. ニュートラル（やや暖色寄りで親しみ）
| トークン | 値 | 用途 |
|---|---|---|
| `ink900` | `#1F1B2E` | 本文テキスト（純黒を避け眼に優しく） |
| `ink700` | `#4A4458` | サブテキスト |
| `ink500` | `#847D96` | キャプション・プレースホルダ |
| `ink300` | `#C9C4D6` | ボーダー・分割線 |
| `surface` | `#FFFFFF` | カード面 |
| `surfaceAlt` | `#F2EFF9` | 選択前の淡い面 |
| `background` | `#FAF8FF` | 画面背景（淡いラベンダー） |

### 1-4. セマンティック
| トークン | 値 |
|---|---|
| `success` | `#2ED47A` |
| `warning` | `#FFB02E` |
| `error` | `#FF5C5C` |
| `info` | `= brandPrimary` |

### 1-5. ColorScheme への対応（実装ガイド）
`ColorScheme.fromSeed` の自動生成をやめ、ブランド固定 + accent 可変で明示構成する。
```
primary            = brandPrimary
onPrimary          = brandPrimaryInk
secondary          = accent（モード差し色）
tertiary           = brandTertiary
surface            = surface
onSurface          = ink900
surfaceContainerHighest = surfaceAlt
outline            = ink300
error              = error
```

---

## 2. タイポグラフィ

### 2-1. フォント
| 役割 | フォント | 理由 |
|---|---|---|
| 見出し / Display | **M PLUS Rounded 1c** | 丸ゴシックで「あそべる・元気」を担う（google_fonts 提供） |
| 本文 / UI / ルビ | **Noto Sans JP** | 可読性。既存踏襲・日本語ルビ対応 |

### 2-2. 型スケール（モード倍率を掛ける前の基準値, px）
| ロール | size | weight | font |
|---|---|---|---|
| display | 32 | Bold (700) | Rounded |
| headline | 24 | Bold (700) | Rounded |
| title | 20 | SemiBold (600) | Rounded |
| bodyLarge | 18 | Regular (400) | Noto Sans JP |
| body | 16 | Regular (400) | Noto Sans JP |
| label | 14 | Medium (500) | Noto Sans JP |
| caption | 12 | Regular (400) | Noto Sans JP |

> Rounded は見出し系のみ。本文・要約・ルビには使わない（calm content 原則）。

### 2-3. モード別メトリクス（既存踏襲）
| モード | sizeFactor | lineHeight | letterSpacing |
|---|---|---|---|
| Child | 1.0 | 1.4 | 0.0 |
| Parent | 0.94 | 1.5 | 0.1 |
| Common | 1.375 | 1.8 | 0.2 |

最終フォントサイズ ＝ 基準 size × sizeFactor。例: Common の headline ＝ 24 × 1.375 ≒ 33px。

### 2-4. ルビ（FuriganaText）
- 読み（ふりがな）＝ 親文字の **50%** サイズ、`height: 1.0`
- markup: `〔漢字｜よみ〕`（例: `〔環境｜かんきょう〕`）
- Common の本文では行間 1.8 を厳守（ルビが乗っても窮屈にしない）

---

## 3. スペーシング・角丸・影・モーション

### 3-1. スペーシング（4pt ベース）
場当たり値（12/16/24/32）を以下のトークンに置換する。
| トークン | px | 主な用途 |
|---|---|---|
| `space1` | 4 | 微小な隙間 |
| `space2` | 8 | アイコンとテキスト間 |
| `space3` | 12 | チップ内 padding |
| `space4` | 16 | カード内 padding / リスト項目 |
| `space5` | 24 | フィード記事の padding |
| `space6` | 32 | リーダー本文の padding |
| `space7` | 48 | セクション間 |
| `space8` | 64 | 画面端の大きな余白 |

### 3-2. 角丸（あそべる＝大きめ）
| トークン | px | 適用 |
|---|---|---|
| `radiusSm` | 12 | 小要素 |
| `radiusMd` | 20 | 入力欄 |
| `radiusLg` | 28 | カード |
| `radiusPill` | 999 | ボタン・チップ・バッジ |

### 3-3. エレベーション（やわらかい・ブランド色を帯びた影）
Material のハード影でなく、淡く色づいた soft shadow を使う。
| トークン | offset Y | blur | color |
|---|---|---|---|
| `elev1` | 2 | 8 | brandPrimary @ 8% |
| `elev2` | 4 | 16 | brandPrimary @ 10% |
| `elev3` | 8 | 24 | brandPrimary @ 12% |

### 3-4. モーション（ぽよん）
| トークン | 値 |
|---|---|
| `durFast` | 150ms |
| `durBase` | 250ms |
| `durSlow` | 400ms（テーマ遷移・据置） |
| `curveStandard` | `Curves.easeInOut` |
| `curveBounce` | `Curves.easeOutBack`（overshoot） |

- **押下フィードバック**: tap 時に `scale 0.96` → `easeOutBack` で戻す。共通ラッパー `BouncyTap` を用意。
- バッジ登場・お気に入りタップにも `curveBounce` を適用。
- フィードのページ送り物理は既存 `_FastPageScrollPhysics` を維持（軽いスワイプで素早くスナップ）。

---

## 4. コンポーネント仕様

### Buttons
| 種類 | 仕様 |
|---|---|
| Primary | filled `brandPrimary` / 文字 `brandPrimaryInk` / `radiusPill` / 高さ 52（Child・Common は 56）/ `BouncyTap` |
| Tonal | 背景 accent @淡 / 文字 ink900 / `radiusPill` |
| Text | 文字 brandPrimary / 装飾なし |

### Card
`surface` / `radiusLg` / `elev1` / 内 padding `space4`。

### Chip / Badge（ステッカー風）
`radiusPill` / 背景は accent を淡くティント / 細い白縁 ＋ `elev1` で「貼った」質感。
Child フィードのカテゴリバッジは `#` プレフィックス（例: `#サッカー`）。

### FeedPage（Child・没入フィード）
```
[全面画像 or accentグラデ＋アイコン]
  └─ 下部グラデ（transparent → ink900 @85%）
      └─ padding space5
          ├─ Badge（#カテゴリ・ステッカー風）
          ├─ Title（display, Rounded, brandPrimaryInk, bold）
          ├─ Tagline（bodyLarge, 白 @70%）
          └─ Actions（「よんでみる」Primary ＋ ♥ IconButton, BouncyTap）
```
背景は黒ベースで没入感を維持。メニューは左上に白アイコンで控えめに。

### InterestCloud（Parent）
スコア連動サイズ（`12 + score × 0.12` px）を維持しつつ、ステッカー Chip 化。
背景は `surfaceAlt → accent` をスコア（0〜100）で補間。

### TalkPromptCard / ArticleSummaryCard（Parent）
Card 仕様準拠。**要約本文は body（Noto Sans JP）・calm**。Rounded は使わない。
TalkPrompt は会話アイコン ＋ プロンプト ＋ ピン（保存）。

### NavigationGrid ＋ ArticleReader（Common）
- グリッドカード: `radiusLg` / 選択時背景 accent / `elev1`。
- **ArticleReader は calm content 原則を厳守**: 背景 `surface`、padding `space6`、
  FuriganaText の行間 1.8、見出しのみ Rounded・本文は Noto Sans JP。

### AppDrawer / LoginScreen
- Drawer ヘッダー背景 `brandPrimary`、ロゴは Rounded。
- Login: 中央 `auto_awesome` アイコン（brandPrimary, 64px）、ロゴ Rounded、Google/ゲストボタンは Primary 仕様。

---

## 5. 画像アートディレクション（Imagen）

カテゴリサムネは Imagen で生成する。**全画像のトーンを揃える**ため、以下のプロンプト規約を固定する。

### アートスタイル（プロンプトに必ず含める要素）
- フラット／ベクター調・明るく彩度高め・丸みのある形・やわらかい影
- **文字を一切含めない**（タイトルはアプリ側でオーバーレイする）
- 子ども安全: 写実的な人物・暴力的／恐怖的表現を避ける
- 背景は淡い単色〜ゆるいグラデーション

### 構図・比率
- 主題は 1 つだけ・中央寄せ・周囲に余白（上にテキストを重ねられる空間を残す）
- アスペクト比: フィード ＝ 縦長（9:16 目安）/ グリッド ＝ 横（4:3 目安）

### プロンプト雛形（例）
```
A flat vector illustration of {topic}, bright cheerful colors, rounded soft shapes,
soft shadows, simple solid pastel background, centered single subject with empty space
around it, no text, child-friendly, safe, cute. Aspect ratio {9:16 | 4:3}.
```

### フォールバック（画像が無い／生成失敗時）
`FeedThumbnail` を拡張し、accent グラデーション ＋ カテゴリアイコンを表示する。
（現状は accent グラデのみ。アイコン重ねを追加する。）

> Imagen 生成パイプライン（Cloud Functions）の実装は**別タスク（バックエンド）**。
> 本書はアートディレクション（プロンプト規約）と表示／フォールバック挙動のみを定義する。

---

## 6. 実装チェックリスト（Sonnet 実装フェーズ）

順序を守って段階的に進める。各ステップ後に `flutter analyze` → No issues を確認。

- [ ] **1. `lib/core/theme/tokens.dart`（新規）**
      `AppColors` / `AppType` / `AppSpacing` / `AppRadii` / `AppElevation` / `AppMotion` を
      `const` で定義（トークンの単一の出所）。本書 §1〜§3 の値をそのまま写す。
- [ ] **2. `lib/core/theme/theme.dart` 刷新**
      `_build` を「brandPrimary 固定 ＋ accent 可変」へ。`ColorScheme` を明示構成（§1-5）。
      display 系に `M PLUS Rounded 1c`、body 系に Noto Sans JP を割当て。
      角丸・カード・ボタン・チップの各 Theme をトークン参照に。
- [ ] **3. `lib/shared/widgets/bouncy_tap.dart`（新規）**
      押下 `scale 0.96` → `easeOutBack` で戻す共通ラッパー。Primary ボタン・バッジ・♥ に適用。
- [ ] **4. `lib/shared/widgets/feed_thumbnail.dart` 拡張**
      フォールバックを accent グラデ ＋ カテゴリアイコンへ。
- [ ] **5. 各画面をトークンへ寄せる（段階的）**
      child_feed / common_view / parent_dashboard / login / app_drawer の
      色・余白・角丸・フォントをトークン参照に置換。Common の本文は calm content 厳守。
- [ ] **6. `pubspec.yaml`**
      フォントは google_fonts 動的読込のため追加依存なし（M PLUS Rounded 1c も同梱）。

### 検証（実装後）
1. `flutter analyze` → No issues
2. 実機／Chrome で 3 モードを巡回し確認:
   (a) ブランド色の一貫性　(b) モード差し色の切替　(c) ボタンの弾み
   (d) Common 本文の可読性（行間 1.8・余白）　(e) サムネのフォールバック（accent グラデ＋アイコン）
3. 横 → 縦の向き切替で 400ms テーマ遷移が滑らかか確認

### スコープ外（本書では決めない）
- Imagen 生成パイプラインの実装（プロンプト規約のみ定義）
- ダークモード（将来。トークン構造は拡張できる形にしておく）
- 各アニメーションの実装細部（原則とトークンのみ。画面ごとは実装時に決定）
