import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/shimmer_box.dart';

const double _kInset = 23;

/// Height of a typical [MarketBottleRow] (two-line name, origin, chips).
const double _kRowHeight = 96;
const double _kRowGap = 12;

/// Index strip height and card widths (see `MarketIndexStrip`).
const double _kIndexHeight = 128;
const double _kIndexWideWidth = 236;
const double _kIndexWidth = 196;

/// Movers title block above the rows.
const double _kMoversHeaderHeight = 36;

/// Name-line widths, varied so the skeleton reads as a list, not a grid.
const List<double> _kNameWidths = [0.9, 0.7, 0.82, 0.62, 0.86, 0.74];

/// First load of Market, laid out like the top of the real tab: the index
/// strip, the "Biggest movers" heading and enough bottle rows to fill the
/// screen. Placeholders sit on real card surfaces under one shimmer sweep.
class MarketLoadingView extends StatelessWidget {
  const MarketLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const above =
            kShellTabBodyContentTopGap +
            _kIndexHeight +
            AppSpacing.lg +
            _kMoversHeaderHeight +
            AppSpacing.sm;
        final rows =
            ((constraints.maxHeight - above) / (_kRowHeight + _kRowGap))
                .ceil()
                .clamp(1, 8);
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ShimmerCardLayers(
            builder: (placeholders) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: kShellTabBodyContentTopGap),
                // The strip runs past the right edge, like the real one.
                SizedBox(
                  height: _kIndexHeight,
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    maxWidth: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.only(left: _kInset),
                      child: Row(
                        children: [
                          _IndexCard(
                            placeholders: placeholders,
                            width: _kIndexWideWidth,
                            wide: true,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _IndexCard(
                            placeholders: placeholders,
                            width: _kIndexWidth,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _kInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ShimmerSlot(
                        placeholders: placeholders,
                        child: const SizedBox(
                          height: _kMoversHeaderHeight,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShimmerBox(
                                      height: 14,
                                      width: 124,
                                      radius: 4,
                                    ),
                                    SizedBox(height: 7),
                                    ShimmerBox(height: 9, width: 72, radius: 4),
                                  ],
                                ),
                              ),
                              ShimmerBox(height: 32, width: 134, radius: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _rows(rows, placeholders),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder bottle rows inside the list: while a new search, category or
/// sort loads with nothing to show yet, and while the next page loads.
class MarketBottleSkeletonList extends StatelessWidget {
  const MarketBottleSkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ShimmerCardLayers(
      builder: (placeholders) => _rows(count, placeholders),
    );
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
              : const AppCard(
                  radius: AppRadii.md,
                  showBorder: false,
                  height: _kRowHeight,
                  child: SizedBox.shrink(),
                ),
        ),
    ],
  );
}

/// An index card: name, level and today's change, then the 30-day change,
/// bottle count and the index's line.
class _IndexCard extends StatelessWidget {
  const _IndexCard({
    required this.placeholders,
    required this.width,
    this.wide = false,
  });

  final bool placeholders;
  final double width;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (!placeholders) {
      return AppCard(
        width: width,
        height: _kIndexHeight,
        child: const SizedBox.shrink(),
      );
    }
    return SizedBox(
      width: width,
      height: _kIndexHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(height: 10, width: 96, radius: 4),
            const SizedBox(height: 10),
            Row(
              children: [
                ShimmerBox(height: wide ? 22 : 18, width: 84, radius: 5),
                const SizedBox(width: 8),
                const ShimmerBox(height: 9, width: 52, radius: 4),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 9, width: 54, radius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(height: 9, width: 72, radius: 4),
                    ],
                  ),
                ),
                ShimmerBox(
                  height: wide ? 32 : 24,
                  width: wide ? 96 : 64,
                  radius: 6,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Art, name, origin and chips on the left; price, price line, movement and
/// range on the right, positioned like [MarketBottleRow].
class _RowPlaceholders extends StatelessWidget {
  const _RowPlaceholders({required this.nameWidth});

  final double nameWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kRowHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        child: Row(
          children: [
            const ShimmerBox(height: 66, width: 66, radius: 10),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLine(widthFactor: nameWidth, height: 12),
                  const SizedBox(height: 7),
                  ShimmerLine(widthFactor: nameWidth * 0.6, height: 12),
                  const SizedBox(height: 9),
                  ShimmerLine(widthFactor: nameWidth * 0.5, height: 9),
                  const SizedBox(height: 10),
                  // Chips that don't fit are cut off, as on a narrow phone.
                  const SizedBox(
                    height: 16,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        maxWidth: double.infinity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShimmerBox(
                              height: 16,
                              width: 40,
                              radius: AppRadii.sm,
                            ),
                            SizedBox(width: 6),
                            ShimmerBox(
                              height: 16,
                              width: 32,
                              radius: AppRadii.sm,
                            ),
                            SizedBox(width: 6),
                            ShimmerBox(
                              height: 16,
                              width: 36,
                              radius: AppRadii.sm,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerBox(height: 14, width: 58, radius: 4),
                SizedBox(height: 7),
                ShimmerBox(height: 20, width: 60, radius: 4),
                SizedBox(height: 7),
                ShimmerBox(height: 10, width: 44, radius: 4),
                SizedBox(height: 6),
                ShimmerBox(height: 8, width: 62, radius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
