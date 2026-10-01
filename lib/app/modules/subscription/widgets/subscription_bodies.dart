// The three screen bodies (checkout, backend-granted premium, active plan)
// and the pieces they share: header, benefits, limit banner, skip link.
part of '../subscription_view.dart';

class _CheckoutSubscriptionBody extends StatelessWidget {
  const _CheckoutSubscriptionBody({
    required this.subscription,
    required this.useAppleStorePrices,
    required this.applePriceForPlan,
    required this.isLoadingApplePrices,
    required this.isTrialOffer,
    required this.checkoutButtonLabel,
    required this.isCheckoutLoading,
    required this.onCheckout,
  });

  final SubscriptionController subscription;
  final bool useAppleStorePrices;
  final String? Function(SubscriptionPackageModel plan) applePriceForPlan;
  final bool isLoadingApplePrices;
  final bool isTrialOffer;
  final String checkoutButtonLabel;
  final bool isCheckoutLoading;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeSlideEntrance(index: 0, child: _SubscriptionHeader()),
        const SizedBox(height: 34),
        const FadeSlideEntrance(
          index: 1,
          child: _BenefitRow(
            spans: [
              TextSpan(text: 'Track '),
              TextSpan(
                text: 'unlimited',
                style: TextStyle(color: AppColors.subscriptionBenefitGold),
              ),
              TextSpan(text: ' collection value overtime.'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const FadeSlideEntrance(
          index: 2,
          child: _BenefitRow(
            spans: [
              TextSpan(text: 'Access to the '),
              TextSpan(
                text: '10000+ bottles ',
                style: TextStyle(color: AppColors.subscriptionBenefitGold),
              ),
              TextSpan(text: 'database.'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const FadeSlideEntrance(
          index: 3,
          child: _BenefitRow(
            spans: [
              TextSpan(
                text: 'Full access',
                style: TextStyle(color: AppColors.subscriptionBenefitGoldAlt),
              ),
              TextSpan(text: ' to bottle insights and tasting.'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const FadeSlideEntrance(
          index: 4,
          child: _BenefitRow(
            spans: [
              TextSpan(
                text: 'No',
                style: TextStyle(
                  color: AppColors.subscriptionBenefitLimitsPrimary,
                ),
              ),
              TextSpan(text: ' daily '),
              TextSpan(
                text: 'limits',
                style: TextStyle(
                  color: AppColors.subscriptionBenefitLimitsSecondary,
                ),
              ),
              TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSubscriptionTheme.planBlockInset,
          ),
          child: _PackagePlanList(
            subscription: subscription,
            useAppleStorePrices: useAppleStorePrices,
            applePriceForPlan: applePriceForPlan,
            isLoadingApplePrices: isLoadingApplePrices,
          ),
        ),
        if (isTrialOffer) ...[
          const SizedBox(height: 36),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSubscriptionTheme.planBlockInset,
            ),
            child: _TrialUrgencySection(),
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 36),
        CommonPrimaryButton(
          label: checkoutButtonLabel,
          isLoading: isCheckoutLoading,
          onPressed: onCheckout,
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1,
            color: AppColors.black,
          ),
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

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.spans});

  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: _BenefitCheckIcon(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.5,
                color: AppColors.white,
              ),
              children: spans,
            ),
          ),
        ),
      ],
    );
  }
}

/// Benefit list tick (Figma 29px) — exported check vector in 29×29 frame.
class _BenefitCheckIcon extends StatelessWidget {
  const _BenefitCheckIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 7, 3.5, 7.5),
        child: SvgPicture.asset(
          AppAssets.subscriptionBenefitCheck,
          width: 19.53,
          height: 13.5,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

/// Selected plan only: gold circle + tick from Figma.

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

/// Benefit list tick (Figma 29px) — exported check vector in 29×29 frame.
