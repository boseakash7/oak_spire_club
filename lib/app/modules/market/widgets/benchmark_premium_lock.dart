import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../benchmark_detail_controller.dart';
import 'benchmark_price_chart.dart';

// What a free plan sees of the bottle page's Premium insights
// (BenchmarkDetailController.insightsLocked): the price range, the price
// history and the deal check. Each opens the subscription screen.

/// A small gold "Premium" pill with a lock, standing in for a locked figure.
class PremiumLockPill extends StatelessWidget {
  const PremiumLockPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.tap,
      semanticLabel: 'Premium feature. Go Premium',
      child: Container(
        height: 23,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: AppColors.goldAccentGlow,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: AppColors.tagGoldBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_rounded,
              size: 12,
              color: AppColors.goldBright,
            ),
            const SizedBox(width: 4),
            Text(
              'Premium',
              style: AppTextStyles.bodyS().copyWith(
                color: AppColors.goldBright,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// In place of the price chart: a blurred line behind a lock, what the chart
/// shows, and the way to Premium.
class BenchmarkLockedChart extends GetView<BenchmarkDetailController> {
  const BenchmarkLockedChart({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      height: BenchmarkPriceChart.height,
      child: ClipRRect(
        borderRadius: AppRadii.cardAll,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Decoration only: a made-up line, blurred past reading.
            ExcludeSemantics(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 40, 16, 28),
                  child: CustomPaint(painter: _GhostStepLinePainter()),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9,
                  colors: [AppColors.surfaceDeep, Colors.transparent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _LockMark(),
                  const SizedBox(height: 10),
                  Text(
                    'Price history is Premium',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleS().copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textCream,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'See how this bottle’s price has moved over 1M, 3M, 6M '
                    'and 1Y.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyS().copyWith(
                      color: AppColors.textWolf,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 200,
                    child: CommonPrimaryButton(
                      label: 'Unlock with Premium',
                      height: AppButtonSize.compact,
                      onPressed: () => controller.openPremium('chart'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// In place of the deal check: its heading, a dimmed price field, and the
/// lock.
class BenchmarkLockedDealCheck extends GetView<BenchmarkDetailController> {
  const BenchmarkLockedDealCheck({super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.averageValue == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Deal check',
                  style: AppTextStyles.titleS().copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PremiumLockPill(onTap: () => controller.openPremium('deal_check')),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Seen it on a shelf or in a listing? See how the price compares.',
            style: AppTextStyles.bodyS().copyWith(color: AppColors.textWolf),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(14),
            onTap: () => controller.openPremium('deal_check'),
            child: Row(
              children: [
                const _LockMark(size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Check any asking price against this bottle’s market '
                    'range with Premium.',
                    style: AppTextStyles.bodyS().copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textWolf,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A gold lock in a soft gold ring.
class _LockMark extends StatelessWidget {
  const _LockMark({this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.goldAccentGlow,
        border: Border.all(color: AppColors.tagGoldBorder),
      ),
      child: Icon(
        Icons.lock_rounded,
        size: size * 0.45,
        color: AppColors.goldBright,
      ),
    );
  }
}

/// A made-up step line in the chart's colour, only ever drawn blurred.
class _GhostStepLinePainter extends CustomPainter {
  const _GhostStepLinePainter();

  static const List<double> _levels = [
    0.72, 0.72, 0.6, 0.64, 0.5, 0.5, 0.42, 0.46, 0.3, 0.34, 0.22,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height * _levels.first);
    for (var i = 1; i < _levels.length; i++) {
      final x = size.width * i / (_levels.length - 1);
      path
        ..lineTo(x, size.height * _levels[i - 1])
        ..lineTo(x, size.height * _levels[i]);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.chartLineMarketValue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
