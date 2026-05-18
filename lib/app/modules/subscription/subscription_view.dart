import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/common_primary_button.dart';
import '../../core/widgets/gradient_text.dart';
import '../../modules/session/user_session_controller.dart';

/// Figma node 124:271 — subscription landing layout.
const double _kHorizontalPad = 35;
const double _kPriceCardHeight = 94;
const double _kPriceCardRadius = 13;
const double _kPriceCardGap = 18;
const Color _kSkipText = Color(0xFF7B7878);
const Color _kBenefitGold = Color(0xFFCA9F2E);
const Color _kBenefitGoldAlt = Color(0xFFD3AE37);

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  late final Razorpay _razorpay;

  static const _plans = <_Plan>[
    _Plan(id: 'monthly', label: 'monthly', amountInr: 499),
    _Plan(id: 'yearly', label: 'yearly', amountInr: 4499),
  ];

  String? _selectedPlanId = 'monthly';

  bool get _trialAvailable {
    if (!Get.isRegistered<UserSessionController>()) return true;
    return Get.find<UserSessionController>().user.value?.packageId == null;
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
      'description': '${plan.label} subscription',
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
    return Scaffold(
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                    padding: const EdgeInsets.only(left: 12),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      _kHorizontalPad,
                      8,
                      _kHorizontalPad,
                      24,
                    ),
                    child: Column(
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
                        const SizedBox(height: 34),
                        const _BenefitRow(
                          spans: [
                            TextSpan(text: 'Track '),
                            TextSpan(
                              text: 'unlimited',
                              style: TextStyle(color: _kBenefitGold),
                            ),
                            TextSpan(text: ' collection value overtime.'),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const _BenefitRow(
                          spans: [
                            TextSpan(text: 'Access to the '),
                            TextSpan(
                              text: '10000+ bottles ',
                              style: TextStyle(color: _kBenefitGold),
                            ),
                            TextSpan(text: 'database.'),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const _BenefitRow(
                          spans: [
                            TextSpan(
                              text: 'Full access',
                              style: TextStyle(color: _kBenefitGoldAlt),
                            ),
                            TextSpan(text: ' to bottle insights and tasting.'),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const _BenefitRow(
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
                        const SizedBox(height: 36),
                        for (var i = 0; i < _plans.length; i++) ...[
                          _PricePlanCard(
                            plan: _plans[i],
                            trialAvailable: _trialAvailable,
                            isSelected: _plans[i].id == _selectedPlanId,
                            onTap: () =>
                                setState(() => _selectedPlanId = _plans[i].id),
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
                  onTap: () => Get.back(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: Text(
                        'Skip this for now',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kSkipText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        const Icon(Icons.check_rounded, size: 29, color: AppColors.goldBright),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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

/// Figma rectangles 124:314 / 124:315 — stacked price plan cards (323×94).
class _PricePlanCard extends StatelessWidget {
  const _PricePlanCard({
    required this.plan,
    required this.trialAvailable,
    required this.isSelected,
    required this.onTap,
  });

  final _Plan plan;
  final bool trialAvailable;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kPriceCardRadius),
        child: Ink(
          height: _kPriceCardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kPriceCardRadius),
            gradient: AppColors.cardSurfaceGradient,
            border: Border.all(
              color: isSelected ? AppColors.black : Colors.transparent,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  plan.label,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '₹${plan.amountInr}',
                  style: AppTextStyles.heading32Bold().copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    height: 1,
                    color: AppColors.white,
                  ),
                ),
                if (trialAvailable)
                  Text(
                    '7 day free trial',
                    style: AppTextStyles.body16().copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                    ),
                  )
                else
                  const SizedBox(width: 72),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Plan {
  const _Plan({required this.id, required this.label, required this.amountInr});

  final String id;
  final String label;
  final int amountInr;
}
