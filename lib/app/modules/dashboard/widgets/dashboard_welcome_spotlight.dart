import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// A new user's first Home: the welcome card lifts a little, glows, and a
/// sheen sweeps across it once, while the rest of the page blurs behind it
/// ([DashboardSpotlightBackdrop]). A tap anywhere outside the card settles it.
///
/// [due] is checked once, when the card first builds; the lift starts after
/// Home's entrance has played. With reduced motion there is no lift or sheen,
/// only the blur behind.
class DashboardWelcomeSpotlight extends StatefulWidget {
  const DashboardWelcomeSpotlight({
    super.key,
    required this.active,
    required this.due,
    required this.onStart,
    required this.onEnd,
    required this.child,
  });

  /// Whether the card is lifted now ([DashboardController.welcomeSpotlight]).
  final bool active;

  /// Whether it should lift once on screen.
  final bool due;

  final VoidCallback onStart;
  final VoidCallback onEnd;
  final Widget child;

  /// How much the card grows while lifted.
  static const double liftScale = 1.04;

  /// Time for Home's staggered entrance to land before the card lifts.
  static const Duration startDelay = Duration(milliseconds: 550);

  @override
  State<DashboardWelcomeSpotlight> createState() =>
      _DashboardWelcomeSpotlightState();
}

class _DashboardWelcomeSpotlightState extends State<DashboardWelcomeSpotlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.due) {
      Future.delayed(DashboardWelcomeSpotlight.startDelay, () {
        if (mounted) widget.onStart();
      });
    }
  }

  @override
  void didUpdateWidget(DashboardWelcomeSpotlight old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !AppMotion.reduced(context)) {
      // Once, a beat after the lift begins.
      Future.delayed(AppMotion.fast, () {
        if (mounted && widget.active) _sheen.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lift = widget.active && !AppMotion.reduced(context);
    final duration = AppMotion.of(context, AppMotion.slow);
    final radius = BorderRadius.circular(AppRadii.card);

    return TapRegion(
      onTapOutside: widget.active ? (_) => widget.onEnd() : null,
      child: AnimatedScale(
        scale: lift ? DashboardWelcomeSpotlight.liftScale : 1,
        duration: duration,
        curve: lift ? AppMotion.emphasized : AppMotion.standard,
        child: AnimatedContainer(
          duration: duration,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: lift ? AppShadows.spotlight : const [],
          ),
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: radius,
                    child: AnimatedBuilder(
                      animation: _sheen,
                      builder: (context, _) {
                        final t = _sheen.value;
                        if (t == 0 || t == 1) return const SizedBox.shrink();
                        return DecoratedBox(decoration: _sheenAt(t));
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A diagonal band of [AppColors.goldSheen], left of the card at 0 and
  /// right of it at 1.
  static BoxDecoration _sheenAt(double t) {
    final x = lerpDouble(-1.8, 1.8, Curves.easeInOut.transform(t))!;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(x - 0.6, -1),
        end: Alignment(x + 0.6, 1),
        colors: [
          AppColors.goldSheen.withValues(alpha: 0),
          AppColors.goldSheen,
          AppColors.goldSheen.withValues(alpha: 0),
        ],
        stops: const [0.3, 0.5, 0.7],
      ),
    );
  }
}

/// Every other Home section while the welcome card is lifted: blurred,
/// dimmed, and not tappable (a tap there only settles the card).
class DashboardSpotlightBackdrop extends StatelessWidget {
  const DashboardSpotlightBackdrop({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  static const double _blurSigma = 3;
  static const double _dimBy = 0.45;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: active,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: active ? 1 : 0),
        duration: AppMotion.of(context, AppMotion.slow),
        curve: AppMotion.standard,
        child: child,
        builder: (context, t, child) {
          final sigma = _blurSigma * t;
          // Always the same widgets, so the section keeps its state.
          return ImageFiltered(
            enabled: t > 0,
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: Opacity(opacity: 1 - _dimBy * t, child: child),
          );
        },
      ),
    );
  }
}
