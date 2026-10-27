import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/storage/app_storage.dart';
import '../../data/models/bluebook_model.dart';
import '../../data/models/collection_item_display.dart';
import '../../data/models/collection_item_model.dart';
import '../../data/models/market_models.dart';
import '../../data/models/price_sparkline.dart';
import '../../data/models/subscription_package_model.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/market_repository.dart';
import '../../data/repositories/package_repository.dart';
import '../../routes/app_routes.dart';
import '../home/home_controller.dart';
import '../navigation/bottom_nav_controller.dart';
import '../collection/collection_controller.dart';
import '../session/user_session_controller.dart';
import '../wishlist/wishlist_controller.dart';
import 'widgets/dashboard_premium_card.dart';

/// The Home tab: the market at a glance (headline index, breadth, the
/// biggest movers), the user's collection against it, what other collectors
/// hold, add and rate, and newly priced bottles (`market/highlights`). Every movement on it
/// covers [windowDays], and every bottle row carries its price line over
/// that window.
///
/// The collection card reads [HomeController], which already loads the
/// collection and its chart for the Collection tab. Every market part is
/// optional: an older server, or one before the nightly job's first run, just
/// leaves those sections out.
class DashboardController extends GetxController {
  DashboardController({
    required MarketRepository marketRepo,
    required BluebookRepository bluebookRepo,
    required PackageRepository packageRepo,
  }) : _marketRepo = marketRepo,
       _bluebookRepo = bluebookRepo,
       _packageRepo = packageRepo;

  final MarketRepository _marketRepo;
  final BluebookRepository _bluebookRepo;
  final PackageRepository _packageRepo;

  final overview = Rxn<MarketOverview>();
  final highlights = MarketHighlights.empty.obs;

  /// Price lines over [windowDays] for every bottle row on the page, keyed
  /// by bottle id.
  final sparklines = <String, PriceSparkline>{}.obs;

  /// True until the first load settles (the skeleton shows meanwhile).
  final isLoading = true.obs;

  /// The window every Home movement covers, in days.
  static const int windowDays = 90;

  /// The window the movers and breadth fall back to when no bottle has a
  /// price from [windowDays] ago yet (a young price history).
  static const int fallbackDays = 30;

  /// Rows shown per list: the collection's movers and each community list.
  static const int rowsShown = 3;

  /// Rows per direction in "Biggest movers" (one direction shows at a time).
  static const int moversShown = 5;

  HomeController get _home => Get.find<HomeController>();

  /// Set at sign-up (`AppStorage.setWelcomePending`) for the new user.
  final welcomePending = false.obs;

  /// The welcome card shows, in place of the Premium card and the empty
  /// collection card, until the first bottle is in or the user closes it.
  bool get welcomeVisible =>
      welcomePending.value && !_home.hasCollection.value;

  /// True while the welcome card is lifted, with the rest of Home blurred
  /// behind it, until the user taps anywhere else. Plays once per user.
  final welcomeSpotlight = false.obs;

  /// Whether the welcome card should lift when it first shows.
  bool get welcomeSpotlightDue =>
      welcomeVisible &&
      !AppStorage.isWelcomeSpotlightSeenFor(AppStorage.userId);

  /// The offer the Premium card shows instead of its trial button, while a
  /// package's offer runs. Null when none does.
  final premiumOffer = Rxn<({PackageOffer offer, int? percentOff})>();

  @override
  void onInit() {
    super.onInit();
    welcomePending.value = AppStorage.isWelcomePendingFor(AppStorage.userId);
    if (welcomePending.value && Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logScreenView('home_welcome'));
    }
    // The first bottle finishes the welcome for good.
    ever<bool>(_home.hasCollection, (has) {
      if (has && welcomePending.value) unawaited(_endWelcome());
    });
    // The collection loads on its own schedule (HomeController); its rows'
    // price lines follow whenever it changes.
    ever<List<CollectionItemModel>>(
      _home.items,
      (_) => _loadCollectionSparklines(),
    );
    _loadCollectionSparklines();
    unawaited(load());
    unawaited(_loadOffer());
  }

  /// Overview and highlights in parallel; each failure leaves its sections
  /// out rather than failing the tab.
  Future<void> load({bool forceRefresh = false}) async {
    await Future.wait([
      _loadOverview(forceRefresh)
          .then((o) => overview.value = o.isEmpty ? null : o)
          .catchError((_) => null),
      _loadHighlights(forceRefresh)
          .then((h) => highlights.value = h)
          .catchError((_) => MarketHighlights.empty),
    ]);
    isLoading.value = false;
    _loadMarketSparklines(forceRefresh: forceRefresh);
  }

  /// The running offer for the Premium card: the yearly plan's first, as
  /// yearly is the checkout's default. On iOS an offer needs its own App
  /// Store product, as on the checkout. Skipped for a user the card doesn't
  /// show for; a failure just leaves the trial button.
  Future<void> _loadOffer() async {
    if (!DashboardPremiumCard.showFor(Get.find<UserSessionController>())) {
      premiumOffer.value = null;
      return;
    }
    try {
      final packages = await _packageRepo.getAll();
      final now = DateTime.now();
      final ordered = [
        ...packages.where((p) => p.isYearly),
        ...packages.where((p) => !p.isYearly),
      ];
      for (final plan in ordered) {
        final offer = Platform.isIOS
            ? plan.appleOfferAt(now)
            : plan.offerAt(now);
        if (offer == null) continue;
        premiumOffer.value = (
          offer: offer,
          percentOff: plan.offerPercentOffAt(now),
        );
        return;
      }
      premiumOffer.value = null;
    } catch (_) {
      // No offer to show: the card keeps its trial button.
    }
  }

  /// The Premium card's countdown reached zero.
  void endOffer() => premiumOffer.value = null;

  /// The [windowDays] movers, or the [fallbackDays] ones when the longer
  /// window has none. The section's subtitle names whichever it got.
  Future<MarketOverview> _loadOverview(bool forceRefresh) async {
    final o = await _marketRepo.overview(
      days: windowDays,
      forceRefresh: forceRefresh,
    );
    if (o.gainers.isNotEmpty || o.losers.isNotEmpty) return o;
    final short = await _marketRepo
        .overview(days: fallbackDays, forceRefresh: forceRefresh)
        .catchError((_) => o);
    return short.gainers.isEmpty && short.losers.isEmpty ? o : short;
  }

  /// Breadth over [windowDays], or over [fallbackDays] when no bottle has a
  /// change that long yet. The community lists are the same either way.
  Future<MarketHighlights> _loadHighlights(bool forceRefresh) async {
    final h = await _marketRepo.highlights(
      days: windowDays,
      forceRefresh: forceRefresh,
    );
    if (h.hasBreadth) return h;
    final short = await _marketRepo
        .highlights(days: fallbackDays, forceRefresh: forceRefresh)
        .catchError((_) => h);
    return short.hasBreadth ? short : h;
  }

  /// The market's risers, [moversShown] at most.
  List<BluebookModel> get gainers =>
      overview.value?.gainers.take(moversShown).toList(growable: false) ??
      const [];

  /// The market's fallers, [moversShown] at most.
  List<BluebookModel> get losers =>
      overview.value?.losers.take(moversShown).toList(growable: false) ??
      const [];

  /// A community list cut to [rowsShown].
  static List<HighlightBottle> shown(List<HighlightBottle> list) =>
      list.take(rowsShown).toList(growable: false);

  /// The collection's bottles that moved most over [windowDays], either
  /// way, biggest first. Ranked by their price lines, so the list fills in
  /// once those arrive; a flat bottle is left out.
  List<({CollectionItemModel item, PriceSparkline spark})>
  get collectionMovers {
    final ranked = <({CollectionItemModel item, PriceSparkline spark})>[];
    final seen = <String>{};
    for (final item in _home.items) {
      final id = item.bluebookBottleId;
      if (id == null || !seen.add(id)) continue;
      final spark = sparklines[id];
      final change = spark?.changePct;
      if (spark == null || change == null || change == 0) continue;
      ranked.add((item: item, spark: spark));
    }
    ranked.sort(
      (a, b) => b.spark.changePct!.abs().compareTo(a.spark.changePct!.abs()),
    );
    return ranked.take(rowsShown).toList(growable: false);
  }

  void _loadMarketSparklines({required bool forceRefresh}) {
    final h = highlights.value;
    final ids = <String>{
      for (final b in [...gainers, ...losers]) b.id,
      for (final list in [h.hot, h.newlyPriced, h.mostCollected, h.topRated])
        for (final i in shown(list))
          if ((double.tryParse(i.bottle.average ?? '') ?? 0) > 0) i.bottle.id,
    };
    _fetchSparklines(ids, forceRefresh: forceRefresh);
  }

  /// One request for the whole collection; the cache is shared with the
  /// Collection tab's rows, so whichever loads first pays for it.
  void _loadCollectionSparklines() {
    final ids = <String>{
      for (final item in _home.items)
        if ((item.marketAverageValue ?? 0) > 0) ?item.bluebookBottleId,
    };
    _fetchSparklines(ids, forceRefresh: false);
  }

  void _fetchSparklines(Set<String> ids, {required bool forceRefresh}) {
    if (ids.isEmpty) return;
    unawaited(
      _bluebookRepo
          .sparklines(ids, days: windowDays, forceRefresh: forceRefresh)
          .then(sparklines.addAll),
    );
  }

  /// Pull-to-refresh: the market parts and the collection card.
  Future<void> refreshAll() async {
    _logTap('home_pull_refresh');
    await Future.wait([
      load(forceRefresh: true),
      _loadOffer(),
      if (Get.isRegistered<HomeController>()) _home.forceReload(),
      if (Get.isRegistered<WishlistController>())
        WishlistController.to.forceReload(),
    ]);
  }

  /// The movers' "See all": the headline index's page, whose risers and
  /// fallers cover the same 90 days by default.
  void openAllPerformers() {
    final index = overview.value?.index;
    _logTap('home_movers_see_all', {'slug': index?.slug ?? 'market'});
    Get.toNamed(
      AppRoutes.marketIndex,
      arguments: {
        'slug': index?.slug ?? 'market',
        'name': index?.name ?? 'Oak Spire Index',
      },
    );
  }

  /// "See all" on Home's wishlist: the Collection tab, on its Wishlist.
  void openWishlist() {
    _logTap('home_wishlist_see_all');
    Get.find<CollectionController>().showWishlist();
    Get.find<BottomNavController>().setIndex(BottomNavController.collectionTab);
  }

  /// The Premium card's button: the subscription screen.
  void openPremium() {
    _logTap('home_premium_card', {'offer': premiumOffer.value != null});
    Get.toNamed(AppRoutes.subscription);
  }

  void openCollection() {
    _logTap('home_collection_open');
    Get.find<BottomNavController>().setIndex(BottomNavController.collectionTab);
  }

  /// Empty collection CTA. Taste switches to Collection after an add and pops
  /// with `true`, so the collection card is refreshed on the way back.
  Future<void> addFirstBottle() async {
    _logTap('home_add_first_bottle');
    final res = await Get.toNamed(AppRoutes.tasteBottles);
    if (res == true && Get.isRegistered<HomeController>()) {
      await _home.forceReload();
    }
  }

  /// The welcome card's button: the add-a-bottle flow.
  Future<void> addFromWelcome() async {
    _logTap('home_welcome_add');
    endWelcomeSpotlight();
    await addFirstBottle();
  }

  void dismissWelcome() {
    _logTap('home_welcome_dismiss');
    endWelcomeSpotlight();
    unawaited(_endWelcome());
  }

  /// Lifts the welcome card, once it is on screen, if it hasn't been yet for
  /// this user.
  void startWelcomeSpotlight() {
    final userId = AppStorage.userId;
    if (!welcomeSpotlightDue || userId == null) return;
    welcomeSpotlight.value = true;
    unawaited(AppStorage.setWelcomeSpotlightSeen(userId));
  }

  /// A tap anywhere but the welcome card: it settles and the page clears.
  void endWelcomeSpotlight() => welcomeSpotlight.value = false;

  Future<void> _endWelcome() async {
    welcomePending.value = false;
    await AppStorage.clearWelcomePending();
  }

  void logMoversToggle(bool rising) => _logTap('home_movers_toggle', {
    'direction': rising ? 'rising' : 'falling',
  });

  void logOpen(String section, String bottleId) => _logTap(
    'home_highlight_open',
    {'section': section, 'bottle_id': bottleId},
  );

  void _logTap(String key, [Map<String, Object>? extra]) {
    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(AppAnalyticsController.to.logTap(key, extra));
    }
  }
}
