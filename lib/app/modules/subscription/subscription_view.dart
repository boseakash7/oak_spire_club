import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/animations/app_motion.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/animated_pressable.dart';
import '../../core/widgets/common_primary_button.dart';
import '../../core/widgets/gradient_text.dart';
import '../../routes/app_routes.dart';
import '../../routes/auth_navigation.dart';

/// Figma node 124:271 — IAP / subscription landing.
const double _kHorizontalPad = 35;
const double _kPriceCardHeight = 94;
const double _kPriceCardRadius = 13;
const double _kPriceCardGap = 19;
const Color _kSkipText = Color(0xFF7B7878);
const Color _kBenefitGold = Color(0xFFCA9F2E);
const Color _kBenefitGoldAlt = Color(0xFFD3AE37);
const Color _kPlanBorderSelected = Color(0xFFC89D2D);
const Color _kPlanBorderUnselected = Color(0xFF060304);
const Color _kPriceGold = Color(0xFFCA9F2E);

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  late final Razorpay _razorpay;

  static const _plans = <_Plan>[
    _Plan(
      id: 'monthly',
      title: 'Monthly',
      billingSubtitle: 'Billed every month',
      renewalNote: 'After trial will renew at \$5',
      originalPrice: 5,
      amountInr: 499,
    ),
    _Plan(
      id: 'yearly',
      title: 'Yearly',
      billingSubtitle: 'Billed every year',
      renewalNote: 'After trial will renew at \$30',
      originalPrice: 30,
      amountInr: 4499,
    ),
  ];

  String? _selectedPlanId = 'monthly';

  bool get _isPostAuth {
    final args = Get.arguments;
    return args is Map && args[AuthNavigation.postAuthSubscriptionArg] == true;
  }

  void _openSkipConfirmation() {
    Get.toNamed(
      AppRoutes.subscriptionSkip,
      arguments: _isPostAuth
          ? {AuthNavigation.postAuthSubscriptionArg: true}
          : null,
    );
  }

  _Plan? get _selectedPlan {
    for (final p in _plans) {
      if (p.id == _selectedPlanId) return p;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _onPaymentSuccess(PaymentSuccessResponse res) {
    unawaited(AppSnackbar.success('Payment successful'));
  }

  void _onPaymentError(PaymentFailureResponse res) {
    unawaited(AppSnackbar.error(res.message ?? 'Payment failed'));
  }

  void _onExternalWallet(ExternalWalletResponse res) {
    unawaited(
      AppSnackbar.info('External wallet: ${res.walletName ?? 'unknown'}'),
    );
  }

  Future<void> _startCheckout() async {
    final plan = _selectedPlan;
    if (plan == null) {
      await AppSnackbar.error('Select a plan first.');
      return;
    }

    final key = AppConstants.razorpayKeyId.trim();
    if (key.isEmpty) {
      await AppSnackbar.error(
        'Razorpay key not configured. Set AppConstants.razorpayKeyId.',
      );
      return;
    }

    final options = <String, Object?>{
      'key': key,
      'amount': plan.amountInr * 100,
      'currency': 'INR',
      'name': AppConstants.appName,
      'description': '${plan.title} subscription',
      'prefill': <String, Object?>{'contact': '', 'email': ''},
      'theme': <String, Object?>{'color': '#B9861F'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      await AppSnackbar.error(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isPostAuth,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.subscriptionBackground,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset(AppAssets.signUpBackground, fit: BoxFit.cover),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        _kHorizontalPad,
                        48,
                        _kHorizontalPad,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FadeSlideEntrance(
                            index: 0,
                            child: _SubscriptionHeader(),
                          ),
                          const SizedBox(height: 34),
                          const FadeSlideEntrance(
                            index: 1,
                            child: _BenefitRow(
                              spans: [
                                TextSpan(text: 'Track '),
                                TextSpan(
                                  text: 'unlimited',
                                  style: TextStyle(color: _kBenefitGold),
                                ),
                                TextSpan(text: ' collection value overtime.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          const FadeSlideEntrance(
                            index: 2,
                            child: _BenefitRow(
                              spans: [
                                TextSpan(text: 'Access to the '),
                                TextSpan(
                                  text: '10000+ bottles ',
                                  style: TextStyle(color: _kBenefitGold),
                                ),
                                TextSpan(text: 'database.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          const FadeSlideEntrance(
                            index: 3,
                            child: _BenefitRow(
                              spans: [
                                TextSpan(
                                  text: 'Full access',
                                  style: TextStyle(color: _kBenefitGoldAlt),
                                ),
                                TextSpan(
                                  text: ' to bottle insights and tasting.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          const FadeSlideEntrance(
                            index: 4,
                            child: _BenefitRow(
                              spans: [
                                TextSpan(
                                  text: 'No',
                                  style: TextStyle(color: Color(0xFFC89D2C)),
                                ),
                                TextSpan(text: ' daily '),
                                TextSpan(
                                  text: 'limits',
                                  style: TextStyle(color: Color(0xFFC89C2C)),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),
                          for (var i = 0; i < _plans.length; i++) ...[
                            FadeSlideEntrance(
                              index: 5 + i,
                              child: _PricePlanCard(
                                plan: _plans[i],
                                isSelected: _plans[i].id == _selectedPlanId,
                                onTap: () => setState(
                                  () => _selectedPlanId = _plans[i].id,
                                ),
                              ),
                            ),
                            if (i < _plans.length - 1)
                              const SizedBox(height: _kPriceCardGap),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _kHorizontalPad,
                      0,
                      _kHorizontalPad,
                      12,
                    ),
                    child: CommonPrimaryButton(
                      label: 'Start free - 7 days trial',
                      onPressed: _startCheckout,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openSkipConfirmation,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: _kSkipText.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Skip this for now',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: _kSkipText,
                            ),
                          ),
                        ],
                      ),
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
            fontSize: 32,
            height: 1.05,
            color: AppColors.white,
          ),
        ),
        GradientText(
          'Whiskey Wisdom.',
          style: AppTextStyles.heading32Bold().copyWith(
            fontSize: 32,
            height: 1.05,
          ),
          gradient: AppColors.goldGradient,
        ),
        const SizedBox(height: 12),
        Text(
          'Join the club now and get 50% off on life time subscription',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.25,
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
        const _BenefitCheckIcon(),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.25,
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

/// Figma pricing cards 124:314 / 129:304 — 323×94 stacked plan rows.
class _PricePlanCard extends StatelessWidget {
  const _PricePlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  final _Plan plan;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        height: _kPriceCardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kPriceCardRadius),
          gradient: AppColors.cardSurfaceGradient,
          border: Border.all(
            color: isSelected ? _kPlanBorderSelected : _kPlanBorderUnselected,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 14, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: AppColors.textCream,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.billingSubtitle,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                            color: AppColors.textCream,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TrialPriceLabel(originalPrice: plan.originalPrice),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      plan.renewalNote,
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        color: AppColors.textWolf,
                      ),
                    ),
                  ),
                  if (isSelected) const _PlanSelectionIndicator(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrialPriceLabel extends StatelessWidget {
  const _TrialPriceLabel({required this.originalPrice});

  final int originalPrice;

  @override
  Widget build(BuildContext context) {
    return Text(
      '\$$originalPrice',
      textAlign: TextAlign.right,
      style: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1,
        color: _kPriceGold,
      ),
    );
  }
}

/// Benefit list tick (Figma 29px) — icon only, no image asset.
class _BenefitCheckIcon extends StatelessWidget {
  const _BenefitCheckIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 29,
      height: 29,
      child: Icon(Icons.check_rounded, size: 29, color: AppColors.goldBright),
    );
  }
}

/// Selected plan only: gold circle + tick.
class _PlanSelectionIndicator extends StatelessWidget {
  const _PlanSelectionIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 23,
      height: 23,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.goldGradient,
      ),
      child: const Icon(Icons.check_rounded, size: 15, color: AppColors.black),
    );
  }
}

class _Plan {
  const _Plan({
    required this.id,
    required this.title,
    required this.billingSubtitle,
    required this.renewalNote,
    required this.originalPrice,
    required this.amountInr,
  });

  final String id;
  final String title;
  final String billingSubtitle;
  final String renewalNote;
  final int originalPrice;
  final int amountInr;
}
