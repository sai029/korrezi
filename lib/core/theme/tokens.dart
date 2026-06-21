import 'package:flutter/material.dart';

// ─── カラー ───────────────────────────────────────────────────────────────────
abstract final class AppColors {
  // ブランド（全モード不変）— Educated Pop & Comic-Tabloid パレット
  static const brandPrimary    = Color(0xFF4361EE); // Cartoon Blue
  static const brandPrimaryInk = Color(0xFFFFFFFF);
  static const brandSecondary  = Color(0xFFFFD700); // Comic Yellow
  static const brandTertiary   = Color(0xFFE63946); // Headline Red

  // モード差し色（accent）— CMYK3原色を各モードに割り当て
  static const accentChild  = Color(0xFFFFD700); // Comic Yellow
  static const accentCommon = Color(0xFFE63946); // Headline Red
  static const accentParent = Color(0xFF1D3557); // Deep Navy

  // ニュートラル — 新聞紙・印刷物ベース
  static const ink900     = Color(0xFF0A0A0A); // near-black ink
  static const ink700     = Color(0xFF2D2D2D);
  static const ink500     = Color(0xFF6B6B6B);
  static const ink300     = Color(0xFFBBBBBB);
  static const surface    = Color(0xFFF4F1EA); // newsprint warm
  static const surfaceAlt = Color(0xFFEDE9DF);
  static const background = Color(0xFFFAF8F5); // off-white warm

  // セマンティック
  static const success = Color(0xFF2A7A2A);
  static const warning = Color(0xFFFFD700);
  static const error   = Color(0xFFE63946);
}

// ─── タイポグラフィ定数 ──────────────────────────────────────────────────────
abstract final class AppType {
  // 基準サイズ（モード倍率前）— 大胆なジャンプ率
  static const double sizeDisplay   = 40;
  static const double sizeHeadline  = 28;
  static const double sizeTitle     = 22;
  static const double sizeBodyLarge = 18;
  static const double sizeBody      = 16;
  static const double sizeLabel     = 14;
  static const double sizeCaption   = 12;

  // モード倍率
  static const double factorChild  = 1.0;
  static const double factorParent = 0.94;
  static const double factorCommon = 1.3;

  // 行間
  static const double lineHeightChild  = 1.35;
  static const double lineHeightParent = 1.5;
  static const double lineHeightCommon = 1.7;

  // 字間 — 見出しは詰め固定・本文はモード別
  static const double spacingHeadline = -0.5;
  static const double spacingChild    = 0.0;
  static const double spacingParent   = 0.1;
  static const double spacingCommon   = 0.2;
}

// ─── スペーシング ─────────────────────────────────────────────────────────────
abstract final class AppSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;
  static const double space7 = 48;
  static const double space8 = 64;
}

// ─── 角丸 — シャープ・ブロック優先（丸みより直線）─────────────────────────────
abstract final class AppRadii {
  static const double radiusSm   = 4;
  static const double radiusMd   = 6;
  static const double radiusLg   = 8;
  static const double radiusPill = 999;

  static const sm   = BorderRadius.all(Radius.circular(radiusSm));
  static const md   = BorderRadius.all(Radius.circular(radiusMd));
  static const lg   = BorderRadius.all(Radius.circular(radiusLg));
  static const pill = BorderRadius.all(Radius.circular(radiusPill));
}

// ─── ボーダー — 新聞のコマ割りを表現する太い罫線 ─────────────────────────────
abstract final class AppBorder {
  static const double thin  = 1.5;
  static const double base  = 2.5;
  static const double thick = 4.0;

  static const sideBase  = BorderSide(color: AppColors.ink900, width: base);
  static const sideThick = BorderSide(color: AppColors.ink900, width: thick);
  static const sideThin  = BorderSide(color: AppColors.ink900, width: thin);
}

// ─── エレベーション — Neo-Brutalism ソリッドオフセット（ぼかし不使用）────────
abstract final class AppElevation {
  static List<BoxShadow> elev1() => const [
        BoxShadow(color: AppColors.ink900, offset: Offset(3, 3), blurRadius: 0),
      ];

  static List<BoxShadow> elev2() => const [
        BoxShadow(color: AppColors.ink900, offset: Offset(5, 5), blurRadius: 0),
      ];

  static List<BoxShadow> elev3() => const [
        BoxShadow(color: AppColors.ink900, offset: Offset(8, 8), blurRadius: 0),
      ];
}

// ─── モーション ───────────────────────────────────────────────────────────────
abstract final class AppMotion {
  static const durFast = Duration(milliseconds: 150);
  static const durBase = Duration(milliseconds: 250);
  static const durSlow = Duration(milliseconds: 400);

  static const curveStandard = Curves.easeInOut;
  static const curveBounce   = Curves.easeOutBack;
}
