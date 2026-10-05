# Plan: ratings out of 10, true collection value, richer collection rows, sparklines, header

## Context

Six requests from the product owner:

1. **Ratings out of 10 everywhere.** The backend stores `bluebook.rating` on a 0–100 scale (admin form `BottleFormHelper` says `max 100, unit /100`; an empty rating is saved as `0`). The app prints the raw number in the Market rows and on benchmark detail (e.g. "92"), but Home Quick Stats converts the collection average to a 0–5 scale. The three screens disagree.
2. **Collection value is wrong.** `CollectionController.load` sets the hero figure from `CollectionValueCalculator.totalInvestedFromItems` (what the user paid), not today's market value. Home already does it right (`HomeController._applyValueFigures`), so the two tabs show different numbers for the same collection.
3. **Collection % is wrong.** The badge beside the value is the 90-day chart move (`first_price`/`last_price`), not gain against what the user paid.
4. **Collection cards are thin.** They show art, name, proof, price paid × qty and fill. The user wants current value, gain vs paid, price movement and a small chart per bottle. **Decision: switch to full-width list rows.**
5. **Header is plain.** It shows only "Good morning, Akash". **Decision: add a member badge and a "today's move" line.**
6. **Sparklines on Benchmark (Market) rows**, too. Benchmark detail already has a full chart.

Two existing bugs make #2 and #3 worse, so they get fixed here as well. Both are in `CollectionRepository._groupCollectionItems` ([collection_repository.dart:23](lib/app/data/repositories/collection_repository.dart#L23)), which merges duplicate rows of the same bottle:
- The merged `pricePaid` is a plain average of unit prices that ignores quantity. Paying $100 for 1 bottle and $200 for 3 gives $150, but the right figure is $175. That skews "invested" and every gain figure.
- The merged row drops `priceMovement` because it is never passed to the constructor. So any bottle the user owns in more than one row loses its movement figure, both in Home's "top moved" list and on the new rows.

---

## 1. Ratings out of 10

**New** `lib/app/core/utils/rating_formatter.dart`:
- `double? RatingFormatter.outOfTen(Object? raw)`: parse the value, return null when it is missing, `'null'` or `<= 0` (0 means "not rated"), otherwise return `value / 10` clamped to 0–10. Always divide: the backend scale is defined as /100.
- `String label(raw)`: one decimal, with a trailing `.0` dropped (`9.2`, `9`); `'—'` when null.
- `String labelOutOfTen(raw)`: `9.2/10`, used where there is room.

Apply it at:
- [market_bottle_row.dart:152](lib/app/modules/market/widgets/market_bottle_row.dart#L152): `RatingFormatter.label(bottle.rating)`. Hide the star and number when there is no rating, instead of showing "—".
- [benchmark_detail_controller.dart:189](lib/app/modules/market/benchmark_detail_controller.dart#L189): `ratingDisplay` becomes `RatingFormatter.labelOutOfTen(args.rating)`, and the `_RatingChip` in `benchmark_top_summary.dart` renders it.
- [home_controller.dart:342](lib/app/modules/home/home_controller.dart#L342): replace the 0–5 conversion with `RatingFormatter.label(chart['collection_rating_percentage'])`. That field is the quantity-weighted average of the same 0–100 column (`Collection::getCollectionRatingsSummary`). Show `/10` in the Quick Stats tile (`home_quick_stats.dart`).
- The new collection rows (§3) use `RatingFormatter.label(bluebook['rating'])`.

## 2. Collection value and gain (one source of truth)

**[collection_value_calculator.dart](lib/app/data/collection_value_calculator.dart)**: add a `CollectionValueSummary` value class and `CollectionValueCalculator.summarize(items)`:
- `invested` = Σ unit `pricePaid` × qty (unchanged meaning).
- `marketValue` = Σ (unit market average × qty) for rows with a bluebook price. Rows without one count at their price paid, so the headline total never drops a bottle. `valuedAtCostCount` records how many rows did that.
- `showingInvestedAsValue` = true when no row has a market price. The heading then reads "Total Invested", as Home already does.
- `gain` and `gainPercent` are computed **only over rows that have both a market price and a price paid > 0**: `(Σ market − Σ paid) / Σ paid × 100`. Rows valued at cost add nothing to the gain, so they cannot fake a 0% or skew it.
- Per-row helpers on `CollectionItemDisplay`: `marketTotalValue` (unit market × qty), `paidTotalValue`, `gainValue`, and `gainPercent` (null when either side is missing).

**[home_controller.dart](lib/app/modules/home/home_controller.dart) `_applyValueFigures`**: rebuild it on `summarize()`. The figures stay the same, but the rule for unpriced rows now matches Collection.

**[collection_controller.dart](lib/app/modules/collection/collection_controller.dart) `load` / `_applyFallbackValue`**:
- `valueAmount` comes from `summary.marketValue`, falling back to invested. Add `showingInvestedAsValue`, `investedText`, `gainAmount` and `gainPercent` observables.
- `trendShort` becomes `summary.gainPercent` (`+27.7%`), or `—` when it is null. Drop the 90-day `fetchChartData` call from this controller, since nothing on the screen uses it any more.
- Sorting: `CollectionSort.price` sorts by current unit value (falling back to paid). Add `CollectionSort.gain` (by `gainPercent`) to the sort sheet in `collection_filter_row.dart`.

**[collection_value_header.dart](lib/app/modules/collection/widgets/collection_value_header.dart)**:
- The heading switches between "Collection Value" and "Total Invested".
- Add a caption under the number: `Invested $X · +$Y` (plus "· N at cost" when `valuedAtCostCount > 0`).
- The badge shows the gain % in `AppColors.trendPositive` / `trendNegative` with an up or down arrow, instead of the static gold chart icon.

**[collection_repository.dart](lib/app/data/repositories/collection_repository.dart) `_groupCollectionItems`**:
- Merged `pricePaid` = Σ(unit × qty) / Σqty.
- Pass `priceMovement: base.priceMovement`.
- No cache-key change is needed: grouping re-runs on decode.

## 3. Collection list rows

**New** `lib/app/modules/collection/widgets/collection_bottle_row.dart`, styled like `MarketBottleRow` (`AppPressable` → `AppCard`, radius `AppRadii.md`):
- **Left:** `BottleImage` 66px (Hero via `heroBottleId`, the same rule as now).
- **Middle:**
  - Name (2 lines).
  - Origin line (distillery · region).
  - `BottleMetaChip`s for type, age and ABV/proof, plus Rare (gold) and the rating (star + `RatingFormatter.label`).
  - A thin `AnimatedFillBar` with fill %, `×N` when the quantity is above 1, and "Paid $X".
  - Build the chips from `BottleDetails.fromBottleJson(item.bluebook ?? {})`, exposed as `CollectionItemDisplay.details`. That factory already falls back to raw columns.
- **Right column:**
  - Current total value (bold cream), with `PricingBadge` compact when the bluebook carries `pricing`.
  - Gain vs paid, colored: `▲ +$41 · +27.7%`.
  - `PriceSparkline` at 64×24 (§4).
  - The last move as `PriceFormatter.formatPriceMovementLabel(item.priceMovementRaw)` in `bodyS`.
  - With no market price, show "Valued at cost", in muted text, in place of the gain and sparkline.

**[collection_view.dart](lib/app/modules/collection/collection_view.dart)**:
- Replace `_Grid`'s `SliverGrid` with a `SliverList`, separated by `AppSpacing.sm`.
- Keep `StaggeredEntrance(id: 'collection-${item.id}')`. It is id-based, so it is safe in a lazy list.
- Keep the hero-dedupe logic.
- Tapping a row still calls `showCollectionQuickView(cardContext, …)`.

**[collection_quick_view.dart](lib/app/modules/collection/widgets/collection_quick_view.dart)**: keep the card, and replace the `priceLabel ($qty)` line with current value plus the gain % (paid stays in a smaller caption). `CollectionCardDetails` stays as it is. Delete `CollectionBottleCard` itself once nothing references it, but keep the `kCollectionCard*` constants the quick view uses.

**[collection_loading_view.dart](lib/app/modules/collection/collection_loading_view.dart)**: change the skeleton to row shapes (`ShimmerScope` + `ShimmerBox`, with `AppColors.shimmerOnCardBase/Highlight` on card surfaces, following `TasteLoadingView`).

## 4. Sparklines (collection rows + Benchmark rows)

### Backend (`../oakspireweb`, branch off `phase6`)

**`PriceSeriesHelper::sparklines(array $ids, $minDate, $maxDate, $maxPoints = 24)`** in `Application/Controllers/Helpers/PriceSeriesHelper.php`:
- Uses the existing batch queries: `_seed($ids, $minDate)` (price in force at window open, with the earliest-row and `bluebook.average` fallbacks) plus `rowsBetweenForBottles($ids, $minDate, $maxDate)`.
- That is 2–4 queries in total whatever the number of bottles, with no per-bottle loop of queries.
- Per bottle: the change points with a point at each end of the window (same semantics as `bottlePoints`), with `maxDate` capped at today. Downsample to `$maxPoints` by taking the last price in each bucket. Cast to float.
- Returns `[id => ['points' => [['d' => 'Y-m-d', 'p' => float], …], 'first' => float, 'last' => float, 'change_pct' => float|null]]`.
- Bottles with no price at all are omitted.

**`Api\BlueBook::sparklines`** (`Application/Controllers/Api/BlueBook.php`) and the route `'/api/bluebook/sparklines' => 'Api\BlueBook::sparklines'` in `Configs/Routes/Versions/v1.php` (v2 inherits it):
- `ids` is a comma-separated GET param. Keep only ints and cap at 60 ids.
- `days` is limited to {30, 90, 180, 365}, default 90.
- Wrap the call in `Cache::remember(Cache::generateKey('sparklines', 'v1', $days, date('Y-m-d'), md5(sorted ids)), 3h, …)`, the same TTL idea as `CHART_CACHE_TTL`. History moves only nightly, so this is safe.
- Respond with `Api::ApiResponse('OK', $map)`.
- Add a line to `changes.txt`.

### App

**New model** `lib/app/data/models/price_sparkline.dart`: `PriceSparkline { List<double> prices; double? changePct; bool get isUp; }` with `fromJson` / `toJson`. Parse tolerantly, because payloads may be stringly-typed.

**[bluebook_remote_datasource.dart](lib/app/data/datasources/bluebook_remote_datasource.dart)**: add `static const sparklinesEndpoint = 'bluebook/sparklines'` and a `sparklines(ids, days)` method using `_client.get` + `parseEnvelope`.

**[app_cache.dart](lib/app/core/cache/app_cache.dart)**: add public `T? peek<T>(key, ttl, decode)` and `Future<void> put(key, json)` around the existing `_read` / `_write`. `getOrFetch` is single-key and cannot batch.

**[bluebook_repository.dart](lib/app/data/repositories/bluebook_repository.dart)**: add `Future<Map<String, PriceSparkline>> sparklines(List<String> ids, {int days = 90})`:
- Read each id from cache key `bluebook:spark:$id:$days` (TTL 6h).
- Fetch only the misses, in one request (chunks of 60).
- Write each result back, and also store an empty marker for ids the server omitted, so they are not refetched.
- **Swallow errors and return what it has.** An old server without the endpoint must only lose sparklines, with no error toast.
- Add the key to the "Cached reads" list in CLAUDE.md.

**New widget** `lib/app/core/widgets/price_sparkline.dart`: `PriceSparklineView(data, width, height)`.
- A `CustomPainter` inside a `RepaintBoundary`, not fl_chart: it is far cheaper per list row and needs no touch handling.
- Draw a **step line**, because history is change-only (this matches the CLAUDE.md "bottle chart is a step line" rule).
- Color it `trendPositive` / `trendNegative` / `textMuted` (flat), with a faint fill underneath.
- With `data == null`, draw a muted flat dashed baseline as the placeholder, so the row does not jump.
- Fade it in with `AppMotion.of(context, AppMotion.fast)`.

**Wiring:**
- `CollectionController`: after `items` load, `unawaited(_loadSparklines())` fetches every bluebook id at once into `final sparklines = <String, PriceSparkline>{}.obs`. The rows read it through `Obx`. On `forceReload`, pass `forceRefresh` through so the cache is bypassed.
- `PagedBottleSearch` ([paged_bottle_search.dart](lib/app/modules/shared/paged_bottle_search.dart)): add a no-op hook `void onBottlesLoaded(List<BluebookModel> page)`, called after `assignAll` / `addAll`.
- `MarketController` overrides that hook to fetch sparklines for the page's priced ids (`average > 0`) into its own `sparklines` RxMap. Taste does not override it, so the Add-a-bottle browser makes no extra calls.
- [market_bottle_row.dart](lib/app/modules/market/widgets/market_bottle_row.dart): `MarketBottleRow` takes an optional `PriceSparkline? sparkline`. The right column becomes:
  1. price + badge,
  2. sparkline 60×20,
  3. movement label,
  4. range.
  
  `market_view.dart:137` passes `controller.sparklines[bottle.id]` inside an `Obx`.
- Check the narrowest width (360dp) for overflow. If the right column gets too wide, drop the range line from the row (the detail page shows it).

## 5. Header: member badge + today's move

**[app_header.dart](lib/app/core/widgets/app_header.dart)**: `_GreetingText` becomes a right-aligned two-line `Column` that fits in `kShellAppBarHeight` (56).
- **Line 1:** `Good morning, Akash` plus a member pill.
  - `BottleMetaChip(label: 'PREMIUM', gold: true)` when `user.hasActiveSubscription || user.isFreeUser`.
  - Otherwise a muted `FREE` pill.
  - Read it reactively from `UserSessionController.user`.
- **Line 2:** `HomeController.headerMoveText`, in `AppTextStyles.micro`, colored by sign.
  - Hidden when it is empty, or when `HomeController` is not registered (guard with `Get.isRegistered`).
  - Animate changes with an `AnimatedSwitcher` + `AppMotion`.

**[home_controller.dart](lib/app/modules/home/home_controller.dart)**: in `_loadChart`, from the raw `marketPoints` (daily series, already parsed):
- `today = last − previous`.
- If `today != 0`: `▲ $124 today` (`$` formatted, with sign).
- Else take the 7-day change: `▲ $310 this week`.
- Else `Steady this week`.
- Empty when there is no collection or no chart data.
- Store the sign in `headerMoveUp` (an `RxnBool`) for the color.
- This needs no new API call: every chart range ≥ 30 days contains both points.

## Files

| Area | Files |
| --- | --- |
| New | `core/utils/rating_formatter.dart`, `core/widgets/price_sparkline.dart`, `data/models/price_sparkline.dart`, `modules/collection/widgets/collection_bottle_row.dart` |
| App, edited | `collection_value_calculator.dart`, `collection_item_display.dart`, `collection_repository.dart`, `collection_controller.dart`, `collection_view.dart`, `collection_value_header.dart`, `collection_quick_view.dart`, `collection_loading_view.dart`, `collection_filter_row.dart`, `home_controller.dart`, `home_quick_stats.dart`, `market_bottle_row.dart`, `market_view.dart`, `market_controller.dart`, `benchmark_detail_controller.dart`, `paged_bottle_search.dart`, `bluebook_remote_datasource.dart`, `bluebook_repository.dart`, `app_cache.dart`, `app_header.dart`, `CLAUDE.md` (API table, cached reads, rating scale note) |
| Backend | `PriceSeriesHelper.php`, `Api/BlueBook.php`, `Configs/Routes/Versions/v1.php`, `changes.txt` |

Suggested order:
1. The rating formatter.
2. The value/gain fix plus the grouping fix (the visible bugs).
3. The list rows without sparklines.
4. The backend endpoint.
5. Sparklines in Collection, then Market.
6. The header.

Ship the backend before an app build that calls it. The app tolerates the endpoint being missing either way.

## Verification

- `flutter analyze` clean.
- Run `docker compose up -d` in oakspireweb, then `flutter run --dart-define=API_BASE_URL=http://10.0.2.2/v2/api/` on an emulator.
- **Rating scale:** in phpMyAdmin, run `SELECT MIN(rating), MAX(rating), COUNT(*) FROM bluebook WHERE rating > 0`. It should confirm 0–100 before relying on the plain /10. Then compare one bottle across the Market row, benchmark detail and Home Quick Stats: they should agree (e.g. 92 → `9.2`).
- **Value/gain:** take a test user with known rows, for example bottle A (paid $100 × 2, market $150) plus bottle B (paid $50, no market price).
  - Expect value $350 and "1 at cost".
  - Expect gain +$100 and +50.0%. Gain covers bottle A only.
  - Home and Collection must show the same value.
  - Add a duplicate row of A at a different price and check that the weighted paid figure is right and that the movement survives grouping.
- **Endpoint:** `curl -H "Host: <WEBSITE_URL>" "http://localhost/v2/api/bluebook/sparklines?ids=1,2,3&days=90"`. It should return clean JSON with no PHP warnings above the envelope. Check the first and last points against `bluebook-price-history/chart-data-dashboard` for one bottle. Run it twice and confirm the Redis key in RedisInsight (:8001).
- **Performance:** scroll Market through 5+ pages with the Flutter DevTools performance overlay. Expect no jank, and exactly one sparklines request per page. Collection should make one request for all its bottles. A second visit within the TTL should make none.
- **Old server:** point the app at a backend without the route. Rows should show the placeholder baseline and no error toast.
- **Header:** check a premium and a free account; the pill should flip after a subscription refresh (`setUser`). The move line should appear only with a collection, and it must fit on a 360dp-wide emulator at the largest system font. Use Reduce Motion to confirm the switcher and sparkline fade turn off.
