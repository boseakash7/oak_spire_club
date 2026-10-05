import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../animations/app_motion.dart';
import '../platform/app_platform.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_pressable.dart';

/// One option in an [AppFilterChipBar].
class AppFilterChipItem<T> {
  const AppFilterChipItem(this.value, this.label);

  final T value;
  final String label;
}

const double _kBarHeight = 34;
const double _kChipHeight = 28;
const double _kChipMinWidth = 92;
const double _kGap = 10;
const double _kRadius = 42;

/// A horizontal row of filter chips (Collection, Benchmark, Add a bottle)
/// with one gold highlight.
///
/// Picking a chip moves the highlight towards the middle of the bar; once it
/// gets there it stays put and the row scrolls the chip into it instead (the
/// first few chips can't reach the middle, so the highlight goes to them).
/// The highlight eases to the new chip's width, and labels turn dark as they
/// pass under the gold: the highlight carries its own copy of the row,
/// clipped to its shape. When the row is scrolled by hand, the highlight
/// stays with the selected chip.
class AppFilterChipBar<T> extends StatefulWidget {
  const AppFilterChipBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.clipToBounds = false,
  });

  final List<AppFilterChipItem<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;

  /// Clip chips at the bar's own left and right edges (e.g. beside a fixed
  /// icon). Otherwise they scroll out to the screen edge.
  final bool clipToBounds;

  @override
  State<AppFilterChipBar<T>> createState() => _AppFilterChipBarState<T>();
}

class _AppFilterChipBarState<T> extends State<AppFilterChipBar<T>>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _rowKey = GlobalKey();
  List<GlobalKey> _chipKeys = const [];

  late final AnimationController _move = AnimationController(vsync: this)
    ..addListener(_onMoveTick);
  // Gentle at both ends: a fast-start curve made the row lurch a third of
  // the way in the first frame.
  late final CurvedAnimation _moveCurve = CurvedAnimation(
    parent: _move,
    curve: Curves.easeInOutCubic,
  );

  /// Highlight (viewport x, width) and scroll offset at the start and end
  /// of a selection move.
  bool _moving = false;
  int _moveId = 0;
  double _fromX = 0, _fromW = 0, _toX = 0, _toW = 0;
  double _fromOffset = 0, _toOffset = 0;

  /// Width of the last chip, so the row can scroll it to the middle too.
  double _lastChipWidth = _kChipMinWidth;

  /// Scroll offset that centres chip [chip] (content x, width) in the bar,
  /// clamped to what the row can actually scroll.
  double _centringOffset((double, double) chip) {
    final p = _scroll.position;
    final centre = chip.$1 + chip.$2 / 2 - p.viewportDimension / 2;
    return centre.clamp(p.minScrollExtent, p.maxScrollExtent);
  }

  @override
  void initState() {
    super.initState();
    _syncKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _settle(jump: true));
  }

  @override
  void didUpdateWidget(AppFilterChipBar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Measure where the highlight is before the chip keys can change.
    final from = oldWidget.selected != widget.selected
        ? _currentHighlight(
            oldWidget.items.indexWhere((i) => i.value == oldWidget.selected),
          )
        : null;
    final itemsChanged = _syncKeys();
    if (oldWidget.selected != widget.selected) {
      // The move starts after this frame's layout; until then keep the
      // highlight where it was, or it flashes onto the new chip for a frame
      // and jumps back.
      if (from != null) _holdAt(from);
      WidgetsBinding.instance.addPostFrameCallback((_) => _startMove(from));
    } else if (itemsChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _settle());
    }
  }

  @override
  void dispose() {
    _moveCurve.dispose();
    _move.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Returns true when the item count changed.
  bool _syncKeys() {
    if (_chipKeys.length == widget.items.length) return false;
    _chipKeys = List.generate(widget.items.length, (_) => GlobalKey());
    return true;
  }

  int get _selectedIndex =>
      widget.items.indexWhere((i) => i.value == widget.selected);

  double get _offset => _scroll.hasClients ? _scroll.offset : 0;

  /// Chip [index]'s left edge and width in row (content) coordinates.
  (double, double)? _chip(int index) {
    if (index < 0 || index >= _chipKeys.length) return null;
    final chip = _chipKeys[index].currentContext?.findRenderObject();
    final row = _rowKey.currentContext?.findRenderObject();
    if (chip is! RenderBox || row is! RenderBox) return null;
    if (!chip.hasSize || !chip.attached || !row.attached) return null;
    final x = chip.localToGlobal(Offset.zero, ancestor: row).dx;
    return (x, chip.size.width);
  }

  /// Where the highlight is on screen right now (viewport x, width).
  (double, double)? _currentHighlight([int? index]) {
    if (_moving) {
      final t = _moveCurve.value;
      return (lerpDouble(_fromX, _toX, t)!, lerpDouble(_fromW, _toW, t)!);
    }
    final chip = _chip(index ?? _selectedIndex);
    if (chip == null) return null;
    return (chip.$1 - _offset, chip.$2);
  }

  /// After layout: measure the last chip and, on first show, put the
  /// selected chip in the highlight without animating.
  void _settle({bool jump = false}) {
    if (!mounted) return;
    final last = _chip(_chipKeys.length - 1);
    final lastWidth = last?.$2 ?? _kChipMinWidth;
    if (lastWidth != _lastChipWidth) {
      // The scroll range depends on it: re-layout, then align again.
      setState(() => _lastChipWidth = lastWidth);
      WidgetsBinding.instance.addPostFrameCallback((_) => _settle(jump: jump));
      return;
    }
    if (jump && _scroll.hasClients) {
      final target = _chip(_selectedIndex);
      if (target != null) _scroll.jumpTo(_centringOffset(target));
    }
    // First frame drew no highlight (nothing was measured yet).
    setState(() {});
  }

  /// Pins the highlight at [at] (viewport x, width) without moving the row.
  void _holdAt((double, double) at) {
    _moveId++;
    _move.stop();
    _fromX = _toX = at.$1;
    _fromW = _toW = at.$2;
    _fromOffset = _toOffset = _offset;
    _moving = true;
    _move.value = 0;
  }

  void _startMove((double, double)? from) {
    if (!mounted) return;
    final target = _chip(_selectedIndex);
    if (target == null || !_scroll.hasClients) {
      setState(() => _moving = false);
      return;
    }
    _fromOffset = _scroll.position.pixels;
    _toOffset = _centringOffset(target);
    _toX = target.$1 - _toOffset;
    _toW = target.$2;
    _fromX = from?.$1 ?? _toX;
    _fromW = from?.$2 ?? _toW;
    _moving = true;
    _move.duration = AppMotion.of(context, AppMotion.slow);
    final move = ++_moveId;
    _move.forward(from: 0).whenCompleteOrCancel(() {
      // A cancelled earlier move reports late; ignore it.
      if (mounted && move == _moveId) setState(() => _moving = false);
    });
  }

  void _onMoveTick() {
    if (!_moving || !_scroll.hasClients) return;
    final target = lerpDouble(_fromOffset, _toOffset, _moveCurve.value)!;
    if (target != _scroll.position.pixels) _scroll.jumpTo(target);
  }

  bool _onScrollStart(ScrollStartNotification n) {
    // A finger on the row takes over from the selection move.
    if (n.dragDetails != null && _moving) _move.stop();
    return false;
  }

  void _select(int index) {
    final value = widget.items[index].value;
    if (value != widget.selected) widget.onSelected(value);
  }

  Widget _row({required bool onGold}) {
    return Row(
      key: onGold ? null : _rowKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.items.length; i++) ...[
          if (i > 0) const SizedBox(width: _kGap),
          if (onGold)
            _ChipFace(label: widget.items[i].label, onGold: true)
          else
            Semantics(
              key: _chipKeys[i],
              button: true,
              selected: i == _selectedIndex,
              child: AppPressable(
                onTap: () => _select(i),
                haptic: PressHaptic.selection,
                scale: 0.94,
                child: _ChipFace(label: widget.items[i].label, onGold: false),
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kBarHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Room after the last chip, so it can be centred like the rest.
          final trailing = math.max(
            0.0,
            (constraints.maxWidth - _lastChipWidth) / 2,
          );

          final bar = Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: NotificationListener<ScrollStartNotification>(
                  onNotification: _onScrollStart,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    physics: AppPlatform.scrollPhysics,
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.only(right: trailing),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _row(onGold: false),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_scroll, _move]),
                    // Built once per bar build, not per animation frame: each
                    // frame only moves and clips it.
                    child: RepaintBoundary(child: _row(onGold: true)),
                    builder: (context, goldRow) {
                      final h = _currentHighlight();
                      if (h == null) return const SizedBox.shrink();
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: h.$1,
                            top: (_kBarHeight - _kChipHeight) / 2,
                            width: h.$2,
                            height: _kChipHeight,
                            child: _Highlight(
                              // Keeps the dark labels lined up with the row.
                              rowShift: -_offset - h.$1,
                              row: goldRow!,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );

          if (!widget.clipToBounds) return bar;
          return ClipRect(clipper: const _HorizontalClip(), child: bar);
        },
      ),
    );
  }
}

/// The gold pill, with the row's labels redrawn dark inside it.
class _Highlight extends StatelessWidget {
  const _Highlight({required this.rowShift, required this.row});

  final double rowShift;
  final Widget row;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold1.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kRadius),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.goldGradient),
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            child: Transform.translate(offset: Offset(rowShift, 0), child: row),
          ),
        ),
      ),
    );
  }
}

class _ChipFace extends StatelessWidget {
  const _ChipFace({required this.label, required this.onGold});

  final String label;

  /// Drawn inside the highlight: no surface, dark label.
  final bool onGold;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kChipHeight,
      constraints: const BoxConstraints(minWidth: _kChipMinWidth),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: Alignment.center,
      decoration: onGold
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(_kRadius),
              gradient: AppColors.cardSurfaceGradient,
            ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: AppTextStyles.uiChip().copyWith(
          color: onGold ? AppColors.black : AppColors.textCream,
        ),
      ),
    );
  }
}

/// Clips left and right only, so the highlight's glow is not cut off.
class _HorizontalClip extends CustomClipper<Rect> {
  const _HorizontalClip();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -24, size.width, size.height + 24);

  @override
  bool shouldReclip(_HorizontalClip oldClipper) => false;
}
