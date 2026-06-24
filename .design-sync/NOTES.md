# Design Sync Notes — Flutter Comic Tabloid DS

## Setup

This is a **Flutter (Dart) → React** conversion. The project has no native
JavaScript component library, so a companion npm package was created at
`design-system-web/` that mirrors the Flutter design system.

- Flutter tokens → CSS custom properties in `design-system-web/src/index.css`
- Flutter widgets → React components in `design-system-web/src/`
- Build: `cd design-system-web && npm install && npm run build` (uses tsup)
- Converter entry: `design-system-web/dist/index.mjs` (ESM, tsup output)
- Node modules: `design-system-web/node_modules`

## Re-sync command

```bash
cd design-system-web && npm run build && cd ..
node .ds-sync/package-build.mjs \
  --config design-sync.config.json \
  --node-modules design-system-web/node_modules \
  --entry design-system-web/dist/index.mjs \
  --out ./ds-bundle
node .ds-sync/package-validate.mjs ./ds-bundle
```

## Font handling

Google Fonts (M PLUS 1p + Noto Sans JP) are loaded via remote `@import` from
the CSS. Set `runtimeFontPrefixes` in config to suppress `[FONT_MISSING]`.
These fonts are NOT shipped in the bundle — they load from Google's CDN at runtime.
In headless screenshots, fallback system fonts appear; the real claude.ai/design
environment loads the fonts correctly.

## Components

| Component | Flutter original | Notes |
|---|---|---|
| BouncyTap | `shared/widgets/bouncy_tap.dart` | CSS scale+bounce animation |
| FeedThumbnail | `shared/widgets/feed_thumbnail.dart` | Image with fallback |
| FuriganaText | `shared/widgets/furigana_text.dart` | HTML `<ruby>` elements |
| CategoryBadge | inline in `child_feed_screen.dart` | Genre hash-based color |
| FeedPage | `_FeedPage` in `child_feed_screen.dart` | Full-height immersive card |
| NavigationDrawer | `shared/widgets/app_drawer.dart` | Side nav |

## FuriganaText format

The component expects `〔漢字｜よみ〕` format (not just `〔漢字〕`).
Preview text must include readings for ruby to display. Without `｜reading`,
the brackets are rendered as plain text.

## tsconfig target

Must be ES2020 or later (for `String.prototype.matchAll`). Earlier targets
cause a TypeScript error in `FuriganaText.tsx`.

## Re-sync risks

- **Ruby format**: if Flutter app data format changes (e.g. different bracket
  style), `FuriganaText` regex needs updating.
- **Font availability**: previews in headless show fallback fonts; this is
  expected and non-blocking.
- **Design token drift**: if Flutter `tokens.dart` gains new values, update
  `design-system-web/src/tokens.ts` and `src/index.css` manually.
- **Playwright version**: installed playwright@1228 (Chrome for Testing 149.0.7827.55)
  to `C:\Users\20t052\AppData\Local\ms-playwright\chromium-1228`. Future syncs
  may need to re-verify if the local playwright install is still present.
