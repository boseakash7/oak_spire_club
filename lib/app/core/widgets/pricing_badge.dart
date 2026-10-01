import 'package:flutter/material.dart';

import '../../data/models/bottle_pricing.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A small dot + label saying what a price rests on (ai-features-plan.md
/// §2.5): "Oak Spire price" for an admin-entered price, "Market" for
/// auction / market data, "Retail" for a below-shelf state price. The dot is
/// green for well-observed market prices, gold for thinner ones, and muted
/// for thin, stale, legacy and admin prices.
class PricingBadge extends StatelessWidget {
  const PricingBadge({super.key, required this.pricing, this.compact = false});

  final BottlePricing? pricing;

  /// Dot only, with the label as a tooltip / semantics.
  final bool compact;

  Color get _color {
    final p = pricing;
    if (p == null || p.isOakSpirePrice || p.isThin) {
      return AppColors.confidenceLow;
    }
    return p.confidence == 'high'
        ? AppColors.confidenceHigh
        : AppColors.confidenceMedium;
  }

  @override
  Widget build(BuildContext context) {
    final p = pricing;
    if (p == null) return const SizedBox.shrink();

    final label = p.label;
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
    );

    if (compact) {
      return Tooltip(
        message: label,
        child: Semantics(label: label, child: dot),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.captionS().copyWith(
            color: p.isThin ? AppColors.textWolf : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
