import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/shimmer_box.dart';

const double _kInset = 23;

/// [CollectionView]'s Owned · Wishlist switch.
const double _kSwitchHeight = 44;

/// One quick-stat tile (see `HomeQuickStats`).
const double _kTileHeight = 48;
const double _kTileGap = 10;

/// Card heights, close to the real ones for a typical collection.
const double _kValueCardHeight = 98;
const double _kMixCardHeight = 196;
const double _kChartCardHeight = 292;
const double _kRowHeight = 104;

/// Name-line widths, varied so the rows read as a list, not a grid.
const List<double> _kNameWidths = [0.9, 0.72, 0.84];

/// Legend widths in the portfolio mix, longest share first.
const List<double> _kLegendWidths = [0.7, 0.56, 0.46, 0.36];

/// First load of the Collection tab, laid out like the real page so nothing
/// jumps when it lands: the Owned · Wishlist switch, the quick-stat tiles,
/// the value card, the portfolio mix, "You vs the market" and the top priced
/// bottles. Placeholders sit on real card surfaces under one shimmer sweep
/// ([ShimmerCardLayers]).
class CollectionLoadingView extends StatelessWidget {
  const CollectionLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceDeep,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          _kInset,
          kShellTabBodyContentTopGap,
          _kInset,
          120,
        ),
        child: ShimmerCardLayers(
          builder: (placeholders) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SegmentSwitch(placeholders: placeholders),
              const SizedBox(height: AppSpacing.md),
              ShimmerSlot(
                placeholders: placeholders,
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: ShimmerBox(height: 14, width: 92, radius: 4),
                ),
              ),
              const SizedBox(height: 12),
              _QuickStats(placeholders: placeholders),
              const SizedBox(height: AppSpacing.md),
              _ValueCard(placeholders: placeholders),
              const SizedBox(height: AppSpacing.md),
              _MixCard(placeholders: placeholders),
              const SizedBox(height: AppSpacing.md),
              _ChartCard(placeholders: placeholders),
              const SizedBox(height: AppSpacing.xl),
              ShimmerSlot(
                placeholders: placeholders,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(height: 14, width: 140, radius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(height: 9, width: 168, radius: 4),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final (i, w) in _kNameWidths.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _Surface(
                  placeholders: placeholders,
                  height: _kRowHeight,
                  radius: AppRadii.md,
                  showBorder: false,
                  child: _BottleRow(nameWidth: w),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A card in the surface layer; in the placeholder layer, the same box with
/// [child]'s placeholders on it.
class _Surface extends StatelessWidget {
  const _Surface({
    required this.placeholders,
    required this.height,
    required this.child,
    this.radius = AppRadii.card,
    this.showBorder = true,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 14),
  });

  final bool placeholders;
  final double height;
  final double radius;
  final bool showBorder;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: ShimmerSlot(placeholders: placeholders, child: child),
    );
    if (placeholders) return SizedBox(height: height, child: content);
    return AppCard(
      height: height,
      radius: radius,
      showBorder: showBorder,
      child: content,
    );
  }
}

/// The Owned · Wishlist switch: its track as a surface, two labels on it.
class _SegmentSwitch extends StatelessWidget {
  const _SegmentSwitch({required this.placeholders});

  final bool placeholders;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kSwitchHeight,
      padding: const EdgeInsets.all(3),
      decoration: placeholders
          ? null
          : BoxDecoration(
              color: AppColors.surfaceChip,
              borderRadius: BorderRadius.circular(AppRadii.chip),
              border: Border.all(color: AppColors.tagInactiveBorder),
            ),
      child: ShimmerSlot(
        placeholders: placeholders,
        child: const Row(
          children: [
            Expanded(
              child: Center(
                child: ShimmerBox(height: 12, width: 54, radius: 4),
              ),
            ),
            Expanded(
              child: Center(
                child: ShimmerBox(height: 12, width: 64, radius: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eight one-line tiles, two to a row: icon, label, number.
class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.placeholders});

  final bool placeholders;

  static const List<double> _labelWidths = [62, 40, 44, 34, 66, 52, 54, 48];

  Widget _tile(double labelWidth) => Expanded(
    child: _Surface(
      placeholders: placeholders,
      height: _kTileHeight,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const ShimmerBox(height: 18, width: 18, radius: 9),
          const SizedBox(width: 8),
          // Shrinks on a narrow phone rather than overflow.
          Flexible(child: ShimmerBox(height: 10, width: labelWidth, radius: 4)),
          const Spacer(),
          const ShimmerBox(height: 16, width: 26, radius: 4),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var r = 0; r < 4; r++) ...[
          if (r > 0) const SizedBox(height: _kTileGap),
          Row(
            children: [
              _tile(_labelWidths[r * 2]),
              const SizedBox(width: _kTileGap),
              _tile(_labelWidths[r * 2 + 1]),
            ],
          ),
        ],
      ],
    );
  }
}

/// "Collection value": heading, today's value, the invested caption, and the
/// gain badge on the right.
class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.placeholders});

  final bool placeholders;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      placeholders: placeholders,
      height: _kValueCardHeight,
      child: const Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 10, width: 96, radius: 4),
                SizedBox(height: 10),
                ShimmerBox(height: 26, width: 132, radius: 6),
                SizedBox(height: 8),
                ShimmerBox(height: 9, width: 176, radius: 4),
              ],
            ),
          ),
          SizedBox(width: 10),
          ShimmerBox(height: 30, width: 78, radius: 10),
        ],
      ),
    );
  }
}

/// "Portfolio mix": heading and the Type / Brand toggle, the stacked bar,
/// and the legend.
class _MixCard extends StatelessWidget {
  const _MixCard({required this.placeholders});

  final bool placeholders;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      placeholders: placeholders,
      height: _kMixCardHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(height: 10, width: 84, radius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(height: 8, width: 112, radius: 4),
                  ],
                ),
              ),
              ShimmerBox(height: 30, width: 112, radius: 15),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const ShimmerBox(height: 10, width: double.infinity, radius: 5),
          const SizedBox(height: AppSpacing.sm),
          for (final w in _kLegendWidths)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const ShimmerBox(height: 10, width: 10, radius: 3),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: ShimmerLine(widthFactor: w, height: 9)),
                  const SizedBox(width: AppSpacing.xs),
                  const ShimmerBox(height: 9, width: 46, radius: 4),
                  const SizedBox(width: 8),
                  const ShimmerBox(height: 9, width: 30, radius: 4),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "You vs the market": heading and range picker, the two scores, the chart
/// and its caption.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.placeholders});

  final bool placeholders;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      placeholders: placeholders,
      height: _kChartCardHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ShimmerBox(height: 10, width: 108, radius: 4),
                ),
              ),
              ShimmerBox(height: 28, width: 136, radius: 14),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              Expanded(child: _Score()),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _Score()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: CustomPaint(painter: _ChartGhostPainter())),
          const SizedBox(height: 10),
          const ShimmerBox(height: 8, width: 190, radius: 4),
        ],
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(height: 8, width: 84, radius: 4),
        SizedBox(height: 8),
        ShimmerBox(height: 22, width: 70, radius: 5),
      ],
    );
  }
}

/// Two soft lines where the value chart will be. Painted in the shimmer's
/// base colour, so the sweep runs over them like the other placeholders.
class _ChartGhostPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.shimmerBase
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    Path line(List<double> ys) {
      final path = Path();
      for (var i = 0; i < ys.length; i++) {
        final x = size.width * i / (ys.length - 1);
        final y = size.height * ys[i];
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final px = size.width * (i - 1) / (ys.length - 1);
          final py = size.height * ys[i - 1];
          final mx = (px + x) / 2;
          path.cubicTo(mx, py, mx, y, x, y);
        }
      }
      return path;
    }

    canvas.drawPath(line(const [0.7, 0.62, 0.66, 0.48, 0.4, 0.3, 0.22]), paint);
    paint.strokeWidth = 2;
    canvas.drawPath(
      line(const [0.7, 0.68, 0.6, 0.62, 0.55, 0.52, 0.48]),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A collection row: art, name, maker, chips and the fill line on the left;
/// value, gain, the price line and the last move on the right.
class _BottleRow extends StatelessWidget {
  const _BottleRow({required this.nameWidth});

  final double nameWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ShimmerBox(height: 66, width: 66, radius: 10),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLine(widthFactor: nameWidth, height: 11),
              const SizedBox(height: 6),
              ShimmerLine(widthFactor: nameWidth * 0.55, height: 9),
              const SizedBox(height: 8),
              const Row(
                children: [
                  ShimmerBox(height: 14, width: 34, radius: AppRadii.sm),
                  SizedBox(width: 6),
                  ShimmerBox(height: 14, width: 30, radius: AppRadii.sm),
                ],
              ),
              const SizedBox(height: 9),
              const Row(
                children: [
                  ShimmerBox(height: 6, width: 44, radius: 3),
                  SizedBox(width: 6),
                  Flexible(child: ShimmerBox(height: 8, width: 56, radius: 4)),
                ],
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
            SizedBox(height: 6),
            ShimmerBox(height: 9, width: 50, radius: 4),
            SizedBox(height: 7),
            ShimmerBox(height: 22, width: 64, radius: 4),
            SizedBox(height: 5),
            ShimmerBox(height: 8, width: 44, radius: 4),
          ],
        ),
      ],
    );
  }
}
