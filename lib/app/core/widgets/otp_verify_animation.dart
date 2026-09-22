import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Premium OTP verify hero — envelope opens, letter rises, gold rings + sparkles.
class OtpVerifyAnimation extends StatefulWidget {
  const OtpVerifyAnimation({
    super.key,
    this.size = 180,
  });

  final double size;

  @override
  State<OtpVerifyAnimation> createState() => _OtpVerifyAnimationState();
}

class _OtpVerifyAnimationState extends State<OtpVerifyAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _loop;
  late final AnimationController _orbit;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_loop, _orbit]),
        builder: (context, _) {
          return CustomPaint(
            size: Size.square(size),
            painter: _OtpScenePainter(
              t: _loop.value,
              orbit: _orbit.value,
            ),
          );
        },
      ),
    );
  }
}

class _OtpScenePainter extends CustomPainter {
  _OtpScenePainter({required this.t, required this.orbit});

  final double t;
  final double orbit;

  double _seg(double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return Curves.easeInOutCubic.transform((t - start) / (end - start));
  }

  double _o(double value) => value.clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final s = size.shortestSide;

    final flapOpen = _seg(0.16, 0.38);
    final letterRise = _seg(0.34, 0.58);
    final digitsOn = _seg(0.52, 0.78);
    final settle = _seg(0.72, 1.0);
    final breath = 0.5 + 0.5 * math.sin(t * math.pi * 2);

    _paintAmbientGlow(canvas, c, s, breath);
    _paintOrbitRings(canvas, c, s, breath);
    _paintSparkles(canvas, c, s);
    _paintEnvelope(canvas, c, s, flapOpen, letterRise, digitsOn, settle, breath);
  }

  void _paintAmbientGlow(Canvas canvas, Offset c, double s, double breath) {
    final r = math.max(1.0, s * (0.42 + breath * 0.04));
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        c,
        r,
        [
          const Color(0xFFD4AF37).withOpacity(_o(0.28 + breath * 0.1)),
          const Color(0xFFB9861F).withOpacity(0.12),
          Colors.transparent,
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(c, r, paint);
  }

  void _paintOrbitRings(Canvas canvas, Offset c, double s, double breath) {
    for (var i = 0; i < 3; i++) {
      final phase = (orbit + i * 0.22) % 1.0;
      final expand = 0.55 + phase * 0.4;
      final opacity = _o((1 - phase) * (0.18 + breath * 0.08));
      final radius = math.max(1.0, s * 0.28 * expand);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Color.lerp(AppColors.gold1, AppColors.gold2, i / 2)!
            .withOpacity(opacity);
      canvas.drawCircle(c, radius, paint);
    }
  }

  void _paintSparkles(Canvas canvas, Offset c, double s) {
    final rnd = math.Random(7);
    for (var i = 0; i < 14; i++) {
      final baseAngle = (i / 14) * math.pi * 2;
      final spin = orbit * math.pi * 2 * (i.isEven ? 1 : -0.7);
      final radius = s * (0.34 + rnd.nextDouble() * 0.12);
      final twinkle = _o(
        0.35 +
            0.65 *
                (0.5 +
                    0.5 *
                        math.sin(t * math.pi * 2 * (1.5 + i % 3) + i)),
      );
      final p = Offset(
        c.dx + math.cos(baseAngle + spin) * radius,
        c.dy + math.sin(baseAngle + spin * 0.8) * radius * 0.78,
      );
      canvas.drawCircle(
        p,
        math.max(0.5, 1.1 + twinkle * 1.4),
        Paint()..color = AppColors.gold2.withOpacity(_o(0.15 + twinkle * 0.55)),
      );

      if (i % 3 == 0) {
        final cross = Paint()
          ..color = AppColors.gold2.withOpacity(_o(0.25 + twinkle * 0.4))
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        final len = 2.5 + twinkle * 2;
        canvas.drawLine(p.translate(-len, 0), p.translate(len, 0), cross);
        canvas.drawLine(p.translate(0, -len), p.translate(0, len), cross);
      }
    }
  }

  void _paintEnvelope(
    Canvas canvas,
    Offset c,
    double s,
    double flapOpen,
    double letterRise,
    double digitsOn,
    double settle,
    double breath,
  ) {
    final cardW = s * 0.58;
    final cardH = s * 0.42;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c.translate(0, s * 0.04),
        width: cardW,
        height: cardH,
      ),
      const Radius.circular(16),
    );

    canvas.drawRRect(
      cardRect.shift(const Offset(0, 6)),
      Paint()..color = Colors.black.withOpacity(0.35),
    );

    final cardPaint = Paint()
      ..shader = ui.Gradient.linear(
        cardRect.outerRect.topLeft,
        cardRect.outerRect.bottomRight,
        const [
          Color(0xFF1A100F),
          Color(0xFF10090B),
          Color(0xFF18100E),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRRect(cardRect, cardPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = ui.Gradient.linear(
        cardRect.outerRect.topLeft,
        cardRect.outerRect.bottomRight,
        [
          AppColors.gold1.withOpacity(_o(0.35 + breath * 0.35)),
          AppColors.gold2.withOpacity(0.85),
          AppColors.gold1.withOpacity(_o(0.4 + breath * 0.3)),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRRect(cardRect, borderPaint);

    final body = cardRect.outerRect;
    final left = body.left;
    final right = body.right;
    final top = body.top;
    final bottom = body.bottom;
    final midX = body.center.dx;

    if (letterRise > 0) {
      final letterH = cardH * 0.55;
      final rise = letterRise * cardH * 0.55;
      final letterRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(midX, top + cardH * 0.35 - rise),
          width: cardW * 0.72,
          height: letterH,
        ),
        const Radius.circular(8),
      );

      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left + 2, top - cardH, right - 2, bottom - 2),
          const Radius.circular(14),
        ),
      );

      canvas.drawRRect(
        letterRect,
        Paint()
          ..shader = ui.Gradient.linear(
            letterRect.outerRect.topCenter,
            letterRect.outerRect.bottomCenter,
            [
              const Color(0xFFF1E8BE).withOpacity(0.95),
              const Color(0xFFE8D9A0).withOpacity(0.9),
            ],
          ),
      );

      final digitY = letterRect.outerRect.center.dy;
      final digitStartX = midX - cardW * 0.22;
      for (var i = 0; i < 4; i++) {
        final appear = _o(
          Curves.easeOutCubic.transform(
            ((digitsOn * 4) - i).clamp(0.0, 1.0),
          ),
        );
        final dx = digitStartX + i * (cardW * 0.15);
        final r = math.max(0.0, 5.0 * appear);
        if (r <= 0.2) continue;
        canvas.drawCircle(
          Offset(dx, digitY),
          r,
          Paint()
            ..shader = AppColors.goldGradient.createShader(
              Rect.fromCircle(center: Offset(dx, digitY), radius: r),
            ),
        );
        if (appear > 0.7) {
          canvas.drawCircle(
            Offset(dx, digitY),
            r + 3,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = AppColors.gold2.withOpacity(_o((appear - 0.7) * 1.5)),
          );
        }
      }
      canvas.restore();
    }

    final foldPaint = Paint()
      ..color = AppColors.gold1.withOpacity(_o(0.25 + breath * 0.15))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;

    final foldPath = Path()
      ..moveTo(left + 10, bottom - 12)
      ..lineTo(midX, top + cardH * 0.42)
      ..lineTo(right - 10, bottom - 12);
    canvas.drawPath(foldPath, foldPaint);

    final flapHeight = cardH * 0.48;
    final openAngle = flapOpen * (math.pi * 0.72);
    canvas.save();
    canvas.translate(midX, top + 1);
    final scaleY = math.cos(openAngle).abs().clamp(0.12, 1.0);
    final lift = math.sin(openAngle) * flapHeight * 0.15;
    canvas.translate(0, -lift);
    canvas.scale(1.0, scaleY);

    final flapPath = Path()
      ..moveTo(-cardW / 2 + 8, 0)
      ..lineTo(0, flapHeight)
      ..lineTo(cardW / 2 - 8, 0)
      ..close();

    canvas.drawPath(
      flapPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, flapHeight),
          [
            Color.lerp(const Color(0xFF2A1C16), AppColors.gold1, 0.15)!,
            const Color(0xFF10090B),
          ],
        ),
    );
    canvas.drawPath(
      flapPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = AppColors.gold2.withOpacity(_o(0.55 + flapOpen * 0.3)),
    );
    canvas.restore();

    final sealProgress = _o(
      Curves.easeOutCubic.transform(
        ((digitsOn - 0.35) / 0.65).clamp(0.0, 1.0),
      ),
    );
    if (sealProgress > 0.01) {
      final sealC = Offset(midX, bottom - cardH * 0.22);
      final sealR = math.max(0.5, 11.0 * sealProgress);
      canvas.drawCircle(
        sealC,
        sealR + 4,
        Paint()..color = AppColors.gold2.withOpacity(_o(0.2 * sealProgress)),
      );
      canvas.drawCircle(
        sealC,
        sealR,
        Paint()
          ..shader = AppColors.goldGradient.createShader(
            Rect.fromCircle(center: sealC, radius: sealR),
          ),
      );
      final check = Paint()
        ..color = AppColors.black.withOpacity(sealProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final checkPath = Path()
        ..moveTo(sealC.dx - 4.2, sealC.dy)
        ..lineTo(sealC.dx - 0.8, sealC.dy + 3.2)
        ..lineTo(sealC.dx + 5.0, sealC.dy - 3.4);
      canvas.drawPath(checkPath, check);
    }

    final dotsY = bottom + s * 0.09;
    final dotsStart = midX - s * 0.16;
    for (var i = 0; i < 4; i++) {
      final wave = 0.5 +
          0.5 * math.sin((t * math.pi * 2) + i * 0.9 + settle * math.pi);
      final lit = (digitsOn * 4 - i).clamp(0.0, 1.0);
      final active = _o(math.max(lit, wave * 0.35 * settle.clamp(0.4, 1.0)));
      final dx = dotsStart + i * (s * 0.11);
      final r = math.max(0.5, 4.2 + active * 2.2);
      canvas.drawCircle(
        Offset(dx, dotsY),
        r + 5,
        Paint()..color = AppColors.gold2.withOpacity(_o(0.12 * active)),
      );
      canvas.drawCircle(
        Offset(dx, dotsY),
        r,
        Paint()
          ..shader = AppColors.goldGradient.createShader(
            Rect.fromCircle(center: Offset(dx, dotsY), radius: r),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OtpScenePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.orbit != orbit;
}
