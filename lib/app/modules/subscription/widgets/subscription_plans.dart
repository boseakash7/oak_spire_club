// Plan picker: plan cards, trial pricing, the countdown, the selection mark.
part of '../subscription_view.dart';

class _PackagePlanList extends StatelessWidget {
  const _PackagePlanList({
    required this.subscription,
    required this.useAppleStorePrices,
    required this.applePriceForPlan,
    required this.isLoadingApplePrices,
  });

  final SubscriptionController subscription;
  final bool useAppleStorePrices;
  final String? Function(SubscriptionPackageModel plan) applePriceForPlan;
  final bool isLoadingApplePrices;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (subscription.isLoadingPackages.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold1,
              ),
            ),
          ),
        );
      }

      final error = subscription.loadError.value;
      if (error != null && error.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            error,
            style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textWolf),
          ),
        );
      }

      final plans = subscription.packages;
      if (plans.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No subscription plans available.',
            style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textWolf),
          ),
        );
      }

      final selectedId = subscription.selectedPackageId.value;
      final bestValueIndex = plans.indexWhere((plan) => !plan.isYearly);

      return Column(
        children: [
          for (var i = 0; i < plans.length; i++) ...[
            FadeSlideEntrance(
              index: 5 + i,
              child: _PricePlanCard(
                plan: plans[i],
                isSelected: plans[i].id == selectedId,
                showBestValue: i == bestValueIndex,
                onTap: () => subscription.selectPackage(plans[i].id),
                applePriceLabel: useAppleStorePrices
                    ? applePriceForPlan(plans[i])
                    : null,
                isLoadingApplePrice:
                    useAppleStorePrices && isLoadingApplePrices,
              ),
            ),
            if (i < plans.length - 1)
              const SizedBox(height: AppSubscriptionTheme.priceCardGap),
          ],
        ],
      );
    });
  }
}

/// Figma pricing cards 124:314 / 196:284 — 323×58 stacked plan rows.

/// Figma pricing cards 124:314 / 196:284 — 323×58 stacked plan rows.
class _PricePlanCard extends StatelessWidget {
  const _PricePlanCard({
    required this.plan,
    required this.isSelected,
    required this.showBestValue,
    required this.onTap,
    this.applePriceLabel,
    this.isLoadingApplePrice = false,
  });

  final SubscriptionPackageModel plan;
  final bool isSelected;
  final bool showBestValue;
  final VoidCallback onTap;
  final String? applePriceLabel;
  final bool isLoadingApplePrice;

  String get _renewalNote {
    final storePrice = applePriceLabel?.trim();
    if (storePrice != null && storePrice.isNotEmpty) {
      return 'After trial will renew at $storePrice';
    }
    return plan.renewalNote;
  }

  @override
  Widget build(BuildContext context) {
    final card = AppPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        height: AppSubscriptionTheme.priceCardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            AppSubscriptionTheme.priceCardRadius,
          ),
          gradient: AppColors.cardSurfaceGradient,
          border: Border.all(
            color: isSelected
                ? AppColors.subscriptionPlanBorderSelected
                : AppColors.subscriptionPlanBorderUnselected,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      plan.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.billingSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        color: AppColors.subscriptionBillingSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TrialPriceLabel(
                priceLabel: applePriceLabel ?? plan.displayPrice,
                salePrice: double.tryParse(plan.price),
                isStoreLocalized:
                    applePriceLabel != null && applePriceLabel!.isNotEmpty,
                isLoading: isLoadingApplePrice,
                renewalNote: _renewalNote,
              ),
              SizedBox(
                width: 30,
                child: isSelected
                    ? const Center(child: _PlanSelectionIndicator())
                    : null,
              ),
            ],
          ),
        ),
      ),
    );

    if (!showBestValue) return card;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSubscriptionTheme.bestValueBadgeOverlap,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          const Positioned(
            top: -10,
            left: 26,
            child: IgnorePointer(child: _BestValueBadge()),
          ),
        ],
      ),
    );
  }
}

class _TrialPriceLabel extends StatelessWidget {
  const _TrialPriceLabel({
    required this.priceLabel,
    required this.renewalNote,
    this.salePrice,
    this.isStoreLocalized = false,
    this.isLoading = false,
  });

  static const double _originalPriceMultiplier = 1.5;

  final String priceLabel;
  final double? salePrice;
  final bool isStoreLocalized;
  final bool isLoading;
  final String renewalNote;

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) return amount.toInt().toString();
    return amount.toStringAsFixed(2);
  }

  String _leadingCurrencySymbol(String label) {
    final trimmed = label.trim();
    var end = 0;
    while (end < trimmed.length) {
      final code = trimmed.codeUnitAt(end);
      final isDigit = code >= 48 && code <= 57;
      if (isDigit || code == 32) break;
      end++;
    }
    if (end == 0) return r'$';
    return trimmed.substring(0, end);
  }

  String? _originalPriceLabel(String saleLabel) {
    final basePrice = salePrice;
    if (basePrice == null || basePrice <= 0) return null;

    final originalAmount = basePrice * _originalPriceMultiplier;
    final formattedAmount = _formatAmount(originalAmount);

    if (isStoreLocalized) {
      return '${_leadingCurrencySymbol(saleLabel)}$formattedAmount';
    }

    return r'$' + formattedAmount;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.gold1,
        ),
      );
    }

    final label = isStoreLocalized ? priceLabel : r'$' + priceLabel;
    final originalLabel = _originalPriceLabel(label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              textAlign: TextAlign.right,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: AppColors.subscriptionPriceLabel,
              ),
            ),
            if (originalLabel != null) ...[
              const SizedBox(width: 4),
              Text(
                originalLabel,
                textAlign: TextAlign.right,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1,
                  color: AppColors.textWolf,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.textWolf,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          renewalNote,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 1.06,
            color: AppColors.textWolf,
          ),
        ),
      ],
    );
  }
}

class _BestValueBadge extends StatelessWidget {
  const _BestValueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 20,
      padding: const EdgeInsets.only(left: 6, right: 8),
      decoration: BoxDecoration(
        color: AppColors.subscriptionPlanBorderSelected,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppAssets.subscriptionCrown,
            width: 13.3,
            height: 12,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 5),
          Text(
            'Best Value',
            style: GoogleFonts.playfairDisplay(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              height: 1,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialUrgencySection extends StatefulWidget {
  const _TrialUrgencySection();

  @override
  State<_TrialUrgencySection> createState() => _TrialUrgencySectionState();
}

class _TrialUrgencySectionState extends State<_TrialUrgencySection> {
  static const Duration _period = Duration(hours: 4);
  static const int _slotsLeft = 9;

  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _resolveEndMillis() {
    final now = DateTime.now().millisecondsSinceEpoch;
    var end = AppStorage.trialCountdownEndsAtMillis;
    if (end == null) {
      end = now + _period.inMilliseconds;
      unawaited(AppStorage.setTrialCountdownEndsAtMillis(end));
      return end;
    }

    final periodMs = _period.inMilliseconds;
    if (end <= now) {
      final elapsed = now - end;
      final cycles = (elapsed ~/ periodMs) + 1;
      end += cycles * periodMs;
      unawaited(AppStorage.setTrialCountdownEndsAtMillis(end));
    }
    return end;
  }

  void _tick() {
    final remaining = Duration(
      milliseconds: _resolveEndMillis() - DateTime.now().millisecondsSinceEpoch,
    );
    if (!mounted) return;
    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  String get _formattedRemaining {
    var seconds = _remaining.inSeconds;
    if (seconds < 0) seconds = 0;
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  double get _progress {
    final total = _period.inMilliseconds;
    if (total <= 0) return 0;
    return (_remaining.inMilliseconds / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: AppColors.white,
            ),
            children: [
              const TextSpan(text: 'Free trials expire in '),
              TextSpan(
                text: _formattedRemaining,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: AppColors.subscriptionTrialTime,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            height: 8,
            width: double.infinity,
            child: ColoredBox(
              color: AppColors.subscriptionTrialTrack,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: _progress,
                  heightFactor: 1,
                  child: const ColoredBox(
                    color: AppColors.subscriptionPlanBorderSelected,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Only $_slotsLeft free trials slots left today.',
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 1.2,
            color: AppColors.subscriptionBenefitGold,
          ),
        ),
      ],
    );
  }
}

/// Selected plan only: gold circle + tick from Figma.
class _PlanSelectionIndicator extends StatelessWidget {
  const _PlanSelectionIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: SvgPicture.asset(
        AppAssets.subscriptionPlanCheck,
        width: 22,
        height: 22,
        fit: BoxFit.contain,
      ),
    );
  }
}
