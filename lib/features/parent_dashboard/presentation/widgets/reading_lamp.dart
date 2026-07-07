import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// 「きょうの よみのランプ」ヒーロー。
///
/// 当日記事の既読率([ratio], 0.0–1.0)を、一つのランプの「明るさ」で表現する。
/// 読むほど暖色（アンバー）の灯りが強くなり、光の輪とレイが広がる。
/// レトロ新聞調（フラット・極太ネイビー罫）に合わせ、光もにじみではなく
/// フラットな同心円＋直線レイ（コミック的な光の表現）で描く。
/// Masthead 直下に置くことを想定。
class ReadingLampHero extends StatelessWidget {
  const ReadingLampHero({
    super.key,
    required this.ratio,
    required this.readCount,
    required this.totalCount,
  });

  /// 当日の既読率(0.0–1.0)。ランプの明るさそのもの。
  final double ratio;

  /// 既読件数（スタンプ表示用）。
  final int readCount;

  /// 当日記事の総数（スタンプ表示用）。
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.sm,
        border: Border.fromBorderSide(AppBorder.sideThick),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 12, height: 24, color: AppColors.accent),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  'きょうのランプ',
                  style: textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              _ReadRatioStamp(readCount: readCount, totalCount: totalCount),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          // 既読率へ向けて一度だけ明るくなるアニメーション。
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
            duration: AppMotion.durSlow,
            curve: AppMotion.curveStandard,
            builder: (context, glow, _) => SizedBox(
              height: 220,
              width: double.infinity,
              child: CustomPaint(painter: _LampPainter(glow: glow)),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            _caption(),
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.ink700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _caption() {
    if (totalCount == 0) return 'きょうは まだ きじが ないよ。';
    if (readCount >= totalCount) return 'いちばん あかるい！ ぜんぶ よんだね。';
    final remaining = totalCount - readCount;
    return 'あと $remaining きじで ピカピカ！';
  }
}

/// 既読率のハンコ風スタンプ（画面の _ReadStamp と同系のトーン）。
class _ReadRatioStamp extends StatelessWidget {
  const _ReadRatioStamp({required this.readCount, required this.totalCount});

  final int readCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final full = totalCount > 0 && readCount >= totalCount;
    final color = full ? AppColors.brandPrimary : AppColors.ink900;
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.sm,
          border: Border.all(color: color, width: AppBorder.base),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              full ? Icons.lightbulb : Icons.lightbulb_outline,
              size: 16,
              color: color,
            ),
            const SizedBox(width: AppSpacing.space1),
            Text(
              '$readCount/$totalCount よんだ',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: AppType.sizeCaption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 既読率[glow](0–1)を「明るさ」に写像して一つのランプを描く。
///
/// glow=0 で消灯（灰色のフィラメント・光なし）、glow=1 で最大光量
/// （暖色の光の輪とレイが最大）。灯りの色はアンバー（[AppColors.accent]）を軸に、
/// わずかに赤へ寄せた白熱色。
class _LampPainter extends CustomPainter {
  _LampPainter({required this.glow});

  /// 明るさ(0–1)。既読率をそのまま渡す。
  final double glow;

  // ── 暖色（すべて design token から導出）──
  /// 灯りの基調（ゴールデンアンバー）。
  static const _warm = AppColors.accent;

  /// 外側の光＝赤みを足した白熱オレンジ。
  static final _warmDeep = Color.lerp(
    AppColors.accent,
    AppColors.brandPrimary,
    0.18,
  )!;

  /// 中心の最も熱い光＝暖かい白。
  static final _warmCore = Color.lerp(
    AppColors.accent,
    AppColors.surface,
    0.45,
  )!;

  static const _outline = AppColors.ink900;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bulbR = size.height * 0.17;
    final center = Offset(cx, size.height * 0.48);

    // 灯りは背面から: 光の輪 → レイ → コード → 口金 → ガラス → フィラメント。
    if (glow > 0.02) {
      _paintHalo(canvas, center, bulbR);
      _paintRays(canvas, center, bulbR);
    }
    _paintCordAndCap(canvas, center, bulbR);
    _paintGlass(canvas, center, bulbR);
    _paintFilament(canvas, center, bulbR);
    if (glow > 0.7) _paintSparkles(canvas, center, bulbR);
  }

  /// フラットな同心円で光の輪を表す（にじみを使わないコミック的表現）。
  void _paintHalo(Canvas canvas, Offset center, double bulbR) {
    final spread = 0.45 + 0.55 * glow;
    // 外→内の順に描き、重なりで中心を最も明るく見せる。
    final rings = <(double, Color, double)>[
      (bulbR * 3.0 * spread, _warmDeep, 0.10 * glow),
      (bulbR * 2.2 * spread, _warm, 0.18 * glow),
      (bulbR * 1.6 * spread, _warmCore, 0.28 * glow),
    ];
    for (final (r, color, alpha) in rings) {
      canvas.drawCircle(
        center,
        r,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  /// 放射状のレイ（長短交互のスターバースト）。
  void _paintRays(Canvas canvas, Offset center, double bulbR) {
    const count = 12;
    final paint = Paint()
      ..color = _warm.withValues(alpha: 0.55 * glow)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final inner = bulbR * 1.15;
    for (var i = 0; i < count; i++) {
      final long = i.isEven;
      final outer = bulbR * ((long ? 1.85 : 1.45) + glow * 1.1);
      final a = (i / count) * 2 * math.pi;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(center + dir * inner, center + dir * outer, paint);
    }
  }

  /// 天井から下がるコードと口金（ネジ部）。
  void _paintCordAndCap(Canvas canvas, Offset center, double bulbR) {
    final capW = bulbR * 0.85;
    final capH = bulbR * 0.62;
    final bulbTop = center.dy - bulbR;
    final capRect = Rect.fromLTWH(
      center.dx - capW / 2,
      bulbTop - capH + 4,
      capW,
      capH,
    );

    // コード。
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, capRect.top),
      Paint()
        ..color = _outline
        ..strokeWidth = AppBorder.base
        ..strokeCap = StrokeCap.round,
    );

    // 口金（塗り＋濃紺の縁）。
    final capRRect = RRect.fromRectAndRadius(
      capRect,
      const Radius.circular(AppRadii.radiusSm),
    );
    canvas.drawRRect(capRRect, Paint()..color = AppColors.ink700);
    canvas.drawRRect(
      capRRect,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppBorder.base,
    );
    // ネジ山を2本。
    final linePaint = Paint()
      ..color = _outline
      ..strokeWidth = AppBorder.thin;
    for (var k = 1; k <= 2; k++) {
      final y = capRect.top + capRect.height * (k / 3);
      canvas.drawLine(
        Offset(capRect.left, y),
        Offset(capRect.right, y),
        linePaint,
      );
    }
  }

  /// ガラス球（明るいほど暖色に満ちる）＋濃紺の縁。
  void _paintGlass(Canvas canvas, Offset center, double bulbR) {
    // 消灯時はほぼ無色、点灯で暖色が満ちる。
    final fill = Color.lerp(AppColors.surface, _warmCore, 0.25 + 0.6 * glow)!;
    canvas.drawCircle(center, bulbR, Paint()..color = fill);
    canvas.drawCircle(
      center,
      bulbR,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppBorder.base,
    );
  }

  /// 白熱フィラメント（消灯=灰、点灯=暖色）。
  void _paintFilament(Canvas canvas, Offset center, double bulbR) {
    final color = Color.lerp(AppColors.ink300, _warmDeep, glow)!;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 + glow * 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = bulbR * 0.5;
    final top = center.dy - bulbR * 0.45;
    final bottom = center.dy + bulbR * 0.15;
    // 2本のリード線＋ジグザグの発光部。
    final path = Path()
      ..moveTo(center.dx - w * 0.5, center.dy + bulbR * 0.55)
      ..lineTo(center.dx - w * 0.5, bottom)
      ..lineTo(center.dx - w, top)
      ..lineTo(center.dx - w * 0.33, bottom)
      ..lineTo(center.dx + w * 0.33, top)
      ..lineTo(center.dx + w, bottom)
      ..lineTo(center.dx + w * 0.5, top)
      ..lineTo(center.dx + w * 0.5, center.dy + bulbR * 0.55);
    canvas.drawPath(path, paint);
  }

  /// 高輝度時のきらめき（4方向の小さな光）。
  void _paintSparkles(Canvas canvas, Offset center, double bulbR) {
    final t = ((glow - 0.7) / 0.3).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = _warmCore.withValues(alpha: 0.9 * t)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const spots = [Offset(-1.5, -1.4), Offset(1.7, -1.1), Offset(1.3, 1.3)];
    for (final s in spots) {
      final c = center + Offset(s.dx * bulbR, s.dy * bulbR);
      final r = bulbR * 0.22 * t;
      canvas.drawLine(c + Offset(-r, 0), c + Offset(r, 0), paint);
      canvas.drawLine(c + Offset(0, -r), c + Offset(0, r), paint);
    }
  }

  @override
  bool shouldRepaint(_LampPainter old) => old.glow != glow;
}
