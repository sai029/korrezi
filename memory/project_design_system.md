---
name: project-design-system
description: デザインシステム実装状況とClaude Design同期情報（2026-06-24更新）
metadata:
  type: project
---

Flutter アプリのデザインシステムを Claude Design に同期済み（2026-06-24）。

**Why:** claude.ai/design から実際のブランドコンポーネントでUIデザインできるようにするため。

**How to apply:** 再同期する際は `.design-sync/NOTES.md` を先に読むこと。

## 実装済み内容

- `lib/core/theme/tokens.dart` — AppColors / AppType / AppSpacing / AppRadii / AppBorder / AppMotion
- `lib/core/theme/theme.dart` — AppTheme (child / parent / common 3モード)
- `lib/shared/widgets/bouncy_tap.dart` — BouncyTap (scale 0.96 + easeOutBack)
- `lib/shared/widgets/feed_thumbnail.dart` — FeedThumbnail
- `lib/shared/widgets/furigana_text.dart` — FuriganaText
- `lib/shared/widgets/app_drawer.dart` — AppDrawer

## Claude Design 同期

- プロジェクト: `Flutter App — Comic Tabloid DS`
- projectId: `95d81b9d-ecfe-4f56-9799-1020ae417e4b`
- URL: https://claude.ai/design/p/95d81b9d-ecfe-4f56-9799-1020ae417e4b
- コンパニオン npm パッケージ: `design-system-web/` (Flutter tokens → React)
- 同期済みコンポーネント: BouncyTap, FeedThumbnail, FuriganaText, CategoryBadge, FeedPage, NavigationDrawer
- 検証: 全6件レンダリングクリーン、bad=0
