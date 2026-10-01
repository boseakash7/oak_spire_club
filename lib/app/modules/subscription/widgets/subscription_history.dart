// Manage mode: past payments.
part of '../subscription_view.dart';

String _formatTransactionDate(int unixSeconds) {
  if (unixSeconds <= 0) return '—';
  final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
  return DateFormat('MMM d, yyyy').format(dt);
}

class _TransactionHistorySection extends StatelessWidget {
  const _TransactionHistorySection({required this.subscription});

  final SubscriptionController subscription;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (subscription.isLoadingHistory.value) {
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

      final error = subscription.historyError.value;
      if (error != null && error.isNotEmpty) {
        return Text(
          error,
          style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textWolf),
        );
      }

      final items = subscription.transactionHistory;
      if (items.isEmpty) {
        return Text(
          'No subscription history yet.',
          style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textWolf),
        );
      }

      return Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            FadeSlideEntrance(
              index: 3 + i,
              child: _TransactionHistoryTile(item: items[i]),
            ),
            if (i < items.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    });
  }
}

class _TransactionHistoryTile extends StatelessWidget {
  const _TransactionHistoryTile({required this.item});

  final PackageTransactionModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: AppColors.cardSurfaceGradient,
        border: Border.all(
          color: AppColors.subscriptionPlanBorderUnselected,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.packageName.isNotEmpty
                      ? item.packageName
                      : 'Subscription',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textCream,
                  ),
                ),
              ),
              Text(
                item.displayAmount,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.subscriptionPriceLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatTransactionDate(item.displayTimestamp),
            style: GoogleFonts.roboto(fontSize: 12, color: AppColors.textWolf),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.displayStatus} · ${item.planType.isNotEmpty ? item.planType : item.packageType}',
            style: GoogleFonts.roboto(fontSize: 11, color: AppColors.textWolf),
          ),
        ],
      ),
    );
  }
}

/// Shown when an API returns `LIMIT_EXCEEDED` and routes here.
