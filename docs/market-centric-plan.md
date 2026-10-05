# Oak Spire: from collection-centric to market-centric

## Context

Today the app opens on Home, and Home is entirely about the user's own collection: value, gain,
the user's own "top moved" bottles, and a value-vs-BSMI chart. The market (Benchmark tab) is a plain
alphabetical list with search and category chips. It has no overview, no sort, and no market-wide
movers. The "Updated …" label is loaded but never rendered.

The goal is to make the market the reason people open the app. People look up bottle prices, then
decide what to do: buy, hold, sell, or add to their collection. Subscription work is out of scope.

What already exists and can be reused (no new data source needed):
- Per bottle: `average/low/high`, `pricing` (basis, confidence, observation count), and `details`
  (including `msrp`, `isAllocated`, age, ABV). The models are `BluebookModel`, `BottlePricing` and
  `BottleDetails` in `lib/app/data/models/`.
- Price history and sparklines: `bluebook/sparklines` (30/90/180/365 days) and
  `chart-data-dashboard`. On the server, `PriceSeriesHelper` already computes as-of prices for any
  set of bottles.
- The index series: `Models\Collection::getIndexDataDashboard`. It is only exposed inside
  `collection/chart-data` today.
- A `favorites` table plus `/api/favorite/*` routes, which can become the watchlist. `all` needs a
  bluebook join, and its stray `RatingHelper::prepare` call needs fixing.
- The admin-only `Models\MarketValue` has rise/fall/value sorts and `summary()`. Reuse its SQL ideas
  rather than writing new ones.
- `ai-features-plan.md` §2.3 "Tier 0 descriptive" (trailing changes, best/worst movers) is already
  planned as "can start now".

## What users get (ranked by value ÷ effort)

| # | Feature | Why a market user cares | Effort |
|---|---|---|---|
| 1 | **Deal check** on bottle detail: type an asking price and see it placed on the low–avg–high bar, with a verdict (below recent low / good / fair / above avg / above recent high) | It answers "should I pay this at the shop or in this listing?". This is the moment they open the app. | App only |
| 2 | **× retail chip** (average ÷ MSRP) on rows and detail | Bourbon hunters think in "secondary premium". It is instant context. | App only |
| 3 | **Change over the selected range** next to the price on detail (e.g. "+11% in 1Y") | Today detail shows only "last change %", which can be months old | App only |
| 4 | **Market overview** at the top of the Market tab: index value, its today/30d/90d/1y change and a sparkline, plus 30-day gainers and losers | It gives people a reason to open the app daily without owning anything | Small backend |
| 5 | **Sort** on the market list: price high/low, 30d gain/loss, premium over retail | Browsing 250k bottles alphabetically has no value | Small backend |
| 6 | **Watchlist** (star a bottle), showing "since watched ±%" | The bridge from looking to deciding. It works before the user owns anything. | Small backend + app |
| 7 | **Signals on your bottles**: at a 12-month high, or below what you paid | Turns market data into a collection decision (sell, hold, drink) | App + stats from #4 |
| 8 | **Price alerts** on watched bottles (target price, or a ±X% move) | The strongest retention hook, but it needs per-user push | Medium backend |

Guardrails apply to everything above:
- Movers and verdicts exclude `pricing.isThin` and `manual` ("Oak Spire price") bottles, or label
  them as thin, so a single noisy observation never tops the gainers list.
- Copy describes price ("11% under market average"), never advice ("Buy").

## Decisions (confirmed)
- **This build: Phase 1 + Phase 2.** Watchlist and alerts are follow-ups.
- **No guest mode.** Sign-up stays first, and the auth flow is untouched.
- **Home is folded into Collection.**

## Target navigation

This build ships **Market (default) · Collection · Settings popup**. In Phase 3 the Watchlist tab
goes between Market and Collection.
- Market = overview card + movers + the existing search/category list (with sort).
- Home is retired:
  - Its top-moved strip (`home_top_moved.dart`) and quick stats (`home_quick_stats.dart`) move into
    the Collection tab, above the list. Collection already has a value header and chart.
  - `HomeController`'s `_applyHeaderMove` / `headerMoveText` move to `CollectionController`, and
    `app_header.dart` line 2 reads it from there.
  - Every caller that refreshes Home moves to Collection only:
    - taste's add flow;
    - `AddToCollectionLauncher.open`;
    - the `forceReload` calls after `/taste-bottles`;
    - `BottomNavController`'s background `fetchHomeData`.
  - The empty-collection CTA ("Add your first bottle") already exists in the Collection empty state.
- Keep `bottom_nav_shell.dart`, `BottomNavController.headerTitle` and
  `AnalyticsScreens.shellTabScreenName` in sync, per CLAUDE.md. The back handler returns to Market
  first, then asks to exit.
- Update CLAUDE.md's screen map and shell description to match.

## Phased build

### Phase 1: app-only quick wins (no backend changes)
1. **Deal check card**: new `lib/app/modules/market/widgets/benchmark_deal_check.dart`, placed in
   `benchmark_detail_view.dart` after the chart row.
   - Its state is `askingPrice` (an Rx double) in `BenchmarkDetailController`, computed against the
     `average/low/high` already in `BenchmarkDetailRouteArgs`.
   - Put the verdict logic in a pure helper, `lib/app/data/deal_check.dart`, so it can be unit
     tested next to `collection_value_test.dart`.
   - When `pricing.isThin` or `isOakSpirePrice` is true, show a "thin data" caption.
2. **× retail**:
   - Add a `retailMultiple(double average)` getter/helper on `BottleDetails`. It returns null when
     `msrp` is missing or ≤ 0.
   - Add the chip to `market_bottle_row.dart` and to `benchmark_top_summary.dart`'s tags.
   - First verify that list payloads carry `details.msrp`. They already carry `details` for chips.
3. **Range change**: compute first→last of the loaded chart series in `BenchmarkDetailController`
   and show it beside the price in `BenchmarkTopSummary`.
4. **Market first**:
   - Reorder the shell so Benchmark (renamed "Market") is index 0 and the default landing tab.
   - Render `MarketController.lastUpdatedText`.
   - Update the back handler ("return to Home first" becomes "return to Market first") and the
     analytics tab names.

### Phase 2: market data endpoints (oakspireweb) + overview UI
1. **Nightly stats**: a new `marketStats` command, run after `priceUpdate`. It writes
   `bluebook_market_stats` with these columns: `bluebook_id`, `change_30d`, `change_90d`,
   `change_365d`, `high_365d`, `low_365d`, `computed_at`.
   - Computed set-based through `BlueBookPriceHistory::latestBeforeDateForBottles`, with no
     per-bottle loop.
   - Only for active admin bottles that have a price.
2. **`GET market/overview`**, a new `Api\Market::overview`. It returns:
   - the headline Oak Spire Index from `market_index_values` (current value, today/30/90/365 change,
     a 90-day series);
   - the top 10 gainers and losers over 30 days, filtered to confidence high/medium, basis not
     `manual`, and average ≥ a floor such as $30;
   - `last_updated`.
   Cache it in Redis until the next cron.
3. **Oak Spire indexes**: our own, not scraped (see "Why not Bourbon 40+" below).
   - **Tables:**
     - `market_indexes`: `id`, `slug`, `name`, `description`, `rule`, `base_date`, `base_value`
       (1000), `active`. `rule` is a category id, an explicit bottle list, or `is_indexed`.
     - `market_index_values`: `index_id`, `date`, `value`, `constituents`, unique on
       (index_id, date).
   - **Starter set:**
     - **Oak Spire Index**: every `is_indexed` bottle. This replaces the BSMI row.
     - **Allocated**: `is_allocated`.
     - **Rare**: `is_rare`.
     - One index per major category from `category_bottles` (e.g. Buffalo Trace Antique Collection,
       Van Winkle, Bottled-in-Bond). Admins pick which categories get one.
   - **Method:**
     - Equal-weighted and chain-linked. Each day's return is the mean of the constituents' daily
       returns, using only bottles priced on both days.
     - `value_t = value_{t-1} × (1 + r)`. This handles bottles joining or leaving without jumps.
     - It excludes `manual` basis and thin confidence.
     - A new `marketIndexUpdate` command runs nightly after `priceUpdate` and backfills from
       `base_date` on first run. It reads as-of prices set-based through `PriceSeriesHelper`.
   - **Endpoints:**
     - `GET market/indexes`: each index's current value, today/30d/90d/1y change and a 90-day
       sparkline.
     - `GET market/index-detail?slug&days`: the series, constituents with their individual change
       (biggest contributors first), and the methodology text.
   - **App:**
     - A horizontal strip of index cards at the top of Market. The headline card is the Oak Spire
       Index.
     - A new `/market-index` route (`modules/market_index/`) with the chart (reuse
       `BenchmarkPriceChart`'s step-line style and `AppSegmentedRange`), a constituents list (reuse
       `MarketBottleRow`) and a "How this index works" section.
     - The Collection chart's BSMI line switches to the Oak Spire Index series.
   - **Before publishing:** check the production mix of `price_basis`. If most bottles are still on
     `manual` admin prices, the index is not a market index. Either label it "Oak Spire price
     index" or hold it until the ingest bot's sold data is live in production.
4. **`sort` param** on `bluebook/get-all-bluebooks` (`Models\BlueBook::getAdminBottles`):
   `name|price_desc|price_asc|gain_30d|loss_30d|premium`. It joins the stats table, and
   `MarketValue`'s sorts are the reference.
5. **App**:
   - `MarketRemoteDataSource` / `MarketRepository`, registered in `AppBinding`, with a short cache.
   - A `MarketOverviewHeader` sliver in `market_view.dart` with the index card and a
     gainers/losers toggle.
   - A sort menu (reuse the Collection sort menu pattern) that passes `sort` through
     `PagedBottleSearch`.
   - The nav changes to Market · Collection, with Home folded into Collection as described above.

### Why not Bourbon 40+ (bourbon40.com)
- It updates quarterly, which is too slow for an app people open daily.
- It covers only 45 bottles, equal-weighted, from auction data.
- It offers no API and no data licence. Scraping it means building on another person's methodology
  and brand without permission, and it can change or block at any time.
- **Optional later:** ask the founder (contact on the site) for permission to show it as an
  attributed external benchmark. An admin would enter it quarterly, and it would show beside our own
  index. Don't block on it.

### Phase 3: watchlist
- **Backend**:
  - Fix `Api\Favorite::all` so it joins bluebook with prices, `pricing` and `details`, and adds the
    as-of price at `favorites.created_at` (`PriceSeriesHelper::valueOn`).
  - Drop the `RatingHelper::prepare` misuse.
- **App**:
  - `FavoritesRemoteDataSource` / `WatchlistRepository`.
  - A star toggle on detail and on rows.
  - A `modules/watchlist/` tab with "since watched ±%" and sparklines (reuse `PriceSparklineView` and
    `BluebookRepository.sparklines`).
  - A watchlist strip on Market.
- **Signals card** for owned bottles at a 12-month high, or below price paid. It uses
  `high_365d` and `CollectionItemDisplay.gainPercent`.

### Phase 4: alerts and discovery (later)
- **Price alerts**:
  - Add a `target_price` / `alert_pct` on favorites.
  - A nightly cron compares watched bottles against those thresholds.
  - Add a send-to-token method on `Models\Firebase` (kreait multicast) that uses `user_fcm`.
- **"Similar bottles"** on detail, from the vector search in `ai-features-plan.md` §1.

## Verification
- `flutter analyze`. Also run `flutter test` with new unit tests for the deal-check verdict bands
  and for `retailMultiple`.
- Run against the local docker backend:
  `flutter run --dart-define=API_BASE_URL=http://10.0.2.2/v2/api/`.
- Check detail across bottles with thin, manual and missing-MSRP pricing.
- Phase 2:
  - Run `docker compose exec php php cli marketStats`.
  - Curl `/v2/api/market/overview` and look for stray PHP warnings above the JSON.
  - Confirm thin and manual bottles never appear in the movers lists.
  - Run `php cli marketIndexUpdate` twice. The second run must change nothing (idempotent).
  - Spot-check one index's 30-day change by hand against its constituents' as-of prices.
  - Confirm that adding or removing a constituent causes no jump in the series.
