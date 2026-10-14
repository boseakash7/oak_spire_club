import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../data/models/subscription_package_model.dart';
import '../../session/user_session_controller.dart';

/// "Go Premium", at the top of Home for a user on the free plan: the four
/// benefits the subscription screen lists, in a 2×2 grid, and a button to it.
/// The button offers the free trial until it has been used. While a package's
/// offer runs, the button gives way to the offer: its label and countdown on
/// the left, "Claim offer" on the right (no price, no trial).
///
/// Hidden when the user has a subscription or backend-granted premium
/// (`is_free`), the same rule as the header's plan badge.
class DashboardPremiumCard extends StatelessWidget {
  const DashboardPremiumCard({
    super.key,
    required this.onUpgrade,
    this.offer,
    this.percentOff,
    this.onOfferEnded,
  });

  final VoidCallback onUpgrade;

  /// The running offer, if any ([DashboardController.premiumOffer]).
  final PackageOffer? offer;

  /// What [offer] takes off the package's price, as a whole percent.
  final int? percentOff;

  /// The countdown reached zero: the card goes back to its trial button.
  final VoidCallback? onOfferEnded;

  /// Whether [user] should see the card.
  static bool showFor(UserSessionController session) {
    final user = session.user.value;
    return user != null && !user.hasActiveSubscription && !user.isFreeUser;
  }

  static const _benefits = [
    (Icons.liquor_rounded, 'Unlimited collection'),
    (Icons.storage_rounded, '10,000+ bottles'),
    (Icons.show_chart_rounded, 'Full bottle insights'),
    (Icons.all_inclusive_rounded, 'No daily limits'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Get.find<UserSessionController>().user.value;
    final trial = user?.hasUsedTrial != true;

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.5)),
      ),
      child: AppCard(
        showBorder: false,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 20,
                  color: AppColors.goldBright,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Go Premium',
                    style: AppTextStyles.headingM().copyWith(
                      fontSize: 18,
                      color: AppColors.textCream,
                    ),
                  ),
                ),
                Text(
                  'Cancel anytime',
                  style: AppTextStyles.bodyS().copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < _benefits.length; i += 2) ...[
              if (i > 0) const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(child: _Benefit(_benefits[i])),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: _Benefit(_benefits[i + 1])),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (offer case final offer?)
              _OfferRow(
                key: ValueKey(offer.endsAt),
                offer: offer,
                percentOff: percentOff,
                onClaim: onUpgrade,
                onEnded: onOfferEnded,
              )
            else
              CommonPrimaryButton(
                label: trial ? 'Start free trial' : 'Go Premium',
                onPressed: onUpgrade,
              ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.benefit);

  final (IconData, String) benefit;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = benefit;
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.goldBright),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyS().copyWith(
              fontSize: 12.5,
              color: AppColors.textCream,
            ),
          ),
        ),
      ],
    );
  }
}

/// The offer in place of the trial button: its label over a live countdown,
/// with "Claim offer" beside them. Only the countdown rebuilds each second.
class _OfferRow extends StatelessWidget {
  const _OfferRow({
    super.key,
    required this.offer,
    required this.percentOff,
    required this.onClaim,
    required this.onEnded,
  });

  final PackageOffer offer;
  final int? percentOff;
  final VoidCallback onClaim;
  final VoidCallback? onEnded;

  @override
  Widget build(BuildContext context) {
    final title = percentOff == null
        ? offer.label
        : '${offer.label} · $percentOff% off';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyS().copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldBright,
                ),
              ),
              const SizedBox(height: 2),
              _OfferCountdown(offer: offer, onEnded: onEnded),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 136,
          child: CommonPrimaryButton(
            label: 'Claim offer',
            height: AppButtonSize.compact,
            onPressed: onClaim,
          ),
        ),
      ],
    );
  }
}

/// "Ends in 2d 04:12:09", ticking every second. Calls [onEnded] once at zero.
class _OfferCountdown extends StatefulWidget {
  const _OfferCountdown({required this.offer, required this.onEnded});

  final PackageOffer offer;
  final VoidCallback? onEnded;

  @override
  State<_OfferCountdown> createState() => _OfferCountdownState();
}

class _OfferCountdownState extends State<_OfferCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!widget.offer.isRunning(DateTime.now())) {
        _timer?.cancel();
        widget.onEnded?.call();
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'Ends in ',
        children: [
          TextSpan(
            text: widget.offer.countdownAt(DateTime.now()),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textCream,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
      maxLines: 1,
      style: AppTextStyles.bodyS().copyWith(
        fontSize: 12,
        color: AppColors.textMuted,
      ),
    );
  }
}
