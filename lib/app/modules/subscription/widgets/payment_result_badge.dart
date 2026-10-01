import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';

/// The round result mark on the payment screen.
///
/// Success: the gold disc springs in, the check pops, and a ring of gold
/// sparks bursts outwards. Failure: the red disc shakes once. Either way a
/// haptic lands with it.
class PaymentResultBadge extends StatefulWidget {
  const PaymentResultBadge({super.key, required this.succeeded});

  final bool succeeded;

  @override
  State<PaymentResultBadge> createState() => _PaymentResultBadgeState();
}

class _PaymentResultBadgeState extends State<PaymentResultBadge>
    with SingleTickerProviderStateMixin {
  static const double _size = 64;
  static const double _canvas = 180;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final Animation<double> _disc = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.35, curve: Curves.elasticOut),
  );
  late final Animation<double> _icon = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.2, 0.45, curve: Curves.easeOutBack),
  );
  late final Animation<double> _burst = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.18, 0.9, curve: Curves.easeOutCubic),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      widget.succeeded ? AppHaptics.confirm() : AppHaptics.error();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = widget.succeeded;

    return SizedBox.square(
      dimension: _canvas,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // One decaying shake for failure, after the disc lands.
          final shake = ok || _c.value < 0.35
              ? 0.0
              : math.sin((_c.value - 0.35) * 40) *
                    8 *
                    (1 - ((_c.value - 0.35) / 0.65)).clamp(0.0, 1.0);

          return Stack(
            alignment: Alignment.center,
            children: [
              if (ok)
                CustomPaint(
                  size: const Size.square(_canvas),
                  painter: _BurstPainter(progress: _burst.value),
                ),
              Transform.translate(
                offset: Offset(shake, 0),
                child: Transform.scale(
                  scale: _disc.value,
                  child: Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: ok ? AppColors.goldGradient : null,
                      color: ok ? null : AppColors.destructiveSurface,
                      border: ok
                          ? null
                          : Border.all(
                              color: AppColors.errorLight.withValues(
                                alpha: 0.7,
                              ),
                              width: 1.5,
                            ),
                      boxShadow: ok
                          ? const [
                              BoxShadow(
                                color: AppColors.goldGlow,
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Transform.scale(
                      scale: _icon.value,
                      child: Icon(
                        ok ? Icons.check_rounded : Icons.close_rounded,
                        size: 36,
                        color: ok ? AppColors.black : AppColors.errorLight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Twelve gold sparks flying out from the centre and fading.
class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress});

  final double progress;

  static const int _sparks = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = size.center(Offset.zero);
    final fade = 1 - progress;
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var i = 0; i < _sparks; i++) {
      final angle = (i / _sparks) * 2 * math.pi + (i.isEven ? 0 : 0.14);
      final reach = (i.isEven ? 78.0 : 62.0) * progress + 30;
      final length = (i.isEven ? 12.0 : 8.0) * fade + 2;
      final dir = Offset(math.cos(angle), math.sin(angle));
      paint
        ..color = (i % 3 == 0 ? AppColors.gold2 : AppColors.goldBright)
            .withValues(alpha: fade)
        ..strokeWidth = i.isEven ? 3 : 2;
      canvas.drawLine(
        center + dir * reach,
        center + dir * (reach + length),
        paint,
      );
    }

    // A soft ring expanding with the sparks.
    canvas.drawCircle(
      center,
      34 + 50 * progress,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * fade
        ..color = AppColors.gold2.withValues(alpha: 0.5 * fade),
    );
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress;
}
