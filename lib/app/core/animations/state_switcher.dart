import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Cross-fades between the states of one area of a screen: loading, content,
/// empty, error, or search results for a new query.
///
/// Uses Material's fade-through: the outgoing state fades out, then the
/// incoming one fades and scales up from 92%, so two layouts never overlap.
/// Give each state a distinct [stateKey]; a rebuild with the same key
/// updates in place without animating.
class AppStateSwitcher extends StatelessWidget {
  const AppStateSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
    this.duration = AppMotion.stateSwitch,
    this.alignment = Alignment.topCenter,
  });

  final Object stateKey;
  final Widget child;
  final Duration duration;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: AppMotion.of(context, duration),
      layoutBuilder: (entries) =>
          Stack(alignment: alignment, children: entries),
      transitionBuilder: (child, primary, secondary) => FadeThroughTransition(
        animation: primary,
        secondaryAnimation: secondary,
        fillColor: Colors.transparent,
        child: child,
      ),
      child: KeyedSubtree(key: ValueKey<Object>(stateKey), child: child),
    );
  }
}
