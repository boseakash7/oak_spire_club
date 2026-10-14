// Checkout pieces: the offer banner, the Free / Premium plan cards, the
// Monthly / Yearly switch and the selected plan's price.
part of '../subscription_view.dart';

/// One price as the screen shows it: the App Store's localized price on iOS,
/// the server's USD price elsewhere.
class _PlanPrice {
  const _PlanPrice({required this.label, this.amount, this.symbol = r'$'});

  /// The full price, e.g. `$25` or `₹2,099.00`.
  final String label;

  /// The number behind [label], for the per-month line. Null hides it.
  final double? amount;
  final String symbol;
}

/// What a plan costs if bought now: [charge], and while an [offer] runs the
/// package's own price as [regular], shown crossed out.
class _PlanQuote {
  const _PlanQuote({required this.charge, this.regular, this.offer});

  final _PlanPrice charge;
  final _PlanPrice? regular;
  final PackageOffer? offer;
}

/// The running offer: its label, the plan it is on, and a countdown to its
/// real end (admin > Packages > Offer). Tapping it picks that plan. When the
/// time is up it calls [onEnded] so the screen drops the offer.
class _OfferBanner extends StatefulWidget {
  const _OfferBanner({
    super.key,
    required this.offer,
    required this.planLabel,
    required this.discountPercent,
    required this.onTap,
    required this.onEnded,
  });

  final PackageOffer offer;
  final String planLabel;
  final int? discountPercent;
  final VoidCallback onTap;
  final VoidCallback onEnded;

  @override
  State<_OfferBanner> createState() => _OfferBannerState();
}

class _OfferBannerState extends State<_OfferBanner> {
  static final _endFormat = DateFormat('MMM d, h:mm a');

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!widget.offer.isRunning(DateTime.now())) {
        _timer?.cancel();
        widget.onEnded();
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
    final offer = widget.offer;
    final title = widget.discountPercent == null
        ? offer.label
        : '${offer.label} · ${widget.discountPercent}% off';
    final muted = AppTextStyles.bodyS().copyWith(
      fontSize: 11,
      color: AppColors.textMuted,
    );

    return AppPressable(
      onTap: widget.onTap,
      haptic: PressHaptic.selection,
      semanticLabel: '$title, ends ${_endFormat.format(offer.endsAt)}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(
          color: AppColors.subscriptionOfferSurface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.subscriptionOfferBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 18,
              color: AppColors.goldBright,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    '${widget.planLabel} · ends ${_endFormat.format(offer.endsAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Ends in', style: muted),
                Text(
                  offer.countdownAt(DateTime.now()),
                  style: AppTextStyles.bodyS().copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textCream,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Free and Premium side by side, from `package/limits` (admin > Plan
/// limits): Free small and dim, Premium larger with a gold edge and a crown.
class _PlanCards extends StatelessWidget {
  const _PlanCards({required this.rows});

  final List<PlanComparisonRow> rows;

  static IconData _icon(PlanFeature kind) => switch (kind) {
    PlanFeature.collection => Icons.liquor_rounded,
    PlanFeature.insights => Icons.show_chart_rounded,
    PlanFeature.searches => Icons.search_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                decoration: BoxDecoration(
                  color: AppColors.subscriptionFreeCard,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free',
                      style: AppTextStyles.bodyS().copyWith(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r'$0',
                      style: AppTextStyles.headingM().copyWith(
                        fontSize: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    for (final row in rows)
                      _PlanItem(
                        icon: row.freeLocked
                            ? Icons.lock_outline_rounded
                            : _icon(row.kind),
                        text: row.free,
                        premium: false,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            flex: 12,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 20, 10, 12),
                    decoration: BoxDecoration(
                      color: AppColors.subscriptionOfferSurface,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(
                        color: AppColors.subscriptionPlanBorderSelected,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The full club',
                          style: AppTextStyles.headingM().copyWith(
                            fontSize: 18,
                            color: AppColors.goldBright,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        for (final row in rows)
                          _PlanItem(
                            icon: row.premiumLocked
                                ? Icons.lock_outline_rounded
                                : _icon(row.kind),
                            text: row.premium,
                            premium: true,
                          ),
                      ],
                    ),
                  ),
                ),
                const Positioned(left: 12, top: 0, child: _PremiumTag()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumTag extends StatelessWidget {
  const _PremiumTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 12,
            color: AppColors.black,
          ),
          const SizedBox(width: 4),
          Text(
            'Premium',
            style: AppTextStyles.bodyS().copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanItem extends StatelessWidget {
  const _PlanItem({
    required this.icon,
    required this.text,
    required this.premium,
  });

  final IconData icon;
  final String text;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: premium ? AppColors.goldBright : AppColors.textWolf,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyS().copyWith(
                fontSize: 12,
                height: 1.25,
                color: premium ? AppColors.textCream : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Monthly / Yearly as one pill, one segment per package. A plan with a
/// running offer says so; otherwise Yearly names its saving against twelve
/// months of the monthly plan.
class _PlanSwitch extends StatelessWidget {
  const _PlanSwitch({required this.subscription, required this.quoteFor});

  final SubscriptionController subscription;
  final _PlanQuote Function(SubscriptionPackageModel plan) quoteFor;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (subscription.isLoadingPackages.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
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
      final plans = subscription.packages.toList();
      if ((error != null && error.isNotEmpty) || plans.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            error != null && error.isNotEmpty
                ? error
                : 'No subscription plans available.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyS().copyWith(color: AppColors.textWolf),
          ),
        );
      }

      final selectedId = subscription.selectedPackageId.value;
      final saving = PlanPricing.yearlySavingPercent(
        monthly: _chargeOf(plans, yearly: false),
        yearly: _chargeOf(plans, yearly: true),
      );

      String label(SubscriptionPackageModel plan) {
        final name = plan.isYearly ? 'Yearly' : 'Monthly';
        if (quoteFor(plan).offer != null) return '$name · offer';
        if (plan.isYearly && saving != null) return '$name · save $saving%';
        return name;
      }

      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.cardSurfaceTop,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            for (final plan in plans)
              Expanded(
                child: _SwitchSegment(
                  label: label(plan),
                  selected: plan.id == selectedId,
                  onTap: () => subscription.selectPackage(plan.id),
                ),
              ),
          ],
        ),
      );
    });
  }

  double? _chargeOf(
    List<SubscriptionPackageModel> plans, {
    required bool yearly,
  }) {
    for (final p in plans) {
      if (p.isYearly == yearly) return quoteFor(p).charge.amount;
    }
    return null;
  }
}

class _SwitchSegment extends StatelessWidget {
  const _SwitchSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.selection,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.fast),
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.goldGradient : null,
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyS().copyWith(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? AppColors.black : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// The selected plan's price, large, with "/ month" or "/ year". During an
/// offer the package's own price sits crossed out beside it and the line
/// under says the price is kept; otherwise a yearly plan shows what it comes
/// to a month.
class _SelectedPlanPrice extends StatelessWidget {
  const _SelectedPlanPrice({
    required this.subscription,
    required this.quoteFor,
    required this.isLoadingStorePrices,
  });

  final SubscriptionController subscription;
  final _PlanQuote Function(SubscriptionPackageModel plan) quoteFor;
  final bool isLoadingStorePrices;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final plan = subscription.selectedPackage;
      if (plan == null || subscription.isLoadingPackages.value) {
        return const SizedBox.shrink();
      }
      if (isLoadingStorePrices) {
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold1,
            ),
          ),
        );
      }
      final quote = quoteFor(plan);
      final amount = quote.charge.amount;
      final muted = AppTextStyles.bodyS().copyWith(color: AppColors.textMuted);
      final regular = quote.regular;

      final String note;
      if (quote.offer != null) {
        note = 'Price kept while you stay subscribed';
      } else if (plan.isYearly && amount != null && amount > 0) {
        note =
            '${quote.charge.symbol}${PlanPricing.amount(PlanPricing.perMonth(amount))} a month';
      } else {
        note = plan.billingSubtitle;
      }

      return Column(
        children: [
          Text.rich(
            TextSpan(
              children: [
                if (regular != null) ...[
                  TextSpan(
                    text: regular.label,
                    style: muted.copyWith(
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.textMuted,
                    ),
                  ),
                  const TextSpan(text: '  '),
                ],
                TextSpan(
                  text: quote.charge.label,
                  style: AppTextStyles.headingL().copyWith(
                    fontSize: 34,
                    color: AppColors.subscriptionPriceLabel,
                  ),
                ),
                TextSpan(
                  text: plan.isYearly ? ' / year' : ' / month',
                  style: muted,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          // Always one line under the price, so the button below holds still
          // when the plan changes.
          const SizedBox(height: 4),
          Text(
            note,
            textAlign: TextAlign.center,
            style: muted.copyWith(
              fontSize: 12,
              color: quote.offer != null
                  ? AppColors.goldBright
                  : AppColors.textMuted,
            ),
          ),
        ],
      );
    });
  }
}
