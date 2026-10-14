import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_haptics.dart';

/// Press and hold for two seconds to open a sealed bottle, or to seal an
/// opened one. Letting go early cancels and changes nothing, so the hold is
/// the confirmation.
///
/// While held a gold wash sweeps across, the bottle's cap twists off (or back
/// on), and the phone rumbles in step with the row's shake: both start
/// gentle and grow with the hold ([shakeAmplitude], [intensityAt]), then a
/// buzz when it's done. Letting go stops the rumble. A phone that can't play
/// a shaped vibration ticks every quarter second instead. [onProgress]
/// reports 0..1 so the caller can shake its row. With the OS "reduce motion"
/// setting the cap and the shake stay still, but the hold still takes two
/// seconds and still rumbles.
class HoldToToggleButton extends StatefulWidget {
  const HoldToToggleButton({
    super.key,
    required this.opening,
    required this.onComplete,
    this.onProgress,
    this.enabled = true,
  });

  /// True to open a sealed bottle, false to seal an opened one.
  final bool opening;
  final VoidCallback onComplete;
  final ValueChanged<double>? onProgress;
  final bool enabled;

  static const Duration holdDuration = Duration(seconds: 2);
  static const Duration _tickEvery = Duration(milliseconds: 250);

  /// How hard the hold shakes and rumbles at [progress] (0..1): a third at
  /// the start, full at the end.
  static double intensityAt(double progress) {
    final p = progress.clamp(0.0, 1.0);
    return 0.3 + 0.7 * p * p;
  }

  /// The row's side-to-side shake at [progress], in logical pixels: 30
  /// shakes a second, as wide as [intensityAt] says.
  static double shakeOffset(double progress) {
    if (progress <= 0 || progress >= 1) return 0;
    return math.sin(progress * 2 * math.pi * 60) * shakeAmplitude(progress);
  }

  static double shakeAmplitude(double progress) => 1.6 * intensityAt(progress);

  /// The rumble for a whole hold, as [AppHaptics.rumble] takes it: one pulse
  /// every 100 ms, each longer and stronger than the last, so the separate
  /// ticks at the start run together into a buzz by the end, the way the
  /// shake grows.
  static (List<int>, List<int>) rumblePattern() {
    const step = 100;
    final count = holdDuration.inMilliseconds ~/ step;
    final pattern = <int>[];
    final strengths = <int>[];
    for (var i = 0; i < count; i++) {
      final k = intensityAt(i / count);
      final on = (step * (0.35 + 0.55 * k)).round();
      pattern
        ..add(i == 0 ? 0 : step - on)
        ..add(on);
      strengths
        ..add(0)
        ..add((255 * k).round().clamp(1, 255));
    }
    return (pattern, strengths);
  }

  @override
  State<HoldToToggleButton> createState() => _HoldToToggleButtonState();
}

final (List<int>, List<int>) _rumble = HoldToToggleButton.rumblePattern();

class _HoldToToggleButtonState extends State<HoldToToggleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: HoldToToggleButton.holdDuration,
  )..addListener(_onTick);

  Timer? _ticker;
  bool _holding = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    AppHaptics.probeRumble();
  }

  void _onTick() {
    widget.onProgress?.call(_c.value);
    if (_c.value >= 1 && !_done) _complete();
    if (mounted) setState(() {});
  }

  void _start() {
    if (!widget.enabled || _done) return;
    _holding = true;
    _ticker?.cancel();
    if (AppHaptics.canRumble) {
      AppHaptics.rumble(_rumble.$1, _rumble.$2);
    } else {
      AppHaptics.tap();
      _ticker = Timer.periodic(
        HoldToToggleButton._tickEvery,
        (_) => AppHaptics.tap(),
      );
    }
    _c.forward(from: 0);
  }

  void _stopHaptics() {
    _ticker?.cancel();
    AppHaptics.stopRumble();
  }

  void _cancel() {
    if (!_holding || _done) return;
    _holding = false;
    _stopHaptics();
    _c.stop();
    final reduced = AppMotion.reduced(context);
    if (reduced) {
      _c.value = 0;
    } else {
      _c.animateBack(0, duration: AppMotion.fast, curve: AppMotion.standard);
    }
  }

  void _complete() {
    _done = true;
    _holding = false;
    _c.stop();
    if (AppHaptics.canRumble) {
      // Replaces the hold's rumble: one hard thump, then a shorter one.
      _ticker?.cancel();
      AppHaptics.rumble(const [0, 70, 60, 110], const [0, 255, 0, 200]);
      widget.onComplete();
      return;
    }
    _stopHaptics();
    // A long buzz: three beats in quick succession.
    AppHaptics.confirm();
    Future<void>.delayed(
      const Duration(milliseconds: 90),
      () => AppHaptics.unawaitedHaptic(HapticFeedback.heavyImpact),
    );
    Future<void>.delayed(
      const Duration(milliseconds: 190),
      () => AppHaptics.unawaitedHaptic(HapticFeedback.mediumImpact),
    );
    widget.onComplete();
  }

  @override
  void didUpdateWidget(HoldToToggleButton old) {
    super.didUpdateWidget(old);
    if (old.opening != widget.opening) {
      _done = false;
      _holding = false;
      _c.value = 0;
      widget.onProgress?.call(0);
    }
  }

  /// Leaving the tree (a closed card, a rebuilt row) ends any hold without
  /// touching the context, which is no longer safe to read.
  @override
  void deactivate() {
    if (_holding) _stopHaptics();
    _holding = false;
    _ticker?.cancel();
    _c.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _c.dispose();
    super.dispose();
  }

  String get _label {
    final verb = widget.opening ? 'open' : 'seal';
    if (!_holding && _c.value == 0) return 'Hold 2s to $verb';
    final left =
        (HoldToToggleButton.holdDuration.inMilliseconds * (1 - _c.value) / 1000)
            .clamp(0.0, 2.0);
    final doing = widget.opening ? 'Opening' : 'Sealing';
    return '$doing… ${left.toStringAsFixed(1)}s';
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final verb = widget.opening ? 'open' : 'seal';

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Hold for two seconds to $verb this bottle',
      // Assistive tech can't hold, so a double tap does it straight away.
      onTap: widget.enabled ? widget.onComplete : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _start(),
        onTapUp: (_) => _cancel(),
        onTapCancel: _cancel,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.5,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.goldRich),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md - 1),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _c.value,
                        heightFactor: 1,
                        child: ColoredBox(
                          color: AppColors.goldRich.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 30,
                        child: CustomPaint(
                          painter: _CapPainter(
                            progress: reduced
                                ? (widget.opening ? 0 : 1)
                                : (widget.opening ? _c.value : 1 - _c.value),
                            color: AppColors.goldBright,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _label,
                        style: AppTextStyles.bodyL().copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textCream,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A bottle neck with its cap. [progress] 0 is screwed on, 1 is lifted off
/// after a full turn.
class _CapPainter extends CustomPainter {
  _CapPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 22;
    final sy = size.height / 30;
    canvas.scale(sx, sy);

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    // Neck, widening into the shoulders.
    final neck = Path()
      ..moveTo(6, 12)
      ..lineTo(16, 12)
      ..lineTo(16, 15)
      ..lineTo(15, 15)
      ..lineTo(15, 30)
      ..lineTo(7, 30)
      ..lineTo(7, 15)
      ..lineTo(6, 15)
      ..close();
    canvas.drawPath(neck, line);

    final lift = progress * 7;
    canvas.save();
    canvas.translate(11, 7 - lift);
    canvas.rotate(progress * 2 * math.pi);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, -4, 14, 7),
        const Radius.circular(2),
      ),
      fill,
    );
    final ridge = Paint()
      ..color = AppColors.black
      ..strokeWidth = 1;
    for (final x in const [-3.0, 0.0, 3.0]) {
      canvas.drawLine(Offset(x, -3), Offset(x, 2), ridge);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CapPainter old) =>
      old.progress != progress || old.color != color;
}
