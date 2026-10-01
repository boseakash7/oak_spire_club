import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/shimmer_box.dart';

const double _kInset = 23;

/// Height of a real bottle row: 56 image + 8 + 8 vertical padding.
const double _kRowHeight = 72;
const double _kRowGap = 10;

/// Search field + chips block above the list (matches `_TasteList`).
const double _kHeaderHeight = 8 + 46 + 12 + 34 + 12;

/// Name-line widths, varied so the skeleton reads as a list, not a grid.
const List<double> _kNameWidths = [0.86, 0.62, 0.76, 0.54, 0.8, 0.68];

/// First load of "Add a bottle": search field, chips and enough bottle rows
/// to fill the screen, laid out exactly like the real list.
class TasteLoadingView extends StatelessWidget {
  const TasteLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = ((constraints.maxHeight - _kHeaderHeight) /
                (_kRowHeight + _kRowGap))
            .ceil()
            .clamp(1, 12);
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: _kInset),
          child: _Layered(
            builder: (placeholders) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _Slot(
                  placeholders: placeholders,
                  child: const ShimmerBox(
                    height: 46,
                    width: double.infinity,
                    radius: AppRadii.md,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _Slot(
                      placeholders: placeholders,
                      child: const Row(
                        children: [
                          ShimmerBox(height: 28, width: 56, radius: 42),
                          SizedBox(width: 10),
                          ShimmerBox(height: 28, width: 96, radius: 42),
                          SizedBox(width: 10),
                          ShimmerBox(height: 28, width: 84, radius: 42),
                          SizedBox(width: 10),
                          ShimmerBox(height: 28, width: 72, radius: 42),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _rows(rows, placeholders),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder bottle rows inside the list: while a new search or category
/// loads with nothing to show yet, and while the next page loads.
class TasteBottleSkeletonList extends StatelessWidget {
  const TasteBottleSkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _Layered(builder: (placeholders) => _rows(count, placeholders));
  }
}

Widget _rows(int count, bool placeholders) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < count; i++)
        Padding(
          padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : _kRowGap),
          child: placeholders
              ? _RowPlaceholders(
                  nameWidth: _kNameWidths[i % _kNameWidths.length],
                )
              : const _RowCard(),
        ),
    ],
  );
}

/// Paints the same layout twice: card surfaces underneath, then the
/// placeholder blocks inside one [ShimmerScope], so a single sweep runs over
/// the details while the cards stay the colour of the real rows.
class _Layered extends StatelessWidget {
  const _Layered({required this.builder});

  /// Builds the layout; `placeholders` is false for the card layer.
  final Widget Function(bool placeholders) builder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        builder(false),
        Positioned.fill(
          child: ShimmerScope(
            baseColor: AppColors.shimmerOnCardBase,
            highlightColor: AppColors.shimmerOnCardHighlight,
            child: builder(true),
          ),
        ),
      ],
    );
  }
}

/// A header placeholder: drawn in the shimmer layer, kept as empty space of
/// the same size in the card layer.
class _Slot extends StatelessWidget {
  const _Slot({required this.placeholders, required this.child});

  final bool placeholders;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (placeholders) return child;
    return Visibility(
      visible: false,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: child,
    );
  }
}

/// The surface of a bottle row (same as `_BottleRow` in the taste view).
class _RowCard extends StatelessWidget {
  const _RowCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kRowHeight,
      decoration: BoxDecoration(
        gradient: AppColors.cardSurfaceGradient,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    );
  }
}

/// Image, name, proof, price and add button, positioned like the real row.
class _RowPlaceholders extends StatelessWidget {
  const _RowPlaceholders({required this.nameWidth});

  final double nameWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kRowHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
        child: Row(
          children: [
            const ShimmerBox(height: 56, width: 56, radius: 8),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Line(widthFactor: nameWidth, height: 11),
                  const SizedBox(height: 7),
                  _Line(widthFactor: nameWidth * 0.55, height: 11),
                  const SizedBox(height: 9),
                  const ShimmerBox(height: 8, width: 64, radius: 4),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerBox(height: 12, width: 54, radius: 4),
                SizedBox(height: 8),
                ShimmerBox(height: 28, width: 28, radius: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: ShimmerBox(height: height, width: double.infinity, radius: 4),
    );
  }
}
