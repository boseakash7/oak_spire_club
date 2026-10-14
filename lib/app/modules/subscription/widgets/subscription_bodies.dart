// The three screen bodies (checkout, backend-granted premium, active plan)
// and the pieces they share: headers, limit banner, skip link.
part of '../subscription_view.dart';

class _CheckoutSubscriptionBody extends StatelessWidget {
  const _CheckoutSubscriptionBody({
    required this.subscription,
    required this.quoteFor,
    required this.isLoadingStorePrices,
    required this.trialDaysFor,
    required this.checkoutButtonLabel,
    required this.isCheckoutLoading,
    required this.onCheckout,
    required this.onOfferEnded,
  });

  final SubscriptionController subscription;
  final _PlanQuote Function(SubscriptionPackageModel plan) quoteFor;
  final bool isLoadingStorePrices;

  /// Free days a subscription to this plan starts with; 0 for none.
  final int Function(SubscriptionPackageModel plan) trialDaysFor;
  final String checkoutButtonLabel;
  final bool isCheckoutLoading;
  final VoidCallback onCheckout;

  /// The offer's countdown reached zero: rebuild without it.
  final VoidCallback onOfferEnded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FadeSlideEntrance(index: 0, child: _CheckoutHeader()),
        const SizedBox(height: AppSpacing.lg),
        Obx(() {
          if (subscription.isLoadingPackages.value || isLoadingStorePrices) {
            return const SizedBox.shrink();
          }
          // The first plan with a running offer (only the yearly, usually).
          for (final plan in subscription.packages) {
            final quote = quoteFor(plan);
            final offer = quote.offer;
            if (offer == null) continue;
            final now = quote.charge.amount;
            final was = quote.regular?.amount;
            final off = now != null && was != null && was > 0
                ? ((1 - now / was) * 100).round()
                : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: FadeSlideEntrance(
                index: 1,
                child: _OfferBanner(
                  key: ValueKey('${plan.id}-${offer.endsAt}'),
                  offer: offer,
                  planLabel: plan.isYearly ? 'Yearly plan' : 'Monthly plan',
                  discountPercent: off != null && off > 0 ? off : null,
                  onTap: () => subscription.selectPackage(plan.id),
                  onEnded: onOfferEnded,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        FadeSlideEntrance(
          index: 2,
          child: Obx(() {
            final rows = subscription.limits.value.comparisonRows();
            if (rows.isEmpty) return const SizedBox.shrink();
            return _PlanCards(rows: rows);
          }),
        ),
        const SizedBox(height: AppSpacing.xl),
        FadeSlideEntrance(
          index: 3,
          child: _PlanSwitch(subscription: subscription, quoteFor: quoteFor),
        ),
        const SizedBox(height: AppSpacing.lg),
        FadeSlideEntrance(
          index: 4,
          child: _SelectedPlanPrice(
            subscription: subscription,
            quoteFor: quoteFor,
            isLoadingStorePrices: isLoadingStorePrices,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        CommonPrimaryButton(
          label: checkoutButtonLabel,
          isLoading: isCheckoutLoading,
          onPressed: onCheckout,
        ),
        const SizedBox(height: AppSpacing.sm),
        Obx(() {
          final plan = subscription.selectedPackage;
          if (plan == null || isLoadingStorePrices) {
            return const SizedBox.shrink();
          }
          final quote = quoteFor(plan);
          final price =
              '${quote.charge.label}/${plan.isYearly ? 'year' : 'month'}';
          final days = trialDaysFor(plan);
          final String line;
          if (days > 0) {
            line =
                '$days-day free trial, then $price. Cancel anytime.';
          } else {
            line = '$price. Renews until you cancel.';
          }
          return Text(
            line,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyS().copyWith(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          );
        }),
      ],
    );
  }
}

/// Above the checkout: × on the left, and "Restore" on the right when
/// [onRestore] is set (iOS, for App Store purchases).
class _CheckoutTopBar extends StatelessWidget {
  const _CheckoutTopBar({required this.onClose, this.onRestore});

  final VoidCallback onClose;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onClose,
          tooltip: 'Close',
          icon: const Icon(
            Icons.close_rounded,
            size: 22,
            color: AppColors.textMuted,
          ),
        ),
        const Spacer(),
        if (onRestore != null)
          TextButton(
            onPressed: onRestore,
            child: Text(
              'Restore',
              style: AppTextStyles.bodyS().copyWith(
                color: AppColors.subscriptionSkipLink,
              ),
            ),
          ),
      ],
    );
  }
}

/// Checkout heading: "Unlock your whiskey wisdom", the second half in gold.
class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader();

  @override
  Widget build(BuildContext context) {
    final heading = AppTextStyles.heading32Bold().copyWith(
      fontSize: 28,
      height: 1.25,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unlock your', style: heading.copyWith(color: AppColors.white)),
        GradientText(
          'whiskey wisdom',
          style: heading,
          gradient: AppColors.goldGradient,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'See what Premium adds to your club.',
          style: AppTextStyles.bodyS().copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _FreeUserSubscriptionBody extends StatelessWidget {
  const _FreeUserSubscriptionBody();

  @override
  Widget build(BuildContext context) {
    final user = Get.find<UserSessionController>().user.value;
    final planName = user?.activePlanLabel ?? 'Premium';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FadeSlideEntrance(index: 0, child: _SubscriptionHeader()),
        const SizedBox(height: 28),
        FadeSlideEntrance(
          index: 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: AppColors.cardSurfaceGradient,
              border: Border.all(color: AppColors.gold2, width: 1),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 40,
                  color: AppColors.goldBright,
                ),
                const SizedBox(height: 16),
                Text(
                  'You are a Free user',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading32Bold().copyWith(
                    fontSize: 22,
                    color: AppColors.textCream,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You can use all premium features on $planName.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    height: 1.35,
                    color: AppColors.textCream,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveSubscriptionBody extends StatelessWidget {
  const _ActiveSubscriptionBody({
    required this.subscription,
    required this.onCancel,
  });

  final SubscriptionController subscription;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final user = Get.find<UserSessionController>().user.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          final loading = subscription.isCancelling.value;
          final canCancel = subscription.canCancelSubscription;
          final historyLoading = subscription.isLoadingHistory.value;
          final needsHistory = subscription.isRazorpayGateway;

          return FadeSlideEntrance(
            index: 0,
            child: _CurrentPlanSummaryCard(
              user: user,
              actionLabel: 'Cancel subscription',
              onAction: onCancel,
              actionLoading: loading,
              actionEnabled: canCancel && (!needsHistory || !historyLoading),
              showAction: subscription.canShowCancelSubscription,
            ),
          );
        }),
        const SizedBox(height: 28),
        FadeSlideEntrance(
          index: 1,
          child: Text(
            'Subscription history',
            style: AppTextStyles.heading32Bold().copyWith(
              fontSize: 20,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _TransactionHistorySection(subscription: subscription),
      ],
    );
  }
}

class _CurrentPlanSummaryCard extends StatelessWidget {
  const _CurrentPlanSummaryCard({
    required this.user,
    this.actionLabel,
    this.onAction,
    this.actionLoading = false,
    this.actionEnabled = true,
    this.showAction = false,
  });

  final UserModel? user;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool actionLoading;
  final bool actionEnabled;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final planName = user?.activePlanLabel ?? 'Premium';
    final billing = user?.subscriptionType?.trim();
    final price = user?.packagePrice?.trim();
    final isDestructiveAction =
        actionLabel?.toLowerCase().contains('cancel') == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: AppColors.cardSurfaceGradient,
        border: Border.all(
          color: AppColors.subscriptionPlanBorderSelected,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Active subscription',
            style: GoogleFonts.roboto(fontSize: 12, color: AppColors.textWolf),
          ),
          const SizedBox(height: 6),
          Text(
            planName,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textCream,
            ),
          ),
          if (billing != null && billing.isNotEmpty && billing != 'null') ...[
            const SizedBox(height: 4),
            Text(
              'Billed ${billing.toLowerCase()}',
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: AppColors.textWolf,
              ),
            ),
          ],
          if (price != null && price.isNotEmpty && price != 'null') ...[
            const SizedBox(height: 8),
            Text(
              r'$' + price,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.subscriptionPriceLabel,
              ),
            ),
          ],
          if (showAction &&
              actionLabel != null &&
              actionLabel!.isNotEmpty &&
              onAction != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: actionEnabled && !actionLoading ? onAction : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: actionLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold1,
                          ),
                        )
                      : Text(
                          actionLabel!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: actionEnabled
                                ? (isDestructiveAction
                                      ? AppColors.errorLight
                                      : AppColors.subscriptionSkipLink)
                                : AppColors.textWolf.withValues(alpha: 0.5),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown when an API returns `LIMIT_EXCEEDED` and routes here.
class _SubscriptionLimitBanner extends StatelessWidget {
  const _SubscriptionLimitBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold2, width: 1),
      ),
      child: Text(
        message,
        style: AppTextStyles.body16().copyWith(
          fontSize: 14,
          height: 1.35,
          color: AppColors.textCream,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SubscriptionHeader extends StatelessWidget {
  const _SubscriptionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unlock Your',
          style: AppTextStyles.heading32Bold().copyWith(
            fontSize: 28,
            height: 1.5,
            color: AppColors.white,
          ),
        ),
        GradientText(
          'Whiskey Wisdom.',
          style: AppTextStyles.heading32Bold().copyWith(
            fontSize: 28,
            height: 1.5,
          ),
          gradient: AppColors.goldGradient,
        ),
        Text(
          'Join the club now and get 50% off on life time subscription',
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

class _SkipThisForNowLink extends StatelessWidget {
  const _SkipThisForNowLink();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.flip(
          flipX: true,
          child: SvgPicture.asset(
            AppAssets.subscriptionSkipChevron,
            width: 9,
            height: 14,
            fit: BoxFit.fill,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Skip this for now',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1,
            color: AppColors.subscriptionSkipLink,
          ),
        ),
      ],
    );
  }
}
