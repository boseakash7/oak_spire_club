import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/analytics/app_analytics_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../routes/app_routes.dart';

void _openPremium(String source) {
  if (Get.isRegistered<AppAnalyticsController>()) {
    unawaited(AppAnalyticsController.to.logTap('search_limit_premium', {
      'source': source,
    }));
  }
  Get.toNamed(AppRoutes.subscription);
}

/// In place of search results once today's free searches are used up
/// ([PagedBottleSearch.searchLimitReached]): Go Premium, or clear the search
/// and browse, which stays free.
class SearchLimitReachedState extends StatelessWidget {
  const SearchLimitReachedState({
    super.key,
    required this.onClear,
    this.source = 'list',
  });

  final VoidCallback onClear;

  /// Which screen, for analytics.
  final String source;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'You’ve used today’s free searches',
          message:
              'They come back tomorrow. Go Premium for unlimited search, or '
              'browse by category in the meantime.',
          actionLabel: 'Go Premium',
          onAction: () => _openPremium(source),
        ),
        TextButton(
          onPressed: onClear,
          child: Text(
            'Clear search',
            style: AppTextStyles.bodyM().copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// "3 free searches left today" under a search field, for a free plan while
/// a search is shown. [left] null hides it.
class SearchesLeftCaption extends StatelessWidget {
  const SearchesLeftCaption({super.key, required this.left, this.source = ''});

  final int? left;

  /// Which screen, for analytics.
  final String source;

  @override
  Widget build(BuildContext context) {
    final n = left;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: n == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 14,
                    color: AppColors.textWolf,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      n == 0
                          ? 'That was your last free search today'
                          : '$n free ${n == 1 ? 'search' : 'searches'} '
                                'left today',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.textWolf,
                      ),
                    ),
                  ),
                  AppPressable(
                    onTap: () => _openPremium(source),
                    haptic: PressHaptic.tap,
                    semanticLabel: 'Go Premium for unlimited search',
                    child: Text(
                      'Go unlimited',
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.goldBright,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
