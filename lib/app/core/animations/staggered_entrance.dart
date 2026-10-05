import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// Remembers which list items already played their entrance, and staggers
/// the ones that appear together.
///
/// Put one around a scrollable list. Items that arrive in the same burst
/// (first page, next page, rows scrolled into view) stagger from slot 0, so a
/// row far down a paginated list never waits behind the rows above it. An
/// item that already played (scrolled away and back, or rebuilt after a
/// refresh) shows at rest instead of animating again.
class StaggerScope extends StatefulWidget {
  const StaggerScope({super.key, required this.child, this.entranceWindow});

  final Widget child;

  /// When set, only items that appear within this long of the scope being
  /// created animate (the first screenful of a list). Rows that scroll into
  /// view or arrive with a later page show at rest, so scrolling never
  /// reveals blank rows popping in. Key the scope by query to restart it.
  final Duration? entranceWindow;

  /// Forget every played item, e.g. when a new search replaces the list.
  static void reset(BuildContext context) =>
      context.findAncestorStateOfType<_StaggerScopeState>()?._played.clear();

  @override
  State<StaggerScope> createState() => _StaggerScopeState();
}

class _StaggerScopeState extends State<StaggerScope> {
  /// Items that arrive within this gap of each other stagger as one burst.
  static const Duration _burstGap = Duration(milliseconds: 140);

  final Set<Object> _played = <Object>{};
  final DateTime _createdAt = DateTime.now();
  DateTime _lastStart = DateTime.fromMillisecondsSinceEpoch(0);
  int _burst = 0;

  bool hasPlayed(Object id) => _played.contains(id);

  bool get entranceOpen {
    final window = widget.entranceWindow;
    return window == null || DateTime.now().difference(_createdAt) <= window;
  }

  void markPlayed(Object id) => _played.add(id);

  int nextSlot() {
    final now = DateTime.now();
    if (now.difference(_lastStart) > _burstGap) _burst = 0;
    _lastStart = now;
    return _burst++;
  }

  @override
  Widget build(BuildContext context) =>
      _StaggerScopeMarker(state: this, child: widget.child);
}

class _StaggerScopeMarker extends InheritedWidget {
  const _StaggerScopeMarker({required this.state, required super.child});

  final _StaggerScopeState state;

  @override
  bool updateShouldNotify(_StaggerScopeMarker oldWidget) => false;
}

/// Fade + rise entrance for a list row, card or section.
///
/// Inside a [StaggerScope] with an [id], the row animates once and staggers
/// with whatever appears alongside it. Without a scope it waits [index] slots
/// (capped at [AppMotion.maxStaggerSlots]) — right for a fixed set of
/// sections on a screen.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.id,
    this.index = 0,
    this.offsetY = 0.06,
    this.enabled = true,
  });

  final Widget child;

  /// Stable identity (e.g. a bottle id) used to play the entrance once.
  final Object? id;

  /// Slot used when there is no [StaggerScope] or no [id].
  final int index;

  /// Starting offset as a fraction of the child's height.
  final double offsetY;

  final bool enabled;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.listItem,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.emphasizedDecelerate,
  );
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;

    final scope = context
        .getInheritedWidgetOfExactType<_StaggerScopeMarker>()
        ?.state;
    final id = widget.id;

    if (!widget.enabled ||
        AppMotion.reduced(context) ||
        (scope != null &&
            id != null &&
            (scope.hasPlayed(id) || !scope.entranceOpen))) {
      _controller.value = 1;
      return;
    }

    final slot = scope != null && id != null ? scope.nextSlot() : widget.index;
    if (scope != null && id != null) scope.markPlayed(id);

    Future<void>.delayed(AppMotion.staggerDelay(slot), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) => FractionalTranslation(
          translation: Offset(0, widget.offsetY * (1 - _curve.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// A screen section that fades and rises in, [index] slots after the first.
class FadeSlideEntrance extends StatelessWidget {
  const FadeSlideEntrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) =>
      StaggeredEntrance(index: index, offsetY: 0.07, child: child);
}

/// A [Column] whose children rise in one after another (spacers excluded
/// from the count), for forms and short fixed layouts.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.firstIndex = 0,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final int firstIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: staggerChildren(children, firstIndex: firstIndex),
    );
  }
}

/// [children] with each non-spacer wrapped in a [FadeSlideEntrance] one slot
/// after the previous, e.g. for a sliver list of form fields.
List<Widget> staggerChildren(List<Widget> children, {int firstIndex = 0}) {
  var slot = firstIndex;
  return [
    for (final child in children)
      if (child is SizedBox || child is Spacer)
        child
      else
        FadeSlideEntrance(index: slot++, child: child),
  ];
}
