import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/animations/state_switcher.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/rating_formatter.dart';
import '../../core/widgets/app_header.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/market_models.dart';
import '../../data/models/price_sparkline.dart';
import 'dashboard_controller.dart';
import 'dashboard_loading_view.dart';
import 'widgets/dashboard_bottle_list.dart';
import 'widgets/dashboard_collection_card.dart';
import 'widgets/dashboard_collection_movers.dart';
import 'widgets/dashboard_market_pulse.dart';
import 'widgets/dashboard_movers.dart';
import 'widgets/dashboard_wishlist.dart';
import '../wishlist/wishlist_controller.dart';

const double _kInset = AppSpacing.gutter;

final _shortDate = DateFormat('d MMM', 'en_US');

/// The Home tab, where the app opens. Top to bottom: the market (headline
/// index and breadth), the user's collection against it, the collection's
/// biggest moves, the wishlist, the market's biggest movers, then what collectors are
/// adding, what they hold most, the highest-rated bottles they hold, and
/// last what is newly priced. Every section is a vertical list, its
/// movements cover [DashboardController.windowDays], and each hides when it
/// has nothing to show.
class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceDeep,
      child: SafeArea(
        top: false,
        child: Obx(() {
          final loading = controller.isLoading.value;
          return AppStateSwitcher(
            stateKey: loading,
            child: loading
                ? const DashboardLoadingView()
                : const _DashboardContent(),
          );
        }),
      ),
    );
  }
}

class _DashboardContent extends GetView<DashboardController> {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: controller.refreshAll,
      child: CustomScrollView(
        physics: AppPlatform.scrollPhysics,
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(height: kShellTabBodyContentTopGap),
          ),
          SliverToBoxAdapter(
            child: Obx(() {
              final overview = controller.overview.value;
              final h = controller.highlights.value;
              final gainers = controller.gainers;
              final losers = controller.losers;
              final mine = controller.collectionMovers;
              final wishlist = WishlistController.to;
              final wanted = wishlist.highlights();
              final wantedSparks = Map<String, PriceSparkline>.of(
                wishlist.sparklines,
              );
              // Copied so this Obx rebuilds as the price lines arrive.
              final sparks = Map<String, PriceSparkline>.of(
                controller.sparklines,
              );
              const days = DashboardController.windowDays;
              final hot = DashboardController.shown(h.hot);
              final fresh = DashboardController.shown(h.newlyPriced);
              final held = DashboardController.shown(h.mostCollected);
              final rated = DashboardController.shown(h.topRated);

              // A Hero tag must be unique on screen, and a bottle can be in
              // several sections: its first appearance owns the flight.
              final claimed = <String>{};
              Set<String> claim(Iterable<String> ids) => {
                for (final id in ids)
                  if (claimed.add(id)) id,
              };
              final mineHeroes = claim([
                for (final m in mine) ?m.item.bluebookBottleId,
              ]);
              final wantedHeroes = claim([for (final w in wanted) w.bottleId]);
              final moverHeroes = claim([
                for (final b in [...gainers, ...losers]) b.id,
              ]);
              Set<String> listHeroes(List<HighlightBottle> items) =>
                  claim([for (final i in items) i.bottle.id]);

              final sections = <Widget>[
                if (overview?.index != null || h.hasBreadth)
                  DashboardMarketPulse(
                    index: overview?.index,
                    highlights: h,
                    lastUpdated: overview?.lastUpdated,
                  ),
                DashboardCollectionCard(
                  index: overview?.index,
                  onOpen: controller.openCollection,
                  onAddFirst: controller.addFirstBottle,
                ),
                if (mine.isNotEmpty)
                  DashboardCollectionMovers(
                    movers: mine,
                    windowDays: days,
                    heroIds: mineHeroes,
                    onOpen: (id) => controller.logOpen('your_movers', id),
                  ),
                if (wanted.isNotEmpty)
                  DashboardWishlist(
                    items: wanted,
                    atTargetCount: wishlist.atTargetCount,
                    sparklines: wantedSparks,
                    heroIds: wantedHeroes,
                    onSeeAll: controller.openWishlist,
                    onOpen: (id) => controller.logOpen('wishlist', id),
                  ),
                if (gainers.isNotEmpty || losers.isNotEmpty)
                  DashboardMovers(
                    gainers: gainers,
                    losers: losers,
                    windowDays: overview?.windowDays ?? days,
                    sparklines: sparks,
                    heroIds: moverHeroes,
                    onSeeAll: controller.openAllPerformers,
                    onOpen: (id) => controller.logOpen('movers', id),
                    onDirectionChanged: controller.logMoversToggle,
                  ),
                if (hot.isNotEmpty)
                  DashboardBottleList(
                    section: 'hot',
                    title: 'Hot with collectors',
                    subtitle: 'Most added to collections in the last 30 days',
                    items: hot,
                    captionOf: (i) => 'Added by ${_collectors(i.added30d)}',
                    sparklines: sparks,
                    heroIds: listHeroes(hot),
                    onOpen: controller.logOpen,
                  ),
                if (held.isNotEmpty)
                  DashboardBottleList(
                    section: 'most_collected',
                    title: 'Most collected',
                    subtitle: 'The bottles Oak Spire collectors hold most',
                    items: held,
                    captionOf: (i) => 'Held by ${_collectors(i.collectors)}',
                    sparklines: sparks,
                    heroIds: listHeroes(held),
                    onOpen: controller.logOpen,
                  ),
                if (rated.isNotEmpty)
                  DashboardBottleList(
                    section: 'top_rated',
                    title: 'Top rated in collections',
                    subtitle: 'The highest-rated bottles collectors own',
                    items: rated,
                    captionOf: (i) =>
                        '★ ${RatingFormatter.labelOutOfTen(i.bottle.rating)}'
                        ' · held by ${i.collectors ?? '—'}',
                    sparklines: sparks,
                    heroIds: listHeroes(rated),
                    onOpen: controller.logOpen,
                  ),
                if (fresh.isNotEmpty)
                  DashboardBottleList(
                    section: 'new',
                    title: 'New to the market',
                    subtitle: 'First priced in the last 30 days',
                    items: fresh,
                    captionOf: (i) => i.firstPricedOn == null
                        ? 'Newly priced'
                        : 'First priced ${_shortDate.format(i.firstPricedOn!)}',
                    sparklines: sparks,
                    heroIds: listHeroes(fresh),
                    onOpen: controller.logOpen,
                  ),
              ];

              return StaggeredColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in sections)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _kInset,
                        0,
                        _kInset,
                        AppSpacing.xl,
                      ),
                      child: s,
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  static String _collectors(int? n) =>
      n == null ? 'collectors' : '$n ${n == 1 ? 'collector' : 'collectors'}';
}
