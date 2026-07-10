import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// ログイン画面の背景「せかいのかけら」。
///
/// 背景を別の装飾で飾るのではなく、ロゴ自身の語彙（両端が丸いバーとドット、
/// 赤 #FD5251 / スレート #879BA5）を分解して紙面に漉き込む。画面端ほど密に、
/// 中央は空けることで「ニュースのかけらが中央の完成形（ロゴ）へ集まりつつある」
/// 構図をつくる。ニュースの断片＝せかいのかけら。
///
/// UI（ロゴ・ボタン）は中央に配置されるため、モチーフは四隅・両端に寄せて
/// 可読性を損なわない。
class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.pageBackground),
      child: CustomPaint(
        painter: _WorldPiecesPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _WorldPiecesPainter extends CustomPainter {
  const _WorldPiecesPainter();

  // ロゴ原本の色（tokens.dart に定義）
  static const _slate = AppColors.logoSlate;
  static const _red = AppColors.logoRed;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    void bar(double x, double y, double bw, double bh, Color c, double a) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, bw, bh),
          Radius.circular(math.min(bw, bh) / 2),
        ),
        Paint()..color = c.withValues(alpha: a),
      );
    }

    void dot(double x, double y, double r, Color c, double a) => canvas
        .drawCircle(Offset(x, y), r, Paint()..color = c.withValues(alpha: a));

    // 上端（左上はロゴの2連バーのエコー。画面外へ少し逃して「流れ込み」を出す）
    bar(-0.10 * w, 0.070 * h, 0.36 * w, 0.055 * w, _slate, 0.16);
    bar(0.10 * w, 0.070 * h + 0.075 * w, 0.05 * w, 0.16 * w, _slate, 0.12);
    dot(0.86 * w, 0.060 * h, 0.028 * w, _slate, 0.18); // ロゴの2ドットのエコー
    dot(0.93 * w, 0.105 * h, 0.016 * w, _slate, 0.14);
    bar(0.78 * w, 0.190 * h, 0.34 * w, 0.050 * w, _slate, 0.12);

    // 中段（UI の外側だけ。興味の芽＝アンバーを1点だけ灯す）
    dot(0.12 * w, 0.310 * h, 0.020 * w, AppColors.accent, 0.75);
    bar(-0.06 * w, 0.560 * h, 0.22 * w, 0.050 * w, _slate, 0.12);
    bar(0.90 * w, 0.520 * h, 0.05 * w, 0.14 * w, _slate, 0.13);
    dot(0.88 * w, 0.350 * h, 0.014 * w, AppColors.accentTeal, 0.45);

    // 下端（ロゴ最下段の2本バーのエコー＋赤は画面全体で1点だけ）
    bar(0.06 * w, 0.840 * h, 0.20 * w, 0.050 * w, _slate, 0.15);
    bar(0.06 * w, 0.840 * h + 0.075 * w, 0.13 * w, 0.050 * w, _slate, 0.11);
    bar(0.80 * w, 0.780 * h, 0.13 * w, 0.048 * w, _red, 0.70);
    bar(0.72 * w, 0.880 * h, 0.34 * w, 0.055 * w, _slate, 0.14);
  }

  @override
  bool shouldRepaint(covariant _WorldPiecesPainter oldDelegate) => false;
}
