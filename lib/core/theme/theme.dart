import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// デザインシステムテーマ。
///
/// - accent はモード固定ではなく、ウィジェット側で AppColors.accentForGenre() を使う。
/// - childMode / commonMode は同一カラー、フォントサイズのみ異なる。
/// - 影なし（AppElevation は空リスト）。
class AppTheme {
  const AppTheme._();

  static ThemeData get childMode => _build(
        sizeFactor: AppType.factorChild,
        lineHeight: AppType.lineHeightChild,
        letterSpacing: AppType.spacingChild,
      );

  static ThemeData get parentMode => _build(
        sizeFactor: AppType.factorParent,
        lineHeight: AppType.lineHeightParent,
        letterSpacing: AppType.spacingParent,
      );

  // common は child と同一カラー・大きめフォント（親子で一緒に読む画面用）。
  static ThemeData get commonMode => _build(
        sizeFactor: AppType.factorCommon,
        lineHeight: AppType.lineHeightCommon,
        letterSpacing: AppType.spacingCommon,
      );

  static ThemeData _build({
    required double sizeFactor,
    required double lineHeight,
    required double letterSpacing,
  }) {
    const brand = AppColors.brandPrimary;
    // accent のデフォルト = ゴールデンアンバー（ウィジェット側でジャンル別に上書き）
    const accent = AppColors.accent;

    final colorScheme = ColorScheme.light(
      primary: brand,
      onPrimary: AppColors.brandPrimaryInk,
      secondary: accent,
      onSecondary: AppColors.ink900,
      tertiary: AppColors.accentTeal,
      error: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.ink900,
      surfaceContainerHighest: AppColors.surfaceAlt,
      outline: AppColors.ink900,
    );

    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

    final bodyTheme = GoogleFonts.notoSansJpTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink900,
      displayColor: AppColors.ink900,
    );

    final headBold  = GoogleFonts.mPlus1p(fontWeight: FontWeight.w900);
    final headSemi  = GoogleFonts.mPlus1p(fontWeight: FontWeight.w800);
    final titleBold = GoogleFonts.mPlus1p(fontWeight: FontWeight.w700);

    TextStyle h(TextStyle? b, double baseSize, TextStyle hBase) =>
        (b ?? const TextStyle()).merge(hBase).copyWith(
              fontSize: baseSize * sizeFactor,
              height: lineHeight,
              letterSpacing: AppType.spacingHeadline,
              color: AppColors.ink900,
            );

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
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.sm,
          side: AppBorder.sideBase,
        ),
      ),
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: GoogleFonts.notoSansJp(
            fontSize: AppType.sizeLabel * sizeFactor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
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
      dividerTheme: const DividerThemeData(
        color: AppColors.ink900,
        space: 1,
        thickness: AppBorder.base,
      ),
    );
  }
}
