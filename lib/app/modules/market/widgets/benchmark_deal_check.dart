import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/analytics/app_analytics_controller.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/utils/thousands_number_input_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/collection_form_field.dart';
import '../../../data/deal_check.dart';
import '../benchmark_detail_controller.dart';

/// "Is this asking price fair?" — type a price from a shelf or a listing and
/// see it on the bottle's low–high bar with a verdict against the average.
/// Absent for a bottle with no average.
class BenchmarkDealCheck extends StatefulWidget {
  const BenchmarkDealCheck({super.key});

  @override
  State<BenchmarkDealCheck> createState() => _BenchmarkDealCheckState();
}

class _BenchmarkDealCheckState extends State<BenchmarkDealCheck> {
  final _input = TextEditingController();
  BenchmarkDetailController get _c => Get.find<BenchmarkDetailController>();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _c.askingPrice.value = double.tryParse(
      PriceFormatter.normalizeForApi(text) ?? '',
    );
  }

  void _onSubmitted(String _) {
    final check = _c.dealCheck;
    if (check == null || !Get.isRegistered<AppAnalyticsController>()) return;
    unawaited(
      AppAnalyticsController.to.logTap('benchmark_deal_check', {
        'bottle_id': _c.bottleId ?? '',
        'verdict': check.verdict.name,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_c.averageValue == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deal check',
            style: AppTextStyles.titleS().copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Seen it on a shelf or in a listing? See how the price compares.',
            style: AppTextStyles.bodyS().copyWith(color: AppColors.textWolf),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CollectionFormField(
                  controller: _input,
                  hint: 'Asking price',
                  prefixText: r'$ ',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [ThousandsNumberInputFormatter()],
                  onChanged: _onChanged,
                  onSubmitted: _onSubmitted,
                ),
                Obx(() {
                  // dealCheck reads askingPrice, so this rebuilds as they type.
                  final check = _c.dealCheck;
                  return AnimatedSize(
                    duration: AppMotion.of(context, AppMotion.fast),
                    alignment: Alignment.topCenter,
                    child: check == null
                        ? const SizedBox(width: double.infinity)
                        : _Result(check: check, thin: _thin),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The price rests on little evidence or on an admin's entry.
  bool get _thin {
    final p = _c.pricing.value;
    return p == null || p.isThin || p.isOakSpirePrice;
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.check, required this.thin});

  final DealCheck check;
  final bool thin;

  Color get _color {
    if (check.verdict.isFavourable) return AppColors.trendPositive;
    if (check.verdict.isUnfavourable) return AppColors.marketTrendDown;
    return AppColors.goldAccent;
  }

  @override
  Widget build(BuildContext context) {
    final caption = AppTextStyles.bodyS().copyWith(
      fontSize: 11,
      color: AppColors.textWolf,
    );
    String money(double v) => PriceFormatter.format(v.round().toString());

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (check.position != null) ...[
            _RangeBar(
              position: check.position!,
              averagePosition: check.averagePosition,
              markerColor: _color,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Low ${money(check.low!)}', style: caption),
                const Spacer(),
                Text('Avg ${money(check.average)}', style: caption),
                const Spacer(),
                Text('High ${money(check.high!)}', style: caption),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            check.verdict.title,
            style: AppTextStyles.titleS().copyWith(
              color: _color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            check.comparisonLabel,
            style: AppTextStyles.bodyM().copyWith(
              color: AppColors.textNeutralSoft,
            ),
          ),
          if (thin) ...[
            const SizedBox(height: 8),
            Text(
              'Based on limited price data. Treat it as a rough guide.',
              style: caption,
            ),
          ],
        ],
      ),
    );
  }
}

/// Low → high track, cheaper side green, dearer side red, with a tick for
/// the average and a marker for the asking price.
class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.position,
    required this.averagePosition,
    required this.markerColor,
  });

  final double position;
  final double? averagePosition;
  final Color markerColor;

  static const double _trackHeight = 6;
  static const double _markerSize = 14;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _markerSize,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          double x(double t) => (w * t).clamp(0.0, w);
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: _trackHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_trackHeight / 2),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.trendPositive,
                      AppColors.fillBarTrack,
                      AppColors.marketTrendDown,
                    ],
                  ),
                ),
              ),
              if (averagePosition != null)
                Positioned(
                  left: x(averagePosition!) - 1,
                  child: Container(
                    width: 2,
                    height: _markerSize,
                    color: AppColors.textMuted,
                  ),
                ),
              Positioned(
                left: 0,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: position),
                  duration: AppMotion.of(context, AppMotion.fast),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Transform.translate(
                    offset: Offset(x(t) - _markerSize / 2, 0),
                    child: child,
                  ),
                  child: Container(
                    width: _markerSize,
                    height: _markerSize,
                    decoration: BoxDecoration(
                      color: AppColors.textCream,
                      shape: BoxShape.circle,
                      border: Border.all(color: markerColor, width: 3),
                    ),
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
