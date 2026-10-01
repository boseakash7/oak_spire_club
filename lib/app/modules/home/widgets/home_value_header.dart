import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_count_text.dart';
import '../../../core/widgets/app_card.dart';
import '../home_controller.dart';

/// Hero block: the collection's value counting up, the cost basis, the
/// "Moved +N%" line, and the unrealised gain chip.
class HomeValueHeader extends StatelessWidget {
  const HomeValueHeader({super.key, required this.home});

  final HomeController home;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The heading has to match the number below it: when no bottle in the
        // collection carries a bluebook price there is no market value to
        // show, and calling cost basis "value" would be wrong.
        Obx(
          () => Text(
            home.showingInvestedAsValue.value
                ? 'Total Invested'
                : 'Collection Value',
            style: AppTextStyles.titleL(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => AppTextStyles
                        .collectionValueGradient
                        .createShader(bounds),
                    child: Obx(
                      () => AnimatedCountText(
                        value: home.collectionValue.value,
                        format: formatWholeDollars,
                        style: AppTextStyles.displayXl(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Cost basis, shown only when it is the supporting figure
                  // rather than the headline.
                  Obx(() {
                    if (home.showingInvestedAsValue.value) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Invested ${home.investedValueText.value}',
                        style: AppTextStyles.caption(),
                      ),
                    );
                  }),
                  Obx(
                    () => AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.medium),
                      child: _MovedLine(
                        key: ValueKey(home.movedText.value),
                        text: home.movedText.value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Obx(
              () => _GainChip(
                gain: home.unrealisedGain.value,
                label: home.unrealisedGainText.value,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Whole-dollar formatting for the counting hero value. Kept top-level so the
/// count-up animation does not rebuild a NumberFormat every frame.
final _wholeDollars = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 0,
);

String formatWholeDollars(double v) =>
    v <= 0 ? r'$ —' : _wholeDollars.format(v);

/// Unrealised gain / loss beside the hero value: the one figure on this screen
/// that is not shown anywhere else. Hidden when market value is unknown.
class _GainChip extends StatelessWidget {
  const _GainChip({required this.gain, required this.label});

  final double? gain;
  final String label;

  @override
  Widget build(BuildContext context) {
    final value = gain;
    final visible = value != null && label.isNotEmpty;
    final up = (value ?? 0) >= 0;
    final tint = up ? AppColors.trendPositive : AppColors.trendNegative;

    return AnimatedScale(
      scale: visible ? 1 : 0.8,
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.emphasized,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppMotion.of(context, AppMotion.fast),
        child: !visible
            ? const SizedBox.shrink()
            : AppCard(
                radius: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Unrealised', style: AppTextStyles.micro()),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          up
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 16,
                          color: tint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: AppTextStyles.bodyM().copyWith(
                            color: tint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// "Moved +64% in last 3 months" — the percent matches the value's gold.
class _MovedLine extends StatelessWidget {
  const _MovedLine({super.key, required this.text});

  final String text;

  static final _withPercent = RegExp(r'^Moved (.+?) in (.+)$');

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.homeMovedSubtitle();
    final match = _withPercent.firstMatch(text);
    if (match == null) {
      return Text(text, style: base);
    }

    final percentPart = match.group(1)!;
    final periodPart = match.group(2)!;
    final showGoldPercent =
        percentPart != '—' && RegExp(r'%').hasMatch(percentPart);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Moved '),
          if (showGoldPercent)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    AppTextStyles.collectionValueGradient.createShader(bounds),
                child: Text(
                  percentPart,
                  style: base.copyWith(color: AppColors.white),
                ),
              ),
            )
          else
            TextSpan(text: percentPart),
          TextSpan(text: ' in $periodPart'),
        ],
      ),
    );
  }
}
