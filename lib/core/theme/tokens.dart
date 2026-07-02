import 'package:flutter/material.dart';

// ─── カラー ───────────────────────────────────────────────────────────────────
abstract final class AppColors {
  // ── ブランド（全モード不変） ──
  /// メインカラー: ディープレッド
  static const brandPrimary    = Color(0xFFD70026);
  /// brandPrimary 上のテキスト/アイコン
  static const brandPrimaryInk = Color(0xFFF8F5F2);
  /// アクセント: ゴールデンアンバー
  static const accent          = Color(0xFFEDB83D);
  /// accent 上のテキスト
  static const accentInk       = Color(0xFF000B29);

  // ── ニュートラル（#000B29 をベース） ──
  /// ほぼ黒のネイビー（黒の代替）
  static const ink900 = Color(0xFF000B29);
  static const ink700 = Color(0xFF1C2647);
  static const ink500 = Color(0xFF5E6A8C);
  static const ink300 = Color(0xFFAEB6CC);

  // ── サーフェス（#F8F5F2 をベース） ──
  /// カード・入力欄の背景
  static const surface    = Color(0xFFF8F5F2);
  /// やや濃いサーフェス（区切り・代替背景）
  static const surfaceAlt = Color(0xFFEFEBE6);
  /// アプリ全体の背景（ほぼ白）
  static const background = Color(0xFFFDFCFB);

  // ── ジャンル別アクセント（記事カテゴリで切り替え） ──
  static const accentGreen  = Color(0xFF258039);
  static const accentYellow = Color(0xFFEDB83D); // メインアクセントと共通
  static const accentTeal   = Color(0xFF31A9B8);
  static const accentRed    = Color(0xFFD70026);  // メインカラーと共通

  /// ジャンル名から 4 色を選ぶ（ハッシュベース・再現性あり）。
  static Color accentForGenre(String genre) {
    const colors = [accentGreen, accentYellow, accentTeal, accentRed];
    return colors[genre.hashCode.abs() % colors.length];
  }

  // ── セマンティック ──
  static const success = Color(0xFF258039);
  static const warning = Color(0xFFEDB83D);
  static const error   = Color(0xFFD70026);

  /// 画像に重ねる白テキストの影（モノトーン/明るい生成画像でも輪郭を保つ）。
  static const onImageShadow = Color(0xB3000000);
}

// ─── グラデーション ───────────────────────────────────────────────────────────
abstract final class AppGradients {
  /// フィード画面の下部オーバーレイ（テキスト可読性確保）。
  ///
  /// モノトーン／白の多い生成画像でも下部のタイトル（ほぼ白）が沈むよう、
  /// 上 45% は透明のまま画像を見せ、そこから下端の濃紺 ~95% まで一気に落とす。
  /// 中段が半透明のままだと画像の白が透けて白文字と同化するため 3 ストップにする。
  static const feedOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.45, 1.0],
    colors: [Colors.transparent, Color(0x66000B29), Color(0xF2000B29)],
  );

  /// サムネイルフォールバック背景（accent → brand）。
  static const thumbnailFallback = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x99EDB83D), Color(0xCCD70026)],
  );

  /// 汎用ページ背景（ベース上の微妙なグラデーション）。
  static const pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDFCFB), Color(0xFFF8F5F2)],
  );
}

// ─── タイポグラフィ定数 ──────────────────────────────────────────────────────
abstract final class AppType {
  static const double sizeDisplay   = 40;
  static const double sizeHeadline  = 28;
  static const double sizeTitle     = 22;
  static const double sizeBodyLarge = 18;
  static const double sizeBody      = 16;
  static const double sizeLabel     = 14;
  static const double sizeCaption   = 12;

  static const double factorChild  = 1.0;
  static const double factorParent = 0.94;
  static const double factorCommon = 1.3;

  static const double lineHeightChild  = 1.35;
  static const double lineHeightParent = 1.5;
  static const double lineHeightCommon = 1.7;

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

// ─── 角丸 ─────────────────────────────────────────────────────────────────────
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

// ─── ボーダー ─────────────────────────────────────────────────────────────────
abstract final class AppBorder {
  static const double thin  = 1.5;
  static const double base  = 2.5;
  static const double thick = 4.0;

  static const sideBase  = BorderSide(color: AppColors.ink900, width: base);
  static const sideThick = BorderSide(color: AppColors.ink900, width: thick);
  static const sideThin  = BorderSide(color: AppColors.ink900, width: thin);
}

// ─── エレベーション（影なし） ──────────────────────────────────────────────────
abstract final class AppElevation {
  static List<BoxShadow> elev1() => const [];
  static List<BoxShadow> elev2() => const [];
  static List<BoxShadow> elev3() => const [];
}

// ─── モーション ───────────────────────────────────────────────────────────────
abstract final class AppMotion {
  static const durFast = Duration(milliseconds: 150);
  static const durBase = Duration(milliseconds: 250);
  static const durSlow = Duration(milliseconds: 400);

  static const curveStandard = Curves.easeInOut;
  static const curveBounce   = Curves.easeOutBack;
}
