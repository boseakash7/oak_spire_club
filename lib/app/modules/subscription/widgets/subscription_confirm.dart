// The review page between "Start free trial" and the payment sheet.
part of '../subscription_view.dart';

/// What `/subscription/confirm` shows, passed as its route arguments.
class SubscriptionConfirmArgs {
  const SubscriptionConfirmArgs._({
    required this.plan,
    required _PlanQuote quote,
    required this.trialDays,
    required this.included,
  }) : _quote = quote;

  final SubscriptionPackageModel plan;
  final _PlanQuote _quote;

  /// Free days before the first charge; 0 when there is no trial.
  final int trialDays;

  /// Premium's side of the plan cards, listed under "Included".
  final List<String> included;

  static SubscriptionConfirmArgs? fromArguments() {
    final args = Get.arguments;
    return args is SubscriptionConfirmArgs ? args : null;
  }
}

/// Confirm your plan: what is due today, when the trial ends, the first
/// charge and what renews after it, what is included and how it is paid.
/// "Confirm" pops `true`, and the subscription screen opens the payment.
class SubscriptionConfirmView extends StatelessWidget {
  const SubscriptionConfirmView({super.key});

  static final _date = DateFormat('MMM d, y');

  @override
  Widget build(BuildContext context) {
    final args = SubscriptionConfirmArgs.fromArguments();
    if (args == null) {
      // Opened without a plan (e.g. a restored route): nothing to confirm.
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back<void>());
      return const Scaffold(backgroundColor: AppColors.surfaceDeep);
    }

    final plan = args.plan;
    final quote = args._quote;
    final trial = args.trialDays > 0;
    final firstCharge = DateTime.now().add(Duration(days: args.trialDays));
    final period = plan.isYearly ? 'year' : 'month';
    final symbol = quote.charge.symbol;

    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, AppSpacing.gutter, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Get.back<bool>(result: false),
                  icon: Icon(
                    AppPlatform.backIcon,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  label: Text(
                    'Back to plans',
                    style: AppTextStyles.bodyS().copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.xs,
                  AppSpacing.gutter,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Confirm your plan',
                      style: AppTextStyles.headingM().copyWith(
                        color: AppColors.textCream,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Check the details before you pay.',
                      style: AppTextStyles.bodyS().copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Oak Spire Premium',
                                      style: AppTextStyles.bodyM().copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textCream,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      quote.offer == null
                                          ? (plan.isYearly
                                                ? 'Yearly'
                                                : 'Monthly')
                                          : '${plan.isYearly ? 'Yearly' : 'Monthly'} · ${quote.offer!.label}',
                                      style: AppTextStyles.bodyS().copyWith(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.workspace_premium_rounded,
                                size: 24,
                                color: AppColors.goldBright,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _ConfirmRow(
                            label: 'Due today',
                            value: trial ? '${symbol}0.00' : quote.charge.label,
                            strong: true,
                          ),
                          if (trial)
                            _ConfirmRow(
                              label: 'Free trial',
                              value:
                                  '${args.trialDays} ${args.trialDays == 1 ? 'day' : 'days'}, ends ${_date.format(firstCharge)}',
                            ),
                          _ConfirmRow(
                            label: trial
                                ? 'First charge · ${_date.format(firstCharge)}'
                                : 'Charged today',
                            value: quote.charge.label,
                            crossedOut: quote.regular?.label,
                            gold: quote.offer != null,
                          ),
                          _ConfirmRow(
                            label: 'Then every $period',
                            value: quote.offer == null
                                ? quote.charge.label
                                : '${quote.charge.label}, kept',
                          ),
                        ],
                      ),
                    ),
                    if (args.included.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Included',
                        style: AppTextStyles.bodyS().copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      for (final item in args.included)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.goldBright,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  item,
                                  style: AppTextStyles.bodyS().copyWith(
                                    color: AppColors.textCream,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Platform.isIOS
                                ? Icons.apple_rounded
                                : Icons.credit_card_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              Platform.isIOS
                                  ? 'Pay with the App Store'
                                  : 'Pay with Razorpay',
                              style: AppTextStyles.bodyS().copyWith(
                                color: AppColors.textCream,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CommonPrimaryButton(
                    label: trial ? 'Confirm and start trial' : 'Confirm and pay',
                    onPressed: () => Get.back<bool>(result: true),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    trial
                        ? 'Cancel before ${_date.format(firstCharge)} and you pay nothing. Manage it in Settings › Subscription.'
                        : 'Cancel anytime in Settings › Subscription.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyS().copyWith(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textMuted,
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

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.label,
    required this.value,
    this.crossedOut,
    this.strong = false,
    this.gold = false,
  });

  final String label;
  final String value;
  final String? crossedOut;
  final bool strong;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.bodyS().copyWith(
      fontSize: 12.5,
      color: AppColors.textMuted,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: muted)),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  if (crossedOut != null) ...[
                    TextSpan(
                      text: crossedOut,
                      style: muted.copyWith(
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.textMuted,
                      ),
                    ),
                    const TextSpan(text: '  '),
                  ],
                  TextSpan(
                    text: value,
                    style: AppTextStyles.bodyS().copyWith(
                      fontSize: 13,
                      fontWeight: strong || gold
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: gold ? AppColors.goldBright : AppColors.textCream,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
