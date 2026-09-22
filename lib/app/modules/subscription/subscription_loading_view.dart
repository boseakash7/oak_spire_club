import 'package:flutter/material.dart';

import '../../core/theme/app_subscription_theme.dart';
import '../../core/widgets/shimmer_box.dart';

/// Full-screen placeholder while subscription profile + data loads.
class SubscriptionLoadingView extends StatelessWidget {
  const SubscriptionLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShimmerBox(height: 36, width: 200, radius: 8),
        const SizedBox(height: 8),
        const ShimmerBox(height: 36, width: 160, radius: 8),
        const SizedBox(height: 12),
        const ShimmerBox(height: 16, width: double.infinity, radius: 6),
        const SizedBox(height: 28),
        const ShimmerBox(height: 48, width: double.infinity, radius: 10),
        const SizedBox(height: 24),
        ShimmerBox(
          height: AppSubscriptionTheme.priceCardHeight,
          width: double.infinity,
          radius: AppSubscriptionTheme.priceCardRadius,
        ),
        const SizedBox(height: AppSubscriptionTheme.priceCardGap),
        ShimmerBox(
          height: AppSubscriptionTheme.priceCardHeight,
          width: double.infinity,
          radius: AppSubscriptionTheme.priceCardRadius,
        ),
      ],
    );
  }
}
