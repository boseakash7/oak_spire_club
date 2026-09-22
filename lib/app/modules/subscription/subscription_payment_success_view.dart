import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_subscription_theme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/common_primary_button.dart';
import '../../core/widgets/gradient_text.dart';
import '../../data/models/subscription_payment_receipt.dart';
import '../../routes/subscription_payment_success_navigation.dart';

/// Shown after `package/payment-verify` (paid or failed).
class SubscriptionPaymentSuccessView extends StatelessWidget {
  const SubscriptionPaymentSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final message = SubscriptionPaymentSuccessNavigation.messageFromArguments();
    final receipt = SubscriptionPaymentSuccessNavigation.receiptFromArguments();
    final succeeded = SubscriptionPaymentSuccessNavigation.isPaymentSuccessful();

    return PopScope(
      canPop: false,
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
            ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSubscriptionTheme.horizontalPadding,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: succeeded
                            ? AppColors.goldGradient
                            : null,
                        color: succeeded ? null : const Color(0xFF3A1A1A),
                        border: succeeded
                            ? null
                            : Border.all(
                                color: const Color(0xFFE57373).withValues(alpha: 0.7),
                                width: 1.5,
                              ),
                      ),
                      child: Icon(
                        succeeded ? Icons.check_rounded : Icons.close_rounded,
                        size: 36,
                        color: succeeded ? AppColors.black : const Color(0xFFE57373),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (succeeded) ...[
                      Text(
                        'Payment',
                        style: AppTextStyles.heading32Bold().copyWith(
                          fontSize: 28,
                          height: 1.05,
                          color: AppColors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      GradientText(
                        'Successful!',
                        style: AppTextStyles.heading32Bold().copyWith(
                          fontSize: 28,
                          height: 1.05,
                        ),
                        gradient: AppColors.goldGradient,
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Text(
                        'Purchase',
                        style: AppTextStyles.heading32Bold().copyWith(
                          fontSize: 28,
                          height: 1.05,
                          color: AppColors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Failed',
                        style: AppTextStyles.heading32Bold().copyWith(
                          fontSize: 28,
                          height: 1.05,
                          color: const Color(0xFFE57373),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                        color: AppColors.textCream,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (receipt != null)
                      Expanded(
                        child: SingleChildScrollView(
                          child: _PaymentReceiptCard(
                            receipt: receipt,
                            paymentSucceeded: succeeded,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(height: 16),
                    CommonPrimaryButton(
                      label: succeeded ? 'Continue' : 'Try again',
                      onPressed:
                          SubscriptionPaymentSuccessNavigation.continueAfterPayment,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentReceiptCard extends StatelessWidget {
  const _PaymentReceiptCard({
    required this.receipt,
    required this.paymentSucceeded,
  });

  final SubscriptionPaymentReceipt receipt;
  final bool paymentSucceeded;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('MMM d, yyyy · h:mm a').format(receipt.paidAt);
    final merchant = receipt.merchantName.trim().isNotEmpty
        ? receipt.merchantName.trim()
        : AppConstants.appName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: AppColors.cardSurfaceGradient,
        borderRadius: BorderRadius.circular(AppSubscriptionTheme.priceCardRadius),
        border: Border.all(
          color: paymentSucceeded
              ? AppColors.gold1.withValues(alpha: 0.45)
              : const Color(0xFFE57373).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 22,
                color: paymentSucceeded
                    ? AppColors.gold2.withValues(alpha: 0.95)
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment receipt',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textCream,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            merchant,
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          const _ReceiptDivider(),
          const SizedBox(height: 14),
          _ReceiptRow(label: 'Plan', value: receipt.planTitle),
          _ReceiptRow(label: 'Amount', value: receipt.formattedAmount),
          _ReceiptRow(
            label: 'Status',
            value: receipt.displayStatus,
            highlight: true,
            failed: receipt.isFailed,
          ),
          _ReceiptRow(label: 'Date', value: dateText),
          _ReceiptRow(label: 'Order', value: receipt.razorpayOrderId),
          _ReceiptRow(label: 'Payment ID', value: receipt.displayPaymentId),
          const SizedBox(height: 14),
          const _ReceiptDivider(),
          const SizedBox(height: 12),
          Text(
            paymentSucceeded
                ? 'Keep this receipt for your records.'
                : 'No charge was completed. You can try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textWolf,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptDivider extends StatelessWidget {
  const _ReceiptDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: 1,
              color: AppColors.gold1.withValues(alpha: 0.35),
            );
          }),
        );
      },
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.failed = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
                color: highlight
                    ? (failed ? const Color(0xFFE57373) : AppColors.gold2)
                    : AppColors.textCream,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
