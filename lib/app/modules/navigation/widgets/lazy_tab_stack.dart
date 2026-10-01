import 'package:flutter/material.dart';

import '../../../core/animations/app_motion.dart';

/// The shell's tab bodies: each tab is built on first visit and kept alive,
/// and switching fades the incoming tab through (a short fade with a slight
/// scale-up) instead of cutting.
///
/// A plain IndexedStack builds every child immediately, which would fire all
/// three tabs' initial fetches on cold start. Rebuilding on each switch is the
/// other extreme: it throws away scroll position, replays entrance animations
/// and redraws the chart from zero every time. This keeps the cheap cold
/// start and the cheap switches.
///
/// Hidden tabs get `TickerMode(false)` so their animations (shimmer, chart
/// draw) pause, and `HeroMode(false)` so a bottle shown on two tabs never
/// produces duplicate Hero tags when a route is pushed.
class LazyTabStack extends StatefulWidget {
  const LazyTabStack({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<LazyTabStack> createState() => _LazyTabStackState();
}

class _LazyTabStackState extends State<LazyTabStack>
    with SingleTickerProviderStateMixin {
  late final List<bool> _visited = List<bool>.generate(
    widget.children.length,
    (i) => i == widget.index,
  );

  late final AnimationController _switch = AnimationController(
    vsync: this,
    duration: AppMotion.tabSwitch,
    value: 1,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _switch,
    curve: AppMotion.emphasizedDecelerate,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.985,
    end: 1,
  ).animate(_fade);
  static const Animation<double> _rest = AlwaysStoppedAnimation<double>(1);

  @override
  void didUpdateWidget(LazyTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _markVisited();
    if (oldWidget.index != widget.index) {
      if (AppMotion.reduced(context)) {
        _switch.value = 1;
      } else {
        _switch.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _switch.dispose();
    super.dispose();
  }

  void _markVisited() {
    final i = widget.index;
    if (i >= 0 && i < _visited.length) _visited[i] = true;
  }

  @override
  Widget build(BuildContext context) {
    _markVisited();
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          if (!_visited[i])
            const SizedBox.shrink()
          else
            TickerMode(
              enabled: i == widget.index,
              child: HeroMode(
                enabled: i == widget.index,
                // Same widget types for every tab, active or not, so a tab's
                // element (and its state) survives becoming active.
                child: FadeTransition(
                  opacity: i == widget.index ? _fade : kAlwaysCompleteAnimation,
                  child: ScaleTransition(
                    scale: i == widget.index ? _scale : _rest,
                    child: widget.children[i],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
