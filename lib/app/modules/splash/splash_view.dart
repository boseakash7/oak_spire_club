import 'package:flutter/material.dart';

import '../../core/animations/app_motion.dart';
import '../../core/constants/app_assets.dart';
import '../../core/widgets/app_backdrop_image.dart';
import '../../core/theme/app_colors.dart';

/// Same background art as sign-in. The logo settles in with a soft scale
/// and a gold sheen sweeps across it while the session resolves (the
/// controller holds the splash for a minimum time).
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  static const double _logoSize = 132;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// 0 → 1 over the first ~40%: fade and scale in.
  late final Animation<double> _enter = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.4, curve: AppMotion.emphasizedDecelerate),
  );

  /// Sheen position across the logo, after it has settled.
  late final Animation<double> _sheen = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.45, 0.85, curve: Curves.easeInOutCubic),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final e = _enter.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Slow push-in on the background.
              Transform.scale(
                scale: 1.08 - 0.08 * _c.value,
                child: const AppBackdropImage(AppAssets.signInBackground),
              ),
              Center(
                child: Opacity(
                  opacity: e,
                  child: Transform.scale(
                    scale: 0.82 + 0.18 * e,
                    child: _SheenLogo(progress: _sheen.value),
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

class _SheenLogo extends StatelessWidget {
  const _SheenLogo({required this.progress});

  /// 0..1 — where the sheen band is; 0 and 1 are off the logo.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      AppAssets.appIc,
      width: _SplashViewState._logoSize,
      height: _SplashViewState._logoSize,
      fit: BoxFit.contain,
    );

    if (progress <= 0 || progress >= 1) return logo;

    return Stack(
      alignment: Alignment.center,
      children: [
        logo,
        ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final x = -1.5 + 3 * progress;
            return LinearGradient(
              begin: Alignment(x - 0.4, -1),
              end: Alignment(x + 0.4, 1),
              colors: const [
                Colors.transparent,
                AppColors.goldSheen,
                Colors.transparent,
              ],
            ).createShader(bounds);
          },
          child: logo,
        ),
      ],
    );
  }
}
