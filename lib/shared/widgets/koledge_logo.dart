import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/tokens.dart';

/// アプリのブランドロゴ「コレッジ」。
///
/// 「子ども × knowledge」を由来とする造語。ディープレッドの角丸バッジに
/// ゴールドの好奇心のきらめき（sparkle）を重ねたマークで、
/// 発見のワクワクを表す。
///
/// [size] はマーク（バッジ）の一辺。[showWordmark] を true にすると
/// マークの下に「コレッジ」の文字を縦に添える。
class KoledgeLogo extends StatelessWidget {
  const KoledgeLogo({
    super.key,
    this.size = 64,
    this.showWordmark = false,
  });

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = _KoledgeMark(size: size);
    if (!showWordmark) return mark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: size * 0.28),
        Text(
          'コレッジ',
          style: GoogleFonts.mPlusRounded1c(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            color: AppColors.ink900,
            letterSpacing: size * 0.02,
          ),
        ),
      ],
    );
  }
}

/// ブランドバッジ本体（角丸レッド + ゴールドのきらめき）。
class _KoledgeMark extends StatelessWidget {
  const _KoledgeMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE21238), AppColors.brandPrimary],
        ),
        borderRadius: BorderRadius.all(Radius.circular(size * 0.28)),
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          size: size * 0.56,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
