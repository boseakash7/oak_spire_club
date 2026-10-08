# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

**Oak Spire Club** (`oakspire_club`) — a Flutter mobile app for bourbon/whiskey collectors.
The app is market-centric. It opens on Home, a one-scroll summary: the market's headline
index and breadth, the user's collection against it, the biggest movers, what other collectors
are adding, the most-collected bottles, the top-rated ones, and last the newly priced bottles.
Market holds the Oak Spire indexes and the sortable bottle list, so people can
check prices and then decide what to do with their collection. Users also track a bottle collection, with its value
charted against the index, and pay for a subscription (Razorpay on Android, Apple IAP on
iOS). The product plan is [docs/market-centric-plan.md](docs/market-centric-plan.md).

Ships to Android (`com.oak.spireclub`) and iOS (`com.oak.spireclub`). The desktop/web
platform folders exist from `flutter create` but are not targets — `analysis_options.yaml`
excludes them, and their `generated_plugin_*` files are regenerated noise (they show as
modified in `git status` after most `pub get` runs).

Flutter SDK is pinned to **3.41.0** via `.fvmrc` / `.vscode/settings.json`. The `.fvm`
directory is not checked in, so a plain `flutter` on PATH is what actually runs unless the
developer has set FVM up locally.

The API this app talks to lives in the sibling repo `../oakspireweb` (PHP). It is documented in
[Backend — `../oakspireweb`](#backend--oakspireweb) at the end of this file.


## Commands

```sh
flutter pub get
flutter analyze                 # lints: package:flutter_lints
flutter test                    # route constants + value/rating/sparkline parsing
flutter run

# Run the emulator on the host GPU. With hw.gpu.mode=auto this machine falls back to
# SwiftShader (software), and the emulator process itself segfaults (exit 139, no app
# error) after a few minutes of Flutter/Impeller rendering:
#   emulator -avd Medium_Phone -gpu host     (or AVD config.ini: hw.gpu.mode=host)

# Against the local docker backend (oakspireweb) on an Android emulator:
# run the php container with WEBSITE_URL=10.0.2.2 so the Host header matches,
# then pass the API base (debug builds allow cleartext HTTP for this).
flutter run --dart-define=API_BASE_URL=http://10.0.2.2/v2/api/

# Release builds — always obfuscated + split debug info
./build_apk.bat                 # or scripts/build_release_apk.ps1 [-SplitPerAbi]
./build_bundle.bat
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

dart run flutter_launcher_icons                                        # app icons
dart run flutter_launcher_icons -f flutter_launcher_icons_splash.yaml  # splash mipmaps
```

Release APK/AAB signing reads `android/key.properties` (not in the repo). The
`signingConfigs` block dereferences those keys unconditionally, so a release build fails
without that file. Keep `build/app/outputs/symbols` private — it is needed to deobfuscate
Crashlytics traces.

## Architecture

GetX for everything: state, DI, routing, and the HTTP client. Layering is
**view → controller → repository → datasource → `ApiClient`**.

```
lib/
  main.dart                  Hive + AppStorage + Firebase init, then runApp
  app/
    app.dart                 GetMaterialApp (dark-only theme, analytics nav observer)
    app_binding.dart         global DI graph, registered once at startup
    core/                    cross-cutting: network, cache, storage, theme, platform,
                             firebase, analytics, animations, services (update check,
                             Apple IAP, store links), shared widgets, utils
    data/                    models, datasources (HTTP), repositories (cache + shaping),
                             plus chart_index_comparison / collection_value_calculator
    modules/<feature>/       <feature>_binding.dart / _controller.dart / _view.dart,
                             plus widgets/ for the view's sections
    modules/session/         UserSessionController (Rx user), AppConfigController
    modules/profile/         settings_menu_popup.dart (settings popup + logout)
    modules/shared/          controller mixins shared by features (PagedBottleSearch)
    routes/                  app_routes.dart, app_pages.dart, *_navigation.dart helpers
```

`AppBinding` `Get.put`s three permanent controllers (`AppAnalyticsController`,
`UserSessionController`, `AppConfigController`, the last after `ConfigRepository` because it
depends on it), lazy-registers every datasource/repository pair, then calls
`FcmTokenSyncService.start()`. `AppCache` is put separately in `main.dart`, before `runApp`.

### Adding a screen

1. Add the path constant to `AppRoutes` ([app_routes.dart](lib/app/routes/app_routes.dart)).
2. Register a `GetPage` in `AppPages.pages` ([app_pages.dart](lib/app/routes/app_pages.dart)).
3. Create `modules/<feature>/` with a binding (`Get.lazyPut` the controller), a
   `GetxController`, and a `GetView<Controller>` view. Views that need no controller may
   skip the binding (see `settingsHelp`, `settingsAbout`).
4. Add a case to `AnalyticsScreens.screenKeyForRoute`. Without one, the screen key falls back
   to the slugged path (`/settings/foo` → `settings_foo`).

### Adding an API call

1. Add the endpoint as a `static const String` in the relevant `*_remote_datasource.dart`,
   plus a method that calls `_client.postJson(...)` (form-encoded POST) or `_client.get(...)`
   followed by `_client.parseEnvelope(response)`.
2. Wrap it in a repository method, which owns caching and any client-side shaping.
3. Register the datasource + repository pair in `AppBinding` with `Get.lazyPut(..., fenix: true)`.
   (`NotificationPrefsRemoteDataSource` / `NotificationPrefsRepository` exist but are *not*
   registered. Register them before anything calls `Get.find` for them.)

## Screen map

Every route constant is in [app_routes.dart](lib/app/routes/app_routes.dart) and registered in
[app_pages.dart](lib/app/routes/app_pages.dart). `shell` is the only tabbed screen; everything
else is a full push.

| Route | Module | Reached from |
| --- | --- | --- |
| `/splash` | `modules/splash` | app entry (`initialRoute`) |
| `/get-started` | `modules/get_started` | `AuthNavigation.openWelcome` when no session |
| `/sign-in` | `modules/auth/sign_in` | get-started, sign-up footer |
| `/sign-up` | `modules/auth/sign_up` | get-started, sign-in footer |
| `/verify-otp` | `modules/auth/verify_otp` | `AuthNavigation.afterAuth` when `!user.emailVerified` |
| `/forgot-password` | `modules/auth/forgot_password` | sign-in |
| `/reset-password` | `modules/auth/reset_password` | forgot-password (`offNamed`, args `{email}`) |
| `/shell` | `modules/navigation` | `AuthNavigation.completeSession`, subscription skip/success |
| `/taste-bottles` | `modules/taste` | Collection chart footer, collection empty state, collection FAB |
| `/add-to-collection` | `modules/add_collection` | taste list + benchmark detail via `AddToCollectionLauncher`; taste "add your own" (no args) |
| `/benchmark-detail` | `modules/market` | market row (`market_bottle_row`), collection quick-view sheet, every Home bottle row |
| `/market-index` | `modules/market_index` | Market index cards (`MarketIndexCard`), args `{slug, name}` |
| `/collection/bottles` | `modules/collection` | Collection tab "View all bottles" (no binding: shares the shell's `CollectionController`) |
| `/subscription` | `modules/subscription` | settings menu, `SubscriptionLimitNavigation`, post-auth offer |
| `/subscription-skip` | `modules/subscription` | subscription screen "skip" |
| `/subscription/payment-success` | `modules/subscription` | after Razorpay verify / Apple IAP subscribe |
| `/settings/account` | `modules/settings/account` | settings popup |
| `/settings/notifications` | `modules/settings/notifications` | settings popup |
| `/settings/privacy` | `modules/settings/privacy` | settings popup |
| `/settings/delete-account` | `modules/settings/delete_account` | settings popup |
| `/settings/help` | `modules/settings/help` | settings popup (no binding) |
| `/settings/about` | `modules/settings/about` | settings popup (no binding) |
| `/settings/legal-web` | `modules/settings/legal` | about screen, args `{title, url}` (no binding) |

**Shell tabs** are built in [bottom_nav_shell.dart](lib/app/modules/navigation/bottom_nav_shell.dart)
as a `LazyTabStack` ([lazy_tab_stack.dart](lib/app/modules/navigation/widgets/lazy_tab_stack.dart)):
`DashboardView` (0, `BottomNavController.homeTab`, the landing tab, labelled "Home"),
`MarketView` (1, `marketTab`) and `CollectionView` (2, `collectionTab`). The fourth nav item
(slot 3) is Settings, which calls `showSettingsPopup(context)` and sets `settingsMenuOpen`; it is
not a tab or route. The shell's back handler closes the popup, then returns to Home, then asks
to exit.

**Home tab** ([dashboard_view.dart](lib/app/modules/dashboard/dashboard_view.dart),
`DashboardController`), top to bottom. Every section is a vertical list (no side scrolling),
movement covers `DashboardController.windowDays` (90), and each section is left out when it has
nothing to show.
- **The market** (`DashboardMarketPulse`): one card, the headline `MarketIndexCard` with
  `title: 'The market'` and a `footer` holding the breadth (rising / falling bottles,
  `market/highlights?days=90`) and "Prices updated".
- **Your collection** (`DashboardCollectionCard`): titled inside the card. Today's value, gain vs paid, the header's move
  line, the value's line over the chart range (`HomeController.chartMarketPrices`, drawn with
  `PriceSparklineView`), the Bottles / Sealed / Opened / Rare counts, and the range's move beside
  the index's (the 6M range has no index match). With no collection it shows an "Add your first
  bottle" CTA to `/taste-bottles`.
- **Your bottles on the move** (`DashboardCollectionMovers`): the 3 collection bottles whose 90-day
  sparkline moved most, either way. It fills in once the sparklines arrive.
- **Biggest movers** (`DashboardMovers`): a Rising / Falling toggle over 5 risers or 5 fallers
  (`DashboardController.moversShown`) from `market/overview?days=90`. "See all" opens the headline
  index's page, whose risers / fallers default to the same 90 days. (It used to be on Market.)
- **Hot with collectors**, **Most collected**, **Top rated in collections**, then last **New
  to the market**: `DashboardBottleList`s (3 rows each) over `market/highlights`.

The two cards at the top (market, collection) carry their titles inside, on the card's top line in
`MarketIndexCard`'s style (muted `bodyS` + chevron), not a `DashboardSectionHeader` above them.

Every bottle row is a `DashboardBottleRow` with a 90-day sparkline, drawn on its own card like a
Collection row (not one card per section). Lay a list of them out with
`DashboardBottleRow.spaced(rows)`. `DashboardController` fetches
them in one `sparklines` call for the market rows and one for the collection (shared cache with
the Collection tab). Community rows show the sparkline's change. Market movers show
`market.changeOver(windowDays)`.

**The 30-day fallback.** `change_90d` is null until a bottle has a price from 90 days ago, so a
young price history has no 90-day movers or breadth. `_loadOverview` / `_loadHighlights` then
fall back to 30 days, and the subtitles show the window they got.

**Opened / sealed counts** are bottles, not rows. A row whose fill is under 100% counts all its
quantity as opened. `_groupCollectionItems` stores the merged sum in
`CollectionItemModel.openedQuantity`, because the merged fill is an average.
`CollectionItemDisplay.openedBottleCount` / `sealedBottleCount` read it, and `HomeController`
totals them as `totalBottleCount` / `openedBottleCount` / `sealedBottleCount`.

A bottle can appear in several sections, and `BottleImage` makes a Hero from `bottleId`, so the
view gives each id's Hero to its first appearance only. The other copies pass `bottleId: null`.
The module is `dashboard`, not `home`, because `HomeController` is the collection-insights
controller.

**Collection insights.** The old Home sections (value vs index chart, quick stats)
render on the Collection tab through `CollectionInsights`, only when the collection is
non-empty. `HomeController` and `modules/home/widgets/` own that data and those
widgets. It is lazy-put by the shell binding, refreshed when switching to Home or Collection,
and feeds Home's collection card (including its move line) and (through `items`) Home's collection
movers.

**Market tab** ([market_view.dart](lib/app/modules/market/market_view.dart)), top to bottom:
`MarketIndexStrip` (one card per Oak Spire index, headline first), then search, category
chips, the "Prices updated" caption with `MarketSortButton`, and the paged list. The biggest
movers are on Home. The index strip hides while a keyword search is active, and so does the sort
pill (search is relevance-ranked). The strip comes from `MarketRepository` and is optional: an older server or one
before the nightly job's first run just shows the list. `MarketBottleRow` shows the 30-day
change (`bluebook.market.change30d`) when there is one, else the last price move.

**Benchmark detail** also has a **Deal check** (`BenchmarkDealCheck`): the user types an asking
price and `DealCheck.evaluate` ([deal_check.dart](lib/app/data/deal_check.dart)) places it on the
low–high bar. The verdict is below low / good (≥5% under) / fair (±5%) / above average / above
high. It is captioned as thin when `pricing` is thin or manual. The summary's movement chip
shows the change over the selected chart range, falling back to the last price move. Tags
include `× retail` (`BottleDetails.retailMultipleLabel`, average ÷ MSRP), as do market rows.

**Shell header** ([app_header.dart](lib/app/core/widgets/app_header.dart)) is the only `AppHeader`
use, and it is the same on every tab (no tab title).
- Left: a gold-ringed user icon, then "Hello," over the user's first name
  (`GreetingFormatter.firstNameFrom`, falling back to "Collector").
- Right: only the plan badge, `PREMIUM` (gold) when `user.hasActiveSubscription || user.isFreeUser`,
  else `FREE`.
- Both read `UserSessionController.user` reactively, so call `setUser` after a refresh and they update.
- `HomeController.headerMoveText` (`▲ $124 today` / `… this week` / `Steady this week`, computed
  in `_applyHeaderMove`) is no longer in the header. Home's collection card shows it.

**Collection tab** ([collection_view.dart](lib/app/modules/collection/collection_view.dart)), top to
bottom, all built by `CollectionInsights`
([collection_insights.dart](lib/app/modules/collection/widgets/collection_insights.dart)):
- **Quick stats** (`HomeQuickStats`): a two-column grid of 8 one-line tiles (gold icon, label,
  number; the number scales down rather than push the label out): collection, drunk, rating,
  rare, then duplicates, doubled (+100% or more), gaining and losing value. The last four come from `CollectionValueCalculator.holdingCounts`, which
  works per bottle against that bottle's price paid. Each tile is tappable and opens All bottles
  filtered to what it counts (`CollectionController.openBottles(CollectionFilter.x)`; Collection
  opens every bottle, Rating opens the rated ones). `CollectionFilter.matches` must agree with
  the tile's count.
- **Collection value** (`CollectionValueCard`): a full-width card, titled inside, with today's
  value, the invested / gain caption and the gain-vs-paid badge. (There is no heading above the
  page any more.)
- **Portfolio mix** (`CollectionPortfolioMix`): one card, titled inside, with a Type / Brand toggle.
  A stacked bar and a legend show each group's share of today's value.
  `PortfolioBreakdown.of` ([portfolio_breakdown.dart](lib/app/data/portfolio_breakdown.dart)) does the
  math: a row counts at market value, else what was paid. Type is `details.spiritType`; brand is
  `details.brand ?? details.distillery`; a blank is "Unspecified". Groups merge case-insensitively,
  the top 5 show, and the rest fold into "Other". Colors are `AppColors.portfolioMix`.
- **You vs the market** (`CollectionMarketChartCard`): a scoreboard card. Its header holds the
  1M / 3M / 6M / 1Y range (`HomeController.setChartRange`); below, the collection's and the Oak Spire
  Index's moves over the range in big numbers, an "Ahead of / Behind the market by N pts" chip, and
  `HomeValueChart` (smooth lines with `preventCurveOverShooting`, a dashed start baseline at 100, no dots, gold wash under the
  collection only; no axes, grid or background). The index line is the headline **Oak Spire Index**
  (`market/index-detail`, `HomeChartRange.indexDays`: 6M asks for 180), not the server's
  `index_data` (BSMI); `ChartIndexComparison.alignIndexToMarketDates` takes its value as of each
  collection date. The touch tooltip shows both values and moves.
- **Top priced bottles** (`CollectionTopPriced`): the 5 highest by one bottle's price
  (`PortfolioBreakdown.topPriced`), as `CollectionBottleRow`s, then a "View all bottles (N)" button.
- **All bottles** ([collection_bottles_view.dart](lib/app/modules/collection/collection_bottles_view.dart),
  `/collection/bottles`): the sort menu, the active quick-stat filter as a gold pill (tap clears
  it), and the list. The title is the filter's label and count. There are no filter chips: the
  quick stats are the filters. "View all bottles" opens it unfiltered.

An empty collection shows the "Browse bottles" empty state in place of all three.

The list is a `SliverList` of `CollectionBottleRow`
([collection_bottle_row.dart](lib/app/modules/collection/widgets/collection_bottle_row.dart)).
The old two-column grid and `CollectionBottleCard` are gone.
- Left side of a row: art, name, maker · region, and type / age / ABV / Rare / rating chips
  (from `CollectionItemDisplay.details`, i.e. `BottleDetails.fromBottleJson(bluebook)`).
  Below them: fill bar + %, `×qty`, and "Paid $X".
- Right side: today's value (`marketTotalValue`), gain $ and % against paid, the 90-day
  sparkline, and `Last ±N%` (`price_movement`). A bottle with no market price shows its paid
  value marked "Valued at cost".
- Each row's `Obx` always reads `controller.sparklines[bottleId ?? '']`, because an `Obx` that
  reads no observable throws.
- Tapping a row still opens `showCollectionQuickView`. That file now owns
  `kCollectionCardRadius`, `kCollectionBottleImage` and `CollectionCardDetails`. Its card is
  240 tall (Figma 226) to fit today's value + gain % and a "Paid" line.
- The sort menu is Name / Price / Gain / Fill Rate / Added Time. Price sorts by current unit
  value (falling back to paid). Gain sorts by `gainPercent`.

**Route arguments are untyped maps.** Helper accessors exist for the subscription routes
(`SubscriptionLimitNavigation`, `SubscriptionPaymentSuccessNavigation`, and
`AuthNavigation.postAuthSubscriptionArg` for `/subscription` and `/subscription-skip`) and for
`/benchmark-detail` (`BenchmarkDetailRouteArgs.from`, in `benchmark_detail_controller.dart`). The
rest read `Get.arguments` directly. `/verify-otp` and `/reset-password` take `{email}`.
`/benchmark-detail` takes a flat bottle map (`id`, `name`, `image`, `average`, `low`, `high`,
`proof`, `description`, `rating`, `price_movement`), built by
`CollectionItemDisplay.benchmarkDetailArguments` or inline in `market_bottle_row`.
`/add-to-collection` takes
`{prefill, editMode?, originalBottleId?, navigateToCollectionOnSuccess, popBenchmarkDetailOnSuccess}`.
Home's empty state passes `{autoCloseOnAdded: true}` to `/taste-bottles`, but nothing reads it,
because taste always pops after an add.

**Add-to-collection pops with `true` on success, and taste-bottles passes that on.** Taste
switches to the Collection tab, reloads collection and home, then `Get.back(result: true)`. The
callers that push taste (home chart footer, home and collection empty states) `await
Get.toNamed(...)` and call `forceReload()` when the result is `true`. Keep that contract when
adding a new entry point. `AddToCollectionLauncher.open` handles its own follow-up instead:
it switches tabs, refreshes home and collection, and optionally pops benchmark detail. It also
merges existing collection rows for the same bottle into an edit-mode prefill.

The Market category chips filter the bluebook list in place; there is no category detail screen
(the old unreachable `category_detail` module was removed).

Copy on market screens describes prices ("11% under the market average"). It never advises
("Buy"), and the index page says the figures are not investment advice.

## API surface

Base URL `https://www.oakspireclub.com/v2/api/`. Every call goes through `ApiClient`; `user_id`
comes from `AppStorage` at the repository layer.

| Endpoint | Verb | Datasource method | Called by |
| --- | --- | --- | --- |
| `auth/register` | POST | `register` | sign-up |
| `auth/login` | POST | `login` | sign-in |
| `auth/send-otp` | POST | `sendOtp` | verify-otp (on open + resend) |
| `auth/verify-otp` | POST | `verifyOtp` | verify-otp submit |
| `auth/forget-password` | POST | `forgetPassword` | forgot-password, reset-password resend |
| `auth/reset-password` | POST | `resetPassword` | reset-password |
| `auth/update` | POST | `updateProfile` | settings/account save, settings/privacy password change |
| `auth/delete` | POST | `deleteAccount` | settings/delete-account |
| `user/get-by-id` | GET | `getById` | splash session refresh, account save, subscription refresh |
| `config/all` | GET | `getAll` | `AppConfigController` at splash |
| `collection/all` | GET | `all` | home, collection, `AddToCollectionLauncher` duplicate check, benchmark detail |
| `collection/chart-data` | GET | `chartData` | home chart, collection chart (`look_back` days) |
| `collection/add` | POST multipart | `add` | add-to-collection (image upload), collection quantity/fill edits |
| `collection/delete-by-user-bottle` | POST | `deleteByUserBottle` | collection remove / edit-replace |
| `bluebook/get-all-bluebooks` | GET | `getAll` (no keyword) | market / taste browsing + pagination; `sort` (`MarketSort.apiValue`) from Market, rows carry `market` stats |
| `bluebook/search` | GET | `getAll` (with keyword) | market / taste search: hybrid lexical + semantic, same envelope, `category_id` honoured, SQL fallback server-side |
| `bluebook/get-by-id` | GET | `getById` | benchmark detail: the catalog facts (`details`: distillery, type, age, ABV, cask…) the list rows don't carry, whichever screen opened it |
| `bluebook/create` | POST | `create` | add-to-collection when the bottle is not in the bluebook |
| `bluebook/get-last-update` | GET | `getLastUpdatedReadable` | market "last updated" label |
| `bluebook/sparklines` | GET | `sparklines` (`ids` ≤ 60, `days`) | collection rows (all bottles, one call) and Benchmark rows (one call per page): 24 as-of samples per bottle; repository never throws, a missing endpoint only costs the sparklines |
| `bluebook-price-history/chart-data-dashboard` | GET | `getChartDashboard` | benchmark detail chart (`bottleId`, `fromDate`, `endDate`) |
| `market/overview` | GET | `MarketRemoteDataSource.overview` (`days`) | Market (30, the index strip's fallback) and Home (90, falling back to 30): headline index + top 10 gainers / losers |
| `market/indexes` | GET | `indexes` | Market index strip |
| `market/index-detail` | GET | `indexDetail` (`slug`, `days`) | `/market-index`: series, risers, fallers, methodology |
| `market/highlights` | GET | `highlights` (`days`, breadth window only) | Home: breadth (90, falling back to 30), plus hot / new / most-collected / top-rated bottle lists, each row with a `community` object |
| `categories/list` | POST + query | `list` | market category chips, taste category chips |
| `package/get-all` | GET | `getAll` | subscription plan list |
| `package/payment-create` | POST | `createPayment` | subscription checkout (Razorpay) |
| `package/payment-verify` | POST | `verifyPayment` | Razorpay success/failure handler |
| `package/subscribe` | POST | `subscribeApple` | Apple IAP purchase completion |
| `package/transaction-history` | POST | `transactionHistory` | subscription manage mode |
| `package/cancel-subscription` | POST | `cancelSubscription` | subscription cancel |
| `usertoken/save-user-fcm` | POST | `saveUserFcm` | `FcmTokenSyncService` on login / token refresh |
| `usertoken/delete-user-fcm` | POST | `deleteUserFcm` | logout |
| `notification-preferences/update` | POST | `updatePreference` | nothing — settings/notifications toggles only drive FCM topics and `AppStorage` |

`CollectionType` (`normal` \| `wishlist`) is sent as the `type` field on every `collection/*`
call; the app only uses `normal` today.

**Cached reads** (24h TTL, cleared on app-version change) are `collection:all:$userId`,
`collection:chart:$userId:$lookBackDays`, `categories:list:$page:$limit`,
and `bluebook:last-updated`; `market:overview:$days`, `market:indexes` and
`market:index:$slug:$days` and `market:highlights:$days` for 1 hour (raw `data` maps, parsed on read); plus `bluebook:spark:$id:$days` (6h, one entry per bottle, read
and written through `AppCache.peek` / `put` so a batch only requests the misses). `bluebook/get-all-bluebooks`, `bluebook/search`,
`config/all`, `user/get-by-id`, and everything under `package/` and `auth/` are uncached.

## Conventions that matter

**API envelope.** Base URL `https://www.oakspireclub.com/v2/api/`. Every response is
`{ code, data }`; `ApiResponseHandler.ensureOk` throws `ApiException(message)` unless
`code == 'OK'`. Controllers catch `ApiException` and surface `e.message` via `AppSnackbar`.
Payloads are stringly-typed — models parse with `json['x']?.toString()`, and the literal
string `'null'` is a real value to guard against (`UserModel` does this throughout).

**No auth token.** There is no session token or auth header. Identity is the `user_id`
form field / query param, read from `AppStorage.userId` at the repository layer. A
repository that finds no user id returns empty rather than throwing.

**`LIMIT_EXCEEDED` is handled globally.** When an error payload carries
`data.flag == 'LIMIT_EXCEEDED'`, `ApiResponseHandler` itself navigates to the subscription
screen via `SubscriptionLimitNavigation.open(message)` and throws `LimitExceededException`
(a subtype of `ApiException`). Callers that catch `ApiException` will also catch this — if
a screen should not show an error toast for it, catch `LimitExceededException` first, as
`SubscriptionController.loadPackages` does.

**Caching.** `AppCache` ([app_cache.dart](lib/app/core/cache/app_cache.dart)) is a Hive box
of `{v: appVersion, t: epochMs, d: jsonString}`. Entries expire on TTL *and* on app version
change. Repositories call `cache.getOrFetch(cacheKey:, ttl:, fetch:, encode:, decode:)` with
user-scoped keys like `collection:all:$userId`. **Any mutation must invalidate the affected
prefixes** — see `CollectionRepository.addToCollection`, which clears both
`collection:all:$userId` and `collection:chart:$userId:`. For a batch of many keys in one request
(sparklines), use `cache.peek(cacheKey:, ttl:, decode:)` to find the misses and `cache.put(key, json)`
to store each result; `getOrFetch` is single-key.

**Grouping `collection/all`.** `CollectionRepository._groupCollectionItems` merges rows of the same
bluebook bottle into one: quantities add up, `pricePaid` is the **quantity-weighted** unit price
(Σ unit × qty / Σ qty), and `priceMovement` is kept from the first row. Every value and gain figure
depends on this, so don't go back to a plain average of the rows.

**Two persistence stores, deliberately.** `AppStorage` writes the login session to *both*
Hive (`oakspire_session_v1`, durable on iOS) and GetStorage (legacy), with a one-way
migration on init; everything else lives in GetStorage only. Reads prefer Hive. Keep new
session writes going through `saveSession` / `clearSession` rather than touching a box.

**Remote config.** `config/all` supplies `upload_url`, the pour-image placeholder, Razorpay
keys, and the current-version payload. `AppConfigController` (permanent, refreshed at
splash) mirrors them into `AppStorage`. Config failure is swallowed — the app runs on
whatever was last persisted, so never assume these are non-null.

**Navigation flow helpers** live in `routes/` rather than in controllers:
- `AuthNavigation.afterAuth` — unverified email → OTP screen; otherwise `completeSession`,
  which shows the post-auth subscription offer when `user.needsSubscriptionOffer` and the
  user has not dismissed it, else the shell.
- `SplashController` holds a ~3.6s minimum splash, resolves the stored session (clearing any
  **unverified** session so it cannot survive a restart), refreshes config, and runs the
  forced/optional update check before routing.
- `SubscriptionLimitNavigation`, `SubscriptionPaymentSuccessNavigation` — argument keys for
  those routes are constants on these classes; read them via the provided
  `*FromArguments()` helpers, not by indexing `Get.arguments` directly.

**Subscription state** is derived from `UserModel` getters, not stored separately:
`isFreeUser` (`is_free == 1`, backend-granted premium), `hasActiveSubscription`,
`hasUsedTrial`, `needsSubscriptionOffer`, `resolvedPaymentGateway` (`razorpay` | `apple_in_app`).
`SubscriptionController` picks one of three `SubscriptionScreenMode`s (`checkout`, `freeUser`,
`activeSubscription`) from these. The live user is `UserSessionController.user` (an `Rxn<UserModel>` loaded
from `AppStorage`). After a refresh, update it with `setUser` so views rebuild.

**Bottom nav indices** are `BottomNavController.homeTab` (0), `marketTab` (1) and `collectionTab` (2); call
sites use those constants, not literals. Keep the shell's `_pages`, `_settingsSlot`
and `AnalyticsScreens.shellTabScreenName` in sync when tabs change. Settings is a popup, not a tab.

**Analytics.** Custom events only: `AppAnalyticsController.to.logScreenView(key)` emits
`{key}_view`, `logTap(key, [extra])` emits `{key}_click`, both through `sanitizeKey`. Always guard
with `Get.isRegistered<AppAnalyticsController>()` and `unawaited(...)`, matching existing
call sites. Route screen views are automatic: `AppAnalyticsNavObserver` (in `app.dart`) maps each
pushed route through `AnalyticsScreens.screenKeyForRoute`. Give each new route a stable key
there; otherwise it falls back to the slugged path.
Shell tab switches log through `BottomNavController.setIndex`. Crashlytics and Performance are
set up in `bootstrapFirebase`.

**FCM topics** are all prefixed `oakspire_` and are documented in
[fcm_topics_summary.txt](fcm_topics_summary.txt) — registration state, subscription tier,
and per-preference alert topics. `FirebaseNotificationTopics` owns subscribe/unsubscribe;
the last-applied registration and tier topics are cached in `AppStorage` so switches are
idempotent.

**Theming is dark-only and hand-tuned to Figma.** Colors come from `AppColors`, text from
`AppTextStyles` (Playfair Display for headings, Roboto/Inter for body, via `google_fonts`),
spacing / radii / glows from `AppSpacing` / `AppRadii` / `AppShadows`
([app_spacing.dart](lib/app/core/theme/app_spacing.dart)). `AppTheme` carries component themes
(inputs, switches, sliders, sheets, date picker). Avoid raw `Color(0x...)` or `TextStyle`
literals in views — add a named token instead. Older screens still use one-off Figma paddings.
New and refactored code takes its values from the `AppSpacing` scale (shell gutter is
`AppSpacing.gutter`, 20).

**Buttons.** Sizes come from `AppButtonSize` ([app_spacing.dart](lib/app/core/theme/app_spacing.dart)):
`regular` (44) for full-width CTAs, dialogs and sheets, `compact` (40) for inline actions such as the
empty state's "Browse bottles". Don't hardcode a button `height`. `CommonPrimaryButton` is the
standard primary action.

**Bottle facts.** Bottle payloads carry a `details` object next to `pricing` (built by
`BlueBookHelper::details` in oakspireweb; numbers are typed, blanks are null). `BluebookModel.details`
is a `BottleDetails`: `chips` for list rows (age, ABV), `facts` for the detail page. A server without
`details` still sends the raw columns, and `BottleDetails.fromBottleJson` falls back to them.

**Banding.** The dark palette's gradients are only a few color levels apart, so they band on
8-bit screens. Flutter already dithers gradients drawn in code. Full-screen photo backgrounds go
through `AppBackdropImage`, which uses high-quality filtering, and ship a 2× variant under
`assets/images/2.0x/` (`signin_bg.png` does). `signUpBackground` is an alias of
`signInBackground`. The dark photo backgrounds are de-banded offline with
[scripts/deband_backgrounds.py](scripts/deband_backgrounds.py), which smooths them in float and
re-dithers them to 8-bit. Re-run it on the undithered masters (the script says where they are)
whenever the art changes. Keep `signin_bg` as PNG, because JPEG or WebP brings the bands back.
Don't add an app-wide grain or noise overlay: a full-screen `ImageShader` pass on every frame
crashed the SwiftShader (software-GPU) emulator.

**Motion.** Durations and curves live in `AppMotion`; read them through
`AppMotion.of(context, d)` (or check `AppMotion.reduced(context)`) so the OS "reduce / remove
animations" setting turns motion off app-wide. The shared primitives, reuse them instead of
hand-rolling animation:
- `AppPageTransition` — every route's transition, attached per `GetPage` in `AppPages.pages`
  (GetX keeps the iOS swipe-back only for a route's own `customTransition`): Cupertino on iOS,
  Material shared-axis on Android.
- `AppStateSwitcher` — fade-through between loading / content / empty states.
- `StaggeredEntrance` / `FadeSlideEntrance` / `StaggeredColumn` — entrances; inside a
  `StaggerScope`, rows with an `id` animate once and stagger per burst, not per absolute index.
  Long scrolling lists (Benchmark, Add a bottle) key the scope by query and pass
  `entranceWindow`, so only the first screenful animates. Never use
  `StaggeredEntrance(index: i)` in a lazily built list: rows scrolled into view would wait for
  their slot and then pop in.
- `AppFilterChipBar` ([app_filter_chip.dart](lib/app/core/widgets/app_filter_chip.dart)) — every
  filter-chip row (Collection, Benchmark, Add a bottle). Picking a chip moves the gold
  highlight toward the middle of the bar. Once it is there it stays put, and the row scrolls
  the chip into it. Pass `clipToBounds` when the bar sits beside fixed content.
- `AppPressable` — press scale + haptic for anything tappable (not a bare `GestureDetector`).
- `ShimmerScope` around a skeleton — one synced sweep for all its `ShimmerBox`es. Placeholders
  that sit on a `cardSurfaceGradient` card need `AppColors.shimmerOnCardBase/Highlight` (the
  default base is nearly the card color). `ShimmerCardLayers` (with `ShimmerSlot` /
  `ShimmerLine`, in [shimmer_box.dart](lib/app/core/widgets/shimmer_box.dart)) does this: real card
  surfaces underneath, the placeholders in one scope on top. `TasteLoadingView` and
  `MarketLoadingView` (plus `MarketBottleSkeletonList` for search and paging) use it, laid out
  like the real rows. Don't use a bare full-size `ShimmerBox` as a row placeholder.
- `AnimatedCountText`, `AnimatedFillBar`, `AppSegmentedRange`, `AppSearchField`,
  `BottleImage` (art + fallback URLs + Hero via `AppHeroTags`), `PricingBadge`.
- `PriceSparklineView` ([price_sparkline.dart](lib/app/core/widgets/price_sparkline.dart)): the
  list-row price line (Collection 64×22, Benchmark 60×20).
  - It is a `CustomPainter` in a `RepaintBoundary`. Don't use fl_chart in rows.
  - It draws a step line, green / red / muted by the window's change.
  - While its data is null it shows a dashed baseline, so the row doesn't shift, and it fades
    in when the data arrives.
- Shell tabs are a `LazyTabStack` (built on first visit, fade-through on switch; hidden tabs get
  `TickerMode(false)` and `HeroMode(false)`).

**Android draws edge to edge** (target SDK 36), so content runs under the system navigation bar
unless a screen reserves it. A `SafeArea` does. A scroll view with an explicit `padding` drops the
automatic inset, so add `MediaQuery.paddingOf(context).bottom` to its bottom padding, as
benchmark detail and the index page do. Sheets add it to their own bottom padding.

**Platform feel** goes through `AppPlatform` (`isCupertino`, `scrollPhysics`, `backIcon`) and
`showAppDatePicker` (wheel on iOS, calendar on Android); use `RefreshIndicator.adaptive`.
Payments keep their own `Platform.isIOS` checks.

**Prices say what they rest on.** `BluebookModel.pricing` (`BottlePricing`) is parsed from the
API's `pricing` object; `PricingBadge` renders it, and a `manual` basis is labelled "Oak Spire
price", never market value (oakspireweb `ai-features-plan.md` §2.5). The bottle chart is a step
line on real dates — history is change-only, so a price holds until the next point — and draws
no BSMI line unless the API sends one (it used to fake one from the current price).

**User messaging** goes through `AppSnackbar.error/success/info` (a custom overlay toast
with the app icon), not `Get.snackbar`, `ScaffoldMessenger` or `Fluttertoast` directly.
Confirmations use `showAppConfirmDialog`. Other dialogs and sheets use `showAppAnimatedDialog` /
`showAppAnimatedBottomSheet` ([show_app_dialog.dart](lib/app/core/widgets/show_app_dialog.dart)).

**Images.** `BottleImage` lets `CachedNetworkImage` draw the placeholder and the fade, because it
skips both when the image is already in memory; a hand-rolled fade flashed the placeholder on every
new copy of the art. Its Hero flies the source's art on push (rows and the detail ask for
different `memCacheWidth`s, so the detail's isn't decoded yet).

A bottle `image` is either a full URL or a bare upload file name.
`AppImageUrl.resolve` turns it into a URL, using `upload_url` first and then the API host.
`BottleImage` calls it, so don't concatenate `upload_url` by hand.

**Chart math** is shared, not per-screen: `ChartIndexComparison` rebases each series so the
first point in the window is 100 (so collection value and BSMI compare on one axis), and
`CollectionValueCalculator` is the single source of truth for invested value and the
"Moved +N%" figure. `CollectionValueCalculator.summarize` gives Home and Collection the same
headline: today's value (bluebook average × qty, or price paid for a bottle with no market
price), invested, and gain / gain % over only the rows that have both prices. Collection's
badge is that gain against paid, not the chart's 90-day move. `CollectionItemDisplay` has the
per-row versions: `marketTotalValue`, `paidTotalValue`, `gainValue`, `gainPercent`, plus `pricing`
and `ratingRaw`.

**Sparklines** come from `BluebookRepository.sparklines(ids, {days = 90, forceRefresh})`
(model `PriceSparkline`: `prices`, `changePct`).
- It is cached per bottle and requests only the misses, in chunks of
  `BluebookRemoteDataSource.sparklinesMaxIds` (60).
- A bottle the server leaves out is cached as empty, so it isn't requested again.
- **It never throws**: on an old server the rows just keep the placeholder.
- `CollectionController._loadSparklines` asks for every priced bottle in one go after each load.
- The Benchmark tab fetches per page: `PagedBottleSearch` calls the hook
  `onBottlesLoaded(page, reset:)` after each page, and `MarketController` overrides it, for
  priced bottles only.
- Taste doesn't override the hook, so "Add a bottle" makes no sparkline calls. Pull-to-refresh
  on Benchmark bypasses the cache for the first page it reloads.
- The points are evenly spaced samples, so the painter spaces them evenly. Keep the server
  sampling dates evenly too, or the timing of moves will look wrong.

**Ratings** are stored out of 100 (`bluebook.rating`, 0 = not rated; the collection average
`collection_rating_percentage` is on the same scale). Show them out of 10 through
`RatingFormatter` (`label` → `9.2`, `labelOutOfTen` → `9.2/10`), never the raw number.

## Testing

There is effectively no test suite: `test/widget_test.dart` asserts route constants and
`test/collection_value_test.dart` covers `CollectionValueCalculator.summarize`, `RatingFormatter`
and `PriceSparkline` parsing. Do not assume tests cover a change; verify behavior by running the app.

---

# Backend — `../oakspireweb`

Everything below documents the sibling repository `oakspireweb`, which serves this app's API.
It is a separate git repo, checked out next to this one (both are folders in
`oakspireweb.code-workspace`). Read this section before changing anything that touches the
API: response shapes, `user_id` handling, subscription state, and chart math all originate there.

## What it is

One PHP 7.4 codebase on a hand-rolled MVC framework that serves **three** things off the same
document root (`http/public`):

1. **The mobile API** — `/api/...` (v1) and `/v2/api/...`, consumed by this Flutter app.
2. **The admin panel** — server-rendered PHP views (Corona dark Bootstrap template) at
   `/admin`, `/dashboard`, `/bottles/list`, `/users/list`, … plus `/ajax/*` DataTables endpoints.
3. **The marketing site** — `oak-website/index.html`, served at `/` by `Website::index`, with
   `.htaccess` rewrites mapping `assets/`, `blog/`, `styles.css`, `terms.html` and friends back
   into that folder.

There is no third-party framework. `System/` is the framework, `Application/` is the app, and
`Configs/` wires them together.

```
oakspireweb/
  docker-compose.yml        apache + php-fpm + mariadb + phpmyadmin + redis-stack
  .env                      MYSQL_*, REDIS_PASSWORD, WEBSITE_URL, API_URL
  db.sql                    STALE dump — see "Tables" below
  changes.txt               informal migration log, newest phase at the bottom
  api.md                    stale curl examples from the Bourboneur era
  http/public/              document root
    index.php               bootstrap;  cli   CLI entry point
    Configs/                Application.php, Database.php, Redis.php, Website.php, Routes/
    System/                 the framework: Core/, Models/, Libs/, Helpers/, Responses/
    Application/
      Controllers/          admin controllers; Api/ (mobile), Api/V2/, Ajax/, Helpers/
      Models/               one class per table, extends System\Core\Model
      Commands/             cron jobs
      Views/                admin panel templates
      Uploads/              user-uploaded bottle images (gitignored)
      Composer/vendor/      firebase-php, phpmailer, stripe-php, mailchimp — vendor is committed
    oak-website/            static marketing site + blog
```

## Running it

```sh
docker compose up -d        # from the oakspireweb root
# apache :80, mysql :3306, phpMyAdmin :8080, redis :6379, RedisInsight :8001
docker compose exec php php cli priceUpdate     # run a cron command by hand
```

**Deploying to the server** is `sh scripts/deploy.sh` (in `~/oakspireclub`). It fast-forwards to
`origin/phase6` only, refuses to run if the server has local commits or edited tracked files, and
checks `http/public/oak-website/index.html` afterwards. A plain `git pull` used to merge a stray
server-only commit back in on every pull, which is how the marketing site kept disappearing.
Server-only values go in the server's `.env` (e.g. `APP_SCHEME=https`, read by
`Configs/Application.php`) and in `docker-compose.override.yml` (gitignored; see
`docker-compose.override.example.yml`), never in tracked files.

`http/` is bind-mounted into the apache and php containers, so edits are live — no rebuild.
`.dockerignore` excludes `http/public/*` from the image on purpose.

**The Host header decides which app runs.** `Application::_matchApplicationHost` compares the
request host (with `www.` stripped) against `site_urls`, which comes from `WEBSITE_URL` /
`API_URL` in `.env` (`oakspireclub.com` / `api.oakspireclub.com`). An unmatched host does not
404 — it `exit`s with *"You are not allowed to access from this domain"*. Hitting
`http://localhost` produces exactly that, so point a hosts entry (or send a `Host:` header) at
the configured domain when testing locally.

## Routing

Two route tables, keyed by the matched host, both registered in `Configs/Routes.php`:

| Host key | Table | Serves |
| --- | --- | --- |
| `website` | `Configs/Routes/Website.php` → `Versions/v1.php` + `Versions/v2.php` | everything this app calls, plus admin + marketing |
| `api` | `Configs/Routes/Api.php` | the `api.` subdomain — a smaller, older, partly stale table |

**This app talks to the `website` host**, base URL `https://www.oakspireclub.com/v2/api/`.

`Application\Libs\RouteExtender` builds that table: if the URI contains a `/vN/` segment it
merges the version's overrides over the v1 table with `array_replace`, then prefixes **every**
key with the literal string `/v2`. Consequences worth knowing:

- Only `v2` exists. An unknown `/v3/...` throws `RequestError("Unknown version in the url")`.
- The prefix is hardcoded `/v2`, not the matched `$prefix` — a future `v3` would still mount at `/v2`.
- **Only two routes are actually overridden in v2** (`Versions/v2.php`):
  `/v2/api/collection/chart-data` and `/v2/api/collection/add` → `Api\V2\Collection`.
  Every other `/v2/api/...` call this app makes is served by the **v1** controller in
  `Application/Controllers/Api/`. When tracing an endpoint, check `Api/V2/` first, then `Api/`.

Route values are `'Namespace\Controller::method'` resolved under `Application/Controllers`.
Placeholders are `(:num)` → `([0-9]+)` and `(:string)` → `([^/]+)`, read in the controller with
`$request->param(0)`. Prefixing a key with `POST:`/`GET:` constrains the verb; almost nothing
does, so most endpoints accept either — `$request->get()` reads `$_GET` and `$request->post()`
reads `$_POST`, and which one an endpoint uses is decided per parameter, not per route. That is
why some of the app's "POST" calls carry query strings (`categories/list`).

Request flow: `index.php` → `Autoloader` → preload configs → `Application::init` → `Router`
regex match → `new Controller($modelList)` → `$controller->$method($request, $response)` →
`$response->render()`. Redirects and 404s are thrown as exceptions (`Redirect`, `Error404`,
`RenderPages`) and caught in `Application::_bootstrap`.

## The API envelope

`Application\Response\Api::ApiResponse($code, $data)` renders `{"code": ..., "data": ...}`.
`$code` is only ever `OK` or `NOT_OK` — anything else throws. This is the contract behind
`ApiResponseHandler.ensureOk` in the app.

**On `NOT_OK`, `data` is usually a plain string** — the human-readable message the app surfaces
as `ApiException.message`. The exception is the free-tier limit, where `data` is a map:

```php
Api::ApiResponse('NOT_OK', [
    'flag' => 'LIMIT_EXCEEDED',
    'message' => "You have exceeded your free collection limit. Maximum allowed bottles: {$maxBottles}",
    'max_bottles' => ..., 'current_bottles' => ..., 'requested_quantity' => ...,
])
```

That is the `data.flag == 'LIMIT_EXCEEDED'` the app intercepts globally. It is raised in
`Api\Collection::add` **and** `Api\V2\Collection::add`, gated on
`is_free == 0 && subscription_status != 'subscribed'`, with the cap read from the
`collection_limits` row for user type `free`.

**Everything serializes as strings.** `Configs/Database.php` sets
`PDO::ATTR_STRINGIFY_FETCHES => true`, so every column — ints, decimals, timestamps — comes back
as a string and lands in JSON quoted. That is why the app's models parse with
`json['x']?.toString()`, and where literal `"null"` strings come from.

`Application/Controllers/Helpers/ApiResponseHelper::GetApiResponse` calls `setMsg()`, which does
not exist on `Api` — it is dead code and would fatal if called. Use `Api::ApiResponse` directly.

## Auth (there is none on the app API)

The app API has **no tokens and no session**. Identity is the `user_id` form field or query
param, trusted as-is — any user id can be passed for any user. That is the backend half of the
app's "No auth token" convention, not an oversight in the client.

- `Application/Middleware/ApiAuthenticate.php` does implement `Bearer` checks against the
  `api_access_token` table (managed under `/api-manager/*`), but **no route this app uses
  extends it**. Only `Api\Outer\BlueBook`, the public partner endpoint, is in that family.
- The **admin panel** uses a real PHP session (`System\Models\AbstractAuth` → `Admin` model,
  `session.put('user')`). Individual admin controllers do not guard themselves;
  `GlobalHelper::checkPermission` exists but its sub-admin permission logic is commented out.
- `Configs/Website.php` defines a `master_password`. `Api\Auth::login` returns a successful
  session for **any** email when that string is submitted as the password. Worth knowing when a
  login "works" unexpectedly — and never paste that file's contents anywhere: it also carries
  live Razorpay keys, the Mailchimp key, and SMTP credentials, all committed to git.

## Data layer

`System\Core\Model` is a singleton registry: `Model::get(User::class)` returns one shared
instance per class. Models hold `$_table` and a `$_db` (`System\Core\Database`, a thin PDO
wrapper: `query($sql, $params)->get()/getAll()/rowCount()`, `insert($table, $data, $replace)`,
`update($table, $id, $data)`). SQL is hand-written in the models; all of it is parameterized.

Controllers extend `System\Core\Controller`, which auto-instantiates the models listed under
`enable_system_modules[<host>]` in `Configs/Application.php` (session, language, email…) as
lowercase properties. Everything else is fetched explicitly with `Model::get`.

### Tables

`admin`, `api_access_token`, `app_config`, `blogs`, `blog_comments`, `bluebook`,
`bluebook_price_history`, `categories`, `collections`, `collection_limits`, `email_otp`,
`favorites`, `firebase_tokens`, `good_pour`, `issues`, `last_updates`, `notifications`,
`notification_preference_types`, `orders`, `packages`, `price_index`, `ratings`,
`razorpay_webhook_data`, `transactions`, `users`, `user_fcm`, `user_notification_preferences`,
`wheel_of_destiny`, plus `test_apple_data` (written ad hoc by the Apple webhook).

**`db.sql` is stale.** It is a 13-table dump from the older Bourboneur schema, missing
`collections`, `categories`, `bluebook_price_history`, `price_index`, `collection_limits` and
most of the rest. Do not treat it as the schema. `changes.txt` is the informal migration log —
its last entries cover phase 6 (`collections.fill`, `collections.price_paid`,
`collections.image`, and `bluebook.user_type` / `bluebook.user_id`). The live database is the
only source of truth; read it through phpMyAdmin on `:8080`.

### Bottles: `bluebook`

Every bottle is a `bluebook` row with `average` / `low` / `high` prices. `user_type` splits the
catalog: `admin` rows are the curated market list (what `bluebook/get-all-bluebooks` returns,
filtered to `active`), and `user` rows are bottles someone created through `bluebook/create`.
`Api\V2\Collection::add` rejects a `user`-owned bottle that belongs to a different user.

## Redis cache

`Application\Models\Cache` wraps phpredis: keys are prefixed `my_cache:`, composed with
`Cache::generateKey($a, $b, ...)` (joined with `#`), and used via
`remember($key, $ttl, $callback)` / `delete` / `deleteByPrefix`. This is server-side and entirely
separate from the app's Hive `AppCache`.

`Api\V2\Collection::chartData` memoizes three pieces for 24h — the chart series
(`<userId>#chart#normal#<minDate>#<maxDate>`), the overall trend
(`<userId>#priceTrend#normal#<today>`), and the shared index series
(`indexData#<minDate>#<maxDate>`) — and `Api\V2\Collection::add` invalidates the first two by
prefix. Any new mutation path that changes a user's collection must do the same, or the app will
keep receiving a stale chart for up to a day even after `forceReload()`.

`Configs/Redis.php` has a `redis_cache_off => true` key that is read into an `enabled` flag and
then never checked — caching is always on, and a Redis connection failure throws `SystemError`
rather than degrading. If the API starts failing wholesale, check that `redis-stack` is up.

## Cron commands

Registered in `Configs/Application.php` under `commands`, run as `php cli <name>` from
`http/public`:

| Command | What it does |
| --- | --- |
| `priceUpdate` | Snapshots every `bluebook` row's average/low/high into `bluebook_price_history` for today. **This is what gives the app's charts any history** — if it stops, every chart flatlines. Intended daily at 00:00 (`changes.txt`). |
| `priceIndexUpdate` | Recomputes the `secondary_market` row in `price_index` (`trend` up/down plus `movement` %). That row is the `index` object in the chart-data payload. Note it compares today against `date('Y-01-01')`, i.e. Jan 1 of the current year, despite the variable being named `$yesterday`, and divides without a zero guard. |
| `firebaseMessage` | Sends up to 100 pending `notifications` rows via `kreait/firebase-php`. |
| `marketStats` | Rewrites `bluebook_market_stats`: each eligible bottle's 30/90/365-day change and 365-day high/low. Nightly after `priceUpdate`. |
| `marketIndexUpdate` | Brings every `market_indexes` row up to today in `market_index_values` (equal-weighted, chain-linked; `--rebuild` recomputes from `base_date`). Nightly after `priceUpdate`. |
| `preCacheChart` | Computes `getOverallPriceTrendForEveryone` and **discards the result** — currently a no-op. |
| `processRazorpayWebhooks` | Drains queued `razorpay_webhook_data` rows through `Package::processQueuedRazorpayWebhookRecord`. |

**Push notifications only ever go to the topic `uncategorized`** (`Firebase::TOPIC_UNCATEGORIZED`
is the sole argument `sendMessagesToTopic` is ever called with). The `oakspire_*` topic tree this
app subscribes to in `FirebaseNotificationTopics` is not targeted by any backend code today, and
`notification-preferences/update` only writes `user_notification_preferences` rows — it does not
drive delivery. Treat per-preference push as unimplemented server-side.

## Payments

Three gateways coexist, in order of how live they are:

- **Razorpay** (Android) — `Api\Package`, ~1500 lines, the bulk of the payment logic. Raw cURL
  against `https://api.razorpay.com/v1/` (no SDK): `_createRazorpayPlan`, `_createRazorpayOrder`,
  `_createRazorpaySubscription`, `_cancelRazorpayGatewaySubscription`. Webhooks land at
  `/api/package/payment-webhook`, are signature-checked, stored in `razorpay_webhook_data`, and
  processed asynchronously by the cron. `_finalizeRazorpayPayment` is the single place where a
  payment outcome is written to `transactions` and `users.subscription_status`.
- **Apple IAP** (iOS) — `Api\Package::subscribe` handles the app-side purchase.
  `InAppPurchase::webhook` currently only base64-decodes the signed payload into
  `test_apple_data`; `InAppPurchase::removeExpired` later scans those rows for `EXPIRED` and
  flips `subscription_status` to `canceled`. Signature verification is not implemented.
- **Stripe** — `Controllers/Stripe.php` and the `stripe_*` config keys are legacy web-checkout
  flows. The app does not use them.

Subscription state lives on `users`: `subscription_status`
(`not_subscribed` | `payment_failed` | `subscribed` | `canceled`), `package_id`, `is_free`,
`is_trial_used`, `subscription_id`, `customer_id`, `payment_method_id`. `User::getUserInfo` —
the payload behind `user/get-by-id`, `auth/login`, `auth/register` and `auth/update` — joins
`packages` for `package_type` / `package_name` / `package_price` / `subscription_type`, and
**coerces `subscription_status` to `'subscribed'` whenever `is_free = 1`**. That is why the app's
`isFreeUser` getter means "backend-granted premium". `password` is selected out of this payload.

## Handlers for the endpoints this app calls

All paths are under `Application/Controllers/`:

| App endpoint | Handler |
| --- | --- |
| `auth/*`, `user/get-by-id` | `Api/Auth.php`, `Api/User.php` (OTP via `email_otp`, mail through PHPMailer/Gmail SMTP) |
| `config/all` | `Api/Config.php` — reads `Configs/Website.php` plus the `app_config` version row written by `/app/updater` |
| `collection/all`, `collection/delete-by-user-bottle` | `Api/Collection.php` |
| `collection/chart-data`, `collection/add` | `Api/V2/Collection.php` (**v2 override**) |
| `bluebook/*` | `Api/BlueBook.php` (`getAdminBottles` is the paginated, category-filtered market list; `sparklines` serves `bluebook/sparklines`) |
| `bluebook-price-history/chart-data-dashboard` | `Api/BluebookPriceHistory.php` |
| `market/overview`, `market/indexes`, `market/index-detail`, `market/highlights` | `Api/Market.php` (models `MarketStats`, `MarketIndex`, `Collection`; cached in Redis under `market#`) |
| `categories/list`, `categories/detail` | `Api/Category.php` |
| `package/*` | `Api/Package.php` |
| `usertoken/*` | `Api/UserToken.php` (`user_fcm` table) |
| `notification-preferences/update` | `Api/NotificationPreference.php` |

`config/all` is where `upload_url` (`Application/Uploads`), `pour_image_placeholder`,
`razorpay_key_id` / `razorpay_key_secret`, `current_version` (the forced-update payload) and the
terms/privacy URLs come from. Bottle images uploaded through `collection/add` are moved to
`Application/Uploads/<rand>_<time>.<ext>` and resolved client-side against `upload_url`.

Chart shaping: history is **change-only** (`priceUpdate` writes a row only when a price moves),
so a bottle's price on a date is its latest row on or before it.
`Controllers/Helpers/PriceSeriesHelper` is the one place that reads history that way — daily
weighted sums (collection value, BSMI index), as-of values (`first_price` / `last_price`), and a
single bottle's change points with a point at each end of the window. `Models/Collection`'s chart
methods, `bluebook/get-price-history` and dated `chart-data-dashboard` all go through it.
`Api\V2\Collection::chartData` caches under a versioned key (`CHART_CACHE_VERSION`) for 3 hours.
The app's `ChartIndexComparison` rebases on top of that.

`PriceSeriesHelper::sparklines($ids, $minDate, $maxDate, $samples = 24)` backs `bluebook/sparklines`.
- For each bottle it returns the as-of price on `$samples` evenly spaced dates (the end is capped
  at today). Bottles with no price are left out.
- It needs only the seed query (`_seed`) and `rowsBetweenForBottles`, so the query count stays
  fixed however many bottles are asked for. Don't add a per-bottle query loop.
- `Api\BlueBook::sparklines` (v1 route, inherited by `/v2`) reads `ids`, comma separated, capped
  by `SPARKLINE_MAX_IDS` = 60. It reads `days` from 30 / 90 / 180 / 365 (default 90).
- It caches the result in Redis for `SPARKLINE_CACHE_TTL` (3 hours), keyed
  `sparklines#v1#<days>#<date>#md5(sorted ids)`.
- It returns `{id: {points: [{d, p}], first, last, change_pct}}`. The map is cast to an object,
  so an empty result is `{}`, not `[]`.

**Market stats and indexes** (`database/2026-10-05_market_stats_and_indexes.sql`):
- `MarketStats::eligibleWhere` is the single definition of a "market" bottle: an active admin
  bottle with average ≥ $30, basis not `manual`, and confidence not `low` / `stale`. Legacy
  prices with no basis are in, because they are most of the catalog. Movers, sorts and every
  index use it.
- An index is equal-weighted and chain-linked. Each day it moves by the mean return of the bottles
  priced the day before. A bottle's daily return is capped at ±50%, and new bottles never move
  it. Membership is `rule_type` (`all`, `indexed`, `allocated`, `rare`, or `category` +
  `rule_value`). Add a category index by inserting a row, then run `marketIndexUpdate`.
- `bluebook/get-all-bluebooks` `sort`: `name` (default), `price_desc`, `price_asc`, `gain_30d`,
  `loss_30d`, `premium`. The gain sorts join the stats table and list only bottles that have a
  30-day change. Every other sort skips the join, because joining 250k rows costs most of a
  second. `BlueBookHelper::withMarketStats` adds the page's `market` objects in one query.

**Market highlights** (`database/2026-10-06_market_highlights.sql`, `Api\Market::highlights`):
- `days` (30 / 90 / 365, default 30) sets the breadth window only, and is part of the Redis key.
- `bluebook_market_stats.first_priced_on` is each bottle's first history date, written by
  `marketStats`. `MarketStats::newlyPriced` ignores any day on which more than 250 bottles got
  their first price, because that is a catalog import or the start of the history, not a
  release. The local catalog's first prices nearly all fall on one import day.
- The community lists (`Collection::mostCollected`, `hotByAdds`, `topRatedHeld`) count distinct
  collectors on `normal` rows. They cover active admin bottles only, never a user's own
  bottles. Each row needs at least `COMMUNITY_MIN_COLLECTORS` (3) collectors, or
  `COMMUNITY_MIN_RECENT_ADDERS` (2) for hot, so no row shows one user's shelf. With few users
  these lists are empty, and Home hides them.
- Each part is wrapped in `_safe`, so a missing table gives an empty part, not an error.

## Other surfaces, for orientation

- **Admin panel** — `Controllers/<Entity>.php` renders a `View` (a `Common/header` +
  `Common/sidebar` + page + `Common/footer` stack, with a tiny `<define>`/`<call>` template
  preprocessor in `System/Responses/View.php`); `Controllers/Ajax/<Entity>.php` serves the
  DataTables JSON behind it. `/app/updater` sets the version payload the app's forced-update check
  reads. `/bottles/price-index`, `/categories/*`, `/rare-bottles/*` and `/notification/*` are the
  screens that most directly change what the app shows.
- **Import** — `Api\Import::baxus` (scrapes/imports an external source) and
  `Api\Import::csvOnlyDrams` (accepts a `csv_content` body). Both write `bluebook` rows.
- **Export** — `/export/collection/(:string)` and `/export/chart-dashboard/(:string)` back the
  `collection_download_url` handed to the app in `config/all`.
- **`Api\ShareMarket::snp`** fetches S&P 500 history from Yahoo Finance for comparison charts.
- **Unused by this app**: `wheel_of_destiny`, `good_pour`, blogs/blog comments (the blog lives in
  the marketing site), `favorites`, and `rating/*`.

## Working in there

- No tests, no linter, no build step. PHP is edited and served directly.
- `environment` in `Configs/Application.php` is `'dev'` and `.user.ini` sets `display_errors = On`,
  so PHP warnings can be emitted **before** the JSON envelope and break client parsing. If the app
  suddenly fails to decode a response, curl the endpoint and look for stray text above the JSON.
- Uncaught `SystemError` / `RequestError` are `echo`ed as plain text with HTTP 200, not returned as
  an envelope. A "malformed response" in the app is usually one of these.
- `System/Core/Database::_getConfig` assigns `$port = $config->database`, so the DSN carries the
  database name in the port slot. It works against the containerized MySQL; do not "fix" it
  casually without testing the connection.
- Branching: `phase6` is the default branch; feature work has been landing through `krishna*`
  branches and PRs.
