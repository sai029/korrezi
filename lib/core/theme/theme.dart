import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Educated Pop & Comic-Tabloid デザインシステム。
///
/// - brandPrimary(Cartoon Blue) は全モード不変のアクションカラー。
/// - accent（差し色）はモードごとに CMYK3原色から割り当て。
/// - 見出し: M PLUS 1p Black / 本文: Noto Sans JP。
/// - Shadow より Border: ぼかしシャドウ不使用、ソリッドオフセット + 太い罫線。
class AppTheme {
  const AppTheme._();

  static ThemeData get childMode => _build(
        accent: AppColors.accentChild,
        sizeFactor: AppType.factorChild,
        lineHeight: AppType.lineHeightChild,
        letterSpacing: AppType.spacingChild,
      );

  static ThemeData get parentMode => _build(
        accent: AppColors.accentParent,
        sizeFactor: AppType.factorParent,
        lineHeight: AppType.lineHeightParent,
        letterSpacing: AppType.spacingParent,
      );

  static ThemeData get commonMode => _build(
        accent: AppColors.accentCommon,
        sizeFactor: AppType.factorCommon,
        lineHeight: AppType.lineHeightCommon,
        letterSpacing: AppType.spacingCommon,
      );

  static ThemeData _build({
    required Color accent,
    required double sizeFactor,
    required double lineHeight,
    required double letterSpacing,
  }) {
    const brand = AppColors.brandPrimary;
    final colorScheme = ColorScheme.light(
      primary: brand,
      onPrimary: AppColors.brandPrimaryInk,
      secondary: accent,
      onSecondary: AppColors.ink900,
      tertiary: AppColors.brandTertiary,
      error: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.ink900,
      surfaceContainerHighest: AppColors.surfaceAlt,
      outline: AppColors.ink900,
    );

    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

    // 本文・UI: Noto Sans JP
    final bodyTheme = GoogleFonts.notoSansJpTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink900,
      displayColor: AppColors.ink900,
    );

    // 見出し: M PLUS 1p（Angular — 新聞ゴシック）
    final headBold  = GoogleFonts.mPlus1p(fontWeight: FontWeight.w900);
    final headSemi  = GoogleFonts.mPlus1p(fontWeight: FontWeight.w800);
    final titleBold = GoogleFonts.mPlus1p(fontWeight: FontWeight.w700);

    // 見出し系: 詰め字間（spacingHeadline）固定
    TextStyle h(TextStyle? b, double baseSize, TextStyle hBase) =>
        (b ?? const TextStyle()).merge(hBase).copyWith(
              fontSize: baseSize * sizeFactor,
              height: lineHeight,
              letterSpacing: AppType.spacingHeadline,
              color: AppColors.ink900,
            );

    // 本文系: モード字間
    TextStyle body(TextStyle? b, double baseSize) =>
        (b ?? const TextStyle()).copyWith(
          fontSize: baseSize * sizeFactor,
          height: lineHeight,
          letterSpacing: letterSpacing,
        );

    final textTheme = bodyTheme.copyWith(
      displayLarge:   h(bodyTheme.displayLarge,   AppType.sizeDisplay,  headBold),
      displayMedium:  h(bodyTheme.displayMedium,  AppType.sizeDisplay,  headBold),
      displaySmall:   h(bodyTheme.displaySmall,   AppType.sizeDisplay,  headBold),
      headlineLarge:  h(bodyTheme.headlineLarge,  AppType.sizeHeadline, headBold),
      headlineMedium: h(bodyTheme.headlineMedium, AppType.sizeHeadline, headSemi),
      headlineSmall:  h(bodyTheme.headlineSmall,  AppType.sizeHeadline, headSemi),
      titleLarge:     h(bodyTheme.titleLarge,     AppType.sizeTitle,    titleBold),
      titleMedium:    h(bodyTheme.titleMedium,    AppType.sizeTitle,    titleBold),
      titleSmall:     h(bodyTheme.titleSmall,     AppType.sizeTitle,    titleBold),
      bodyLarge:      body(bodyTheme.bodyLarge,   AppType.sizeBodyLarge),
      bodyMedium:     body(bodyTheme.bodyMedium,  AppType.sizeBody),
      bodySmall:      body(bodyTheme.bodySmall,   AppType.sizeCaption),
      labelLarge:     body(bodyTheme.labelLarge,  AppType.sizeLabel),
      labelMedium:    body(bodyTheme.labelMedium, AppType.sizeLabel),
      labelSmall:     body(bodyTheme.labelSmall,  AppType.sizeCaption),
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      // カード: newsprint surface + シャープ角 + ソリッドボーダー
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.sm,
          side: AppBorder.sideBase,
        ),
      ),
      // FilledButton: brand blue / シャープ角 / 高さ52 / 太字
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: AppColors.brandPrimaryInk,
          minimumSize: const Size(0, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.sm),
          textStyle: GoogleFonts.mPlus1p(
            fontSize: AppType.sizeLabel * sizeFactor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: GoogleFonts.notoSansJp(
            fontSize: AppType.sizeLabel * sizeFactor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // Chip: シャープ角 + ソリッドボーダー
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.sm),
        backgroundColor: accent.withValues(alpha: 0.12),
        labelStyle: GoogleFonts.notoSansJp(
          fontSize: AppType.sizeCaption * sizeFactor,
          fontWeight: FontWeight.w600,
          color: AppColors.ink900,
        ),
        side: AppBorder.sideThin,
      ),
      // AppBar: 新聞マストヘッド（ near-black）
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ink900,
        foregroundColor: AppColors.brandPrimaryInk,
        elevation: 0,
        titleTextStyle: headBold.copyWith(
          fontSize: AppType.sizeTitle * sizeFactor,
          color: AppColors.brandPrimaryInk,
          letterSpacing: AppType.spacingHeadline,
        ),
      ),
      // Divider: 太い黒罫線（新聞コマ割り）
      dividerTheme: const DividerThemeData(
        color: AppColors.ink900,
        space: 1,
        thickness: AppBorder.base,
      ),
    );
  }
}

/// 向きの変化を物理トリガーとして検知し、テーマを滑らかに切り替えるラッパー。
class OrientationResponsiveTheme extends StatelessWidget {
  const OrientationResponsiveTheme({
    super.key,
    required this.child,
    required this.portraitTheme,
    this.duration = AppMotion.durSlow,
  });

  final ThemeData portraitTheme;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final theme = orientation == Orientation.landscape
            ? AppTheme.commonMode
            : portraitTheme;
        return AnimatedTheme(
          data: theme,
          duration: duration,
          curve: AppMotion.curveStandard,
          child: child,
        );
      },
    );
  }
}
