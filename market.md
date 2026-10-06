# Oak Spire: market-centric app

Status as of **2026-10-05**. This is the working document for turning Oak Spire from a
collection tracker into a market app. It covers the goal, the decisions made, what is built,
what was verified, and what remains. The original approved plan is
[docs/market-centric-plan.md](docs/market-centric-plan.md). This file supersedes it where they
differ.

Branches: `market-centric` in both `oak_spire_club` (app) and `../oakspireweb` (backend).
Nothing from Phase 1 or 2 is committed yet.

---

## 1. Goal

The app used to open on Home, which was entirely about the user's own collection. The market
was a plain alphabetical list with no overview, no sort, and no market-wide movers.

The new direction: **people open the app to see where bottle prices are and where the market
is moving, then decide what to do** (buy, hold, sell, drink, add to the collection).
Subscriptions are out of scope for now.

What we offer such a user, ranked by value against effort:

| # | Feature | Why it matters | Status |
|---|---|---|---|
| 1 | **Deal check**: type an asking price and see it against low / avg / high | Answers "should I pay this?" at the shelf or in a listing | Done |
| 2 | **× retail chip** (market price ÷ MSRP) | Bourbon hunters think in secondary premium | Done |
| 3 | **Change over the chosen range** on the bottle page | "Last change %" alone can be months old | Done |
| 4 | **Market overview**: Oak Spire Index + biggest movers | A reason to open the app daily without owning anything | Done |
| 5 | **Sort** the market list (price, 30-day rise or fall, premium) | Browsing 250k bottles alphabetically has no value | Done |
| 6 | **Oak Spire indexes**: our own, several of them | "Where is the market moving?" | Done (3 starter indexes) |
| 7 | **Watchlist** with "since watched ±%" | The bridge from looking to deciding | Not started (Phase 3) |
| 8 | **Signals on your bottles** (12-month high, below what you paid) | Turns market data into a collection decision | Not started (Phase 3) |
| 9 | **Price alerts** on watched bottles | The strongest retention hook | Not started (Phase 4) |
| 10 | **Similar bottles** on the bottle page | Discovery | Not started (Phase 4) |

**Guardrails:**
- Copy describes prices ("11% under the market average"), never advice ("Buy"). The index page
  says the figures are not investment advice.
- Thin data is labelled, never hidden. Manual (Oak Spire–set) prices are excluded from movers
  and indexes.

---

## 2. Decisions

| Decision | Choice |
|---|---|
| First build scope | Phase 1 + Phase 2 |
| Guest browsing (no account) | **No**: sign-up stays first, and the auth flow is untouched |
| Home screen | **Folded into Collection**. Market is the landing tab. |
| Price index source | **Build our own**, don't fetch bourbon40.com (see below) |
| Which prices count as "market" | Active admin bottle, average ≥ $30, basis not `manual`, confidence not `low` / `stale`. **Legacy prices with no basis recorded are included**, because they are ~99% of the catalog. |

### Why not the Bourbon 40+ index (bourbon40.com)
- It updates **quarterly**, too slow for an app people open daily.
- It covers only 45 bottles, equal-weighted, from auction data.
- It offers no API and no data licence. Scraping means using someone else's methodology and
  brand without permission, and the site can change or block us at any time.
- **Optional later:** ask the founder (contact on the site) for permission to show it as an
  attributed external benchmark. An admin would enter it each quarter, beside our own index.

---

## 3. What is built

### Phase 1: app-only quick wins (no backend changes)

| Feature | Where |
|---|---|
| **Deal check** card on the bottle page | `lib/app/modules/market/widgets/benchmark_deal_check.dart` |

  - The user types an asking price; a marker shows it on the low–high bar, with a tick at the
    average.
  - Verdicts: *below the recent low* · *good* (≥5% under the average) · *fair* (within ±5%) ·
    *above average* · *above the recent high*.
  - It adds a "limited price data" caption when the price is thin or manual.
  - Logic: `lib/app/data/deal_check.dart` (pure, unit tested). State: `askingPrice` /
    `dealCheck` in `BenchmarkDetailController`.

| Feature | Where |
|---|---|
| **× retail** chip | `BottleDetails.retailMultiple` / `retailMultipleLabel`. Shown on `MarketBottleRow` and in the `BenchmarkTopSummary` tags. |
| **Range change** chip ("+11.0% 1Y"), falling back to "last move" | `BenchmarkDetailController.rangeChangePercent`, `BenchmarkTopSummary._MovementChip` |
| **Market-first navigation** | `bottom_nav_shell.dart` / `bottom_nav_controller.dart` |

  - The tabs are **Market (0) · Collection (1) · Settings popup (slot 2)**, with constants
    `BottomNavController.marketTab` / `collectionTab`.
  - Back returns to Market, then asks to exit. Analytics tab names are updated.

| Feature | Where |
|---|---|
| **Home folded into Collection** | `lib/app/modules/collection/widgets/collection_insights.dart` |

  - The value-vs-index chart, top moved and quick stats sit under the Collection value header,
    shown only when the collection is non-empty.
  - The Home views were deleted (`home_view`, `home_filled_view`, `home_loading_view`,
    `home_empty_view`, `home_value_header`).
  - `HomeController` and `modules/home/widgets/` still own that data and those widgets.
    `HomeController` also still feeds the header's "▲ $124 today" line.

| Feature | Where |
|---|---|
| "Prices updated …" caption on Market | `MarketController.lastUpdatedText`, which was loaded before but never shown |
| Thousands formatter moved to core | `lib/app/core/utils/thousands_number_input_formatter.dart` (shared by add-to-collection and the deal check) |

### Phase 2: market data (backend) + overview UI (app)

#### Backend (`../oakspireweb`)

**Schema:** `database/2026-10-05_market_stats_and_indexes.sql`. It is safe to re-run.

| Table | Purpose |
|---|---|
| `bluebook_market_stats` | Per eligible bottle: `change_30d`, `change_90d`, `change_365d`, `high_365d`, `low_365d`, rewritten nightly |
| `market_indexes` | Index definitions: `slug`, `name`, `description`, `rule_type` (`all` / `indexed` / `allocated` / `rare` / `category`) + `rule_value`, `base_date`, `base_value` (1000), `is_headline`, `sort_order`, `active` |
| `market_index_values` | One value per index per day, plus `constituents` |

The seeded indexes are **Oak Spire Index** (`market`, all eligible bottles, headline),
**Allocated** and **Rare**.

**Nightly commands**, chained after `priceUpdate` in `.docker/php/price-cron.sh`:

| Command | What it does |
|---|---|
| `php cli marketStats` | Rewrites `bluebook_market_stats`. The price N days ago is the latest history row on or before that day; NULL if there was none. Queries are batched per 1000 bottles, never per bottle. Clears the Redis `market#` cache. |
| `php cli marketIndexUpdate [--rebuild]` | Brings every active index up to today. The first run backfills from `base_date`. A re-run the same day recomputes today to the same value. |

**Index method** (`Models/MarketIndex.php`, `Commands/MarketIndexUpdate.php`):
- Equal-weighted and chain-linked.
- Each day: r = (sum of that day's returns) ÷ (bottles priced the day before), and
  value = previous value × (1 + r).
- A bottle's daily return is capped at ±50%.
- A new bottle joins the next day and never moves the index.

**Eligibility** is defined once, in `MarketStats::eligibleWhere`. Movers, sorts and every
index use it.

**Endpoints** are v1 routes, so `/v2/api/...` inherits them. Controller:
`Controllers/Api/Market.php`. Responses are cached in Redis under `market#` for an hour, and
both commands clear that prefix.

| Endpoint | Params | Returns |
|---|---|---|
| `market/overview` | `days` 30/90/365 (default 30) | Headline index summary (value, change 1d/30d/90d/365d, 90-day series), top 10 gainers and losers, `last_updated` |
| `market/indexes` | — | Every index with values, headline first |
| `market/index-detail` | `slug`, `days` 30/90/180/365 | Series, risers, fallers (members only), methodology text |

**Sort on `bluebook/get-all-bluebooks`** (`Models/BlueBook::getAdminBottles`):
- Values: `sort` = `name` (default), `price_desc`, `price_asc`, `gain_30d`, `loss_30d`,
  `premium`.
- The gain and loss sorts join the stats table and list only bottles that have a 30-day change.
  The other sorts skip the join, because joining 250k rows took the default list from 0.19s to
  0.83s.
- Every API row now carries a `market` object (`BlueBookHelper::withMarketStats`, one query per
  page).
- Admin callers pass no sort and keep the old query.

`changes.txt` has the full entry.

#### App

| Piece | Where |
|---|---|
| Models | `data/models/market_models.dart` (`MarketIndexSummary`, `MarketOverview`, `MarketIndexDetail`) and `data/models/bottle_market_stats.dart`. `BluebookModel.market` is parsed from each row. |
| Data | `data/datasources/market_remote_datasource.dart` and `data/repositories/market_repository.dart`: 1-hour `AppCache` of the raw maps. Registered in `AppBinding`. |
| Sort | `MarketSort` enum and `MarketController.setSort`. `PagedBottleSearch.sortParam` is passed to the repository and datasource. |
| Market tab | `MarketIndexStrip` (index cards), `MarketMovers` (top 5 rising / falling, with "See all" switching the list's sort), `MarketSortButton` (sheet). The overview and sort pill hide during a keyword search. |
| Rows | `MarketBottleRow` shows "+25.0% 30d" when the stats have it, else the last price move |
| Index detail | New route `/market-index` (`modules/market_index/`): level and change, line chart with 1M / 3M / 6M / 1Y, risers, fallers, "How this index works". Analytics key `market_index`. |

---

## 4. Verified

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 15 pass: deal-check bands, retail multiple, market payload parsing, existing suites |
| PHP lint (`php -l`) on every changed backend file | Clean |
| Migration + commands on the local DB (55,710 eligible bottles) | `marketStats` took 2–4s. `marketIndexUpdate` backfilled 278 days in 0.5s. A second run recomputes only today. |
| **Index maths** with two temporary history rows | Stats came out at +25% / −20% and the index at 1000 → 1025, exactly as calculated by hand. 55,708 bottles joining on 09-30 caused no jump. |
| Endpoints | Clean JSON with no stray PHP warnings. An unknown slug gives `NOT_OK "Index not found"`, and an invalid sort falls back to `name`. |
| Sort timings (local) | name 0.32s, price 0.16s, gain / loss 0.16s, premium 0.16s |
| Emulator (Android, local API) | Market tab, index card, movers, sort pill and index detail screen render with real data |

**Not yet checked on a device:**
- The Deal check.
- The Collection tab with insights.
- The two layout fixes made after the emulator session: the index range selector no longer
  stretches, and the "See all" spacing is tightened.

---

## 5. What remains

### Open items from Phase 1 + 2
- [ ] **Commit** both repos on `market-centric`, then open PRs.
- [ ] **Run the app through** the Deal check, Collection insights, sort sheet and index range
      selector on a device.
- [ ] **Collection chart:** it still compares against the old BSMI line from
      `collection/chart-data`. Switch it to the Oak Spire Index series. Server side,
      `Models\Collection::getIndexDataDashboard` should read `market_index_values`, falling back
      to BSMI. App side, rename the "BSMI" legend.
- [ ] **Production data check before publishing indexes:** look at the `price_basis` /
      `price_confidence` mix in production. If most prices are admin-set, either label the
      index an "Oak Spire price index" or wait until the ingest bot's sold data is live there.
- [ ] **Allocated / Rare / category indexes:** locally no bottle is flagged `is_allocated` or
      `is_rare`, so those indexes are empty and are skipped. Flag bottles, and add category
      indexes by inserting into `market_indexes` (example in the migration file), then run
      `marketIndexUpdate`.
- [ ] **MSRP data:** locally no bottle has `msrp`, so "× retail" and the premium sort show
      nothing. Fill MSRP (ingest bot / CSV; BAXUS import parses it but discards it).
- [ ] **Admin screen** for indexes. Today they're edited by SQL.
- [ ] **Performance:** `price_desc` / `premium` sort 258k rows without an index. They are fine
      locally, but watch them in production and consider an index on `bluebook.average`.
- [ ] **Naming tidy-up (optional):** `HomeController` and `modules/home/widgets/` now only
      serve the Collection tab. Rename them when convenient.

### Phase 3: watchlist and signals
- **Backend:**
  - Fix `Api\Favorite::all` to join bluebook with prices, `pricing` and `details`, plus the
    as-of price at `favorites.created_at` (`PriceSeriesHelper::valueOn`).
  - Drop its stray `RatingHelper::prepare` call.
- **App:**
  - `FavoritesRemoteDataSource` / `WatchlistRepository`.
  - A star toggle on the bottle page and on rows.
  - A Watchlist tab between Market and Collection, showing "since watched ±%" and sparklines.
  - A watchlist strip on Market.
- **Signals** on owned bottles: "at a 12-month high" (`high_365d`) and "now below what you
  paid" (`CollectionItemDisplay.gainPercent`).

### Phase 4: alerts and discovery
- **Price alerts:**
  - Add `target_price` / `alert_pct` on favorites.
  - A nightly comparison job.
  - A send-to-token method on `Models\Firebase` (kreait multicast, `user_fcm` tokens).
  - Today the backend only ever pushes to the `uncategorized` topic.
- **"Similar bottles"** on the bottle page, via the vector search in `ai-features-plan.md` §1.

### Subscriptions (parked by request)
Later: decide which market features are free and which are premium. For example, the indexes and
movers free; watchlist size, alerts and longer chart ranges premium.

---

## 6. Deploying

1. **Database first.** Run the migration, because the new list query and endpoints need the
   tables:
   ```bash
   mysql <db> < database/2026-10-05_market_stats_and_indexes.sql
   ```
2. **Deploy the backend:** `sh scripts/deploy.sh` once the branch is merged to `phase6`.
3. **Fill the tables once:**
   ```bash
   php cli marketStats && php cli marketIndexUpdate
   ```
   After that, `price-cron` runs both nightly after `priceUpdate`.
4. **Ship the app.** It handles a server without these endpoints: the overview and indexes just
   don't appear, and rows fall back to the last price move.

---

## 7. Local dev state to clean up

- **Containers** are running with `WEBSITE_URL=10.0.2.2` (for the emulator). To restore them:
  ```bash
  docker compose up -d php apache
  ```
- **Two temporary history rows** feed the local movers: bottles **1** and **9**, dated
  `2026-09-01`, in `bluebook_price_history`. Delete them, then:
  ```bash
  docker compose exec php php cli marketStats
  docker compose exec php php cli marketIndexUpdate --rebuild
  ```
- **A collection row** (`collections.id = 7`, user 109, bottle 257827, paid $20) was added from
  the emulator during testing. It wasn't created by the automated testing, so it was left as
  is.
