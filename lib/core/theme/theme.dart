import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// アプリのテーマ定義と、向き連動の動的テーマ切替。
///
/// - Child Mode (タブレット縦) / Parent Mode (スマホ縦): 各モード専用テーマ
/// - Common Mode (タブレット横): フォント・行間を拡大して親子同時閲覧をサポート
///
/// 日本語(ルビ本文)を扱うため Noto Sans JP を基調にする。
class AppTheme {
  const AppTheme._();

  // ----- シード色（モードごとに雰囲気を変える）-----
  static const Color _childSeed = Color(0xFF4FC3F7); // 明るいシアン: 子ども向け
  static const Color _parentSeed = Color(0xFFFF8A65); // 温かいコーラル: 会話喚起
  static const Color _commonSeed = Color(0xFF66BB6A); // 落ち着いた緑: 同時閲覧

  /// Child Mode（タブレット・縦）: 没入フィード向け。
  static ThemeData get childMode => _build(
        seed: _childSeed,
        baseFontSize: 16,
        lineHeight: 1.4,
        letterSpacing: 0.0,
      );

  /// Parent Mode（スマホ・縦）: 落ち着いた読みやすさ。
  static ThemeData get parentMode => _build(
        seed: _parentSeed,
        baseFontSize: 15,
        lineHeight: 1.5,
        letterSpacing: 0.1,
      );

  /// Common Mode（タブレット・横）: フォント・行間を拡大（親子同時閲覧）。
  static ThemeData get commonMode => _build(
        seed: _commonSeed,
        baseFontSize: 22,
        lineHeight: 1.8,
        letterSpacing: 0.2,
      );

  static ThemeData _build({
    required Color seed,
    required double baseFontSize,
    required double lineHeight,
    required double letterSpacing,
  }) {
    final colorScheme = ColorScheme.fromSeed(seedColor: seed);
    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

    // Noto Sans JP をベースに、サイズ・行間・字間をモードに合わせてスケール。
    final textTheme = GoogleFonts.notoSansJpTextTheme(base.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return base.copyWith(
      textTheme: _applyMetrics(
        textTheme,
        baseFontSize / 16.0,
        lineHeight,
        letterSpacing,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(baseFontSize),
        ),
      ),
    );
  }

  /// フォントサイズ(factor)・行間(height)・字間(letterSpacing)を TextTheme 全体へ
  /// 適用する。fontSize が null のスタイルはサイズ拡縮をスキップ（null安全）。
  static TextTheme _applyMetrics(
    TextTheme t,
    double factor,
    double height,
    double letterSpacing,
  ) {
    TextStyle? s(TextStyle? style) => style?.copyWith(
          fontSize: style.fontSize == null ? null : style.fontSize! * factor,
          height: height,
          letterSpacing: letterSpacing,
        );
    return t.copyWith(
      displayLarge: s(t.displayLarge),
      displayMedium: s(t.displayMedium),
      displaySmall: s(t.displaySmall),
      headlineLarge: s(t.headlineLarge),
      headlineMedium: s(t.headlineMedium),
      headlineSmall: s(t.headlineSmall),
      titleLarge: s(t.titleLarge),
      titleMedium: s(t.titleMedium),
      titleSmall: s(t.titleSmall),
      bodyLarge: s(t.bodyLarge),
      bodyMedium: s(t.bodyMedium),
      bodySmall: s(t.bodySmall),
      labelLarge: s(t.labelLarge),
      labelMedium: s(t.labelMedium),
      labelSmall: s(t.labelSmall),
    );
  }
}

/// 向きの変化を物理トリガーとして検知し、テーマを滑らかに切り替えるラッパー。
///
/// 横向き(landscape)になると Common Mode テーマへ、縦向きでは [portraitTheme] へ
/// `AnimatedTheme` でアニメーション遷移する（フォント・行間が滑らかに拡縮）。
class OrientationResponsiveTheme extends StatelessWidget {
  const OrientationResponsiveTheme({
    super.key,
    required this.child,
    required this.portraitTheme,
    this.duration = const Duration(milliseconds: 400),
  });

  /// 縦向き時に適用するテーマ（Child Mode / Parent Mode）。
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
          curve: Curves.easeInOut,
          child: child,
        );
      },
    );
  }
}
