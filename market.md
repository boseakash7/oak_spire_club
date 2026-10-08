# Oak Spire: market-centric app

Status as of **2026-10-08**. This is the working document for turning Oak Spire from a
collection tracker into a market app. It covers the goal, the decisions made, what is built,
what was verified, and what remains. The original approved plan is
[docs/market-centric-plan.md](docs/market-centric-plan.md). This file supersedes it where they
differ. [CLAUDE.md](CLAUDE.md) describes each screen in detail; this file tracks the plan.

Branches: `market-centric` in both `oak_spire_club` (app) and `../oakspireweb` (backend).
Everything below is committed on those branches. No PR is open yet, and nothing is merged to
`main` (app) or `phase6` (backend).

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
| 2 | **× retail chip** (market price ÷ MSRP) | Bourbon hunters think in secondary premium | Done (no MSRP data yet) |
| 3 | **Change over the chosen range** on the bottle page | "Last change %" alone can be months old | Done |
| 4 | **Market overview**: Oak Spire Index, breadth, biggest movers | A reason to open the app daily without owning anything | Done (on Home) |
| 5 | **Sort** the market list (price, 30-day rise or fall, premium) | Browsing 250k bottles alphabetically has no value | Done |
| 6 | **Oak Spire indexes**: our own, several of them | "Where is the market moving?" | Done (3 starter indexes) |
| 7 | **Community lists**: hot with collectors, most collected, top rated, new to the market | Shows what other collectors do, not only prices | Done |
| 8 | **Collection vs the market**: value, gain vs paid, scoreboard against the index, portfolio mix | Puts the user's bottles in market terms | Done |
| 9 | **Wishlist** with "since added ±%" and a target price | The bridge from looking to deciding | Done (10-08) |
| 10 | **Signals on your bottles** (12-month high, below what you paid) | Turns market data into a collection decision | Partly: "Losing" / "Gaining" / "Doubled" quick stats |
| 11 | **Price alerts** on wishlist bottles | The strongest retention hook | Not started (Phase 4) |
| 12 | **Similar bottles** on the bottle page | Discovery | Not started (Phase 4) |

**Guardrails:**
- Copy describes prices ("11% under the market average"), never advice ("Buy"). The index page
  says the figures are not investment advice.
- Thin data is labelled, never hidden. Manual (Oak Spire–set) prices are excluded from movers
  and indexes.

---

## 2. Decisions

| Decision | Choice |
|---|---|
| First build scope | Phase 1 + Phase 2, then the Home and Collection rework |
| Guest browsing (no account) | **No**: sign-up stays first, and the auth flow is untouched |
| Landing screen | **Home, rebuilt as a market summary** (changed on 10-06). Home was first folded into Collection with Market as the landing tab; it came back as a one-scroll market page with the user's collection in it. |
| Tabs | **Home (0) · Market (1) · Collection (2)**, Settings as a popup in slot 3 |
| Price index source | **Build our own**, don't fetch bourbon40.com (see below) |
| Which prices count as "market" | Active admin bottle, average ≥ $30, basis not `manual`, confidence not `low` / `stale`. **Legacy prices with no basis recorded are included**, because they are ~99% of the catalog. |
| Movement window on Home | **90 days**, falling back to 30 when the price history is too young for a 90-day figure |
| Collection chart benchmark | The headline **Oak Spire Index**, not the old BSMI line |
| Push notifications | **Topic-based**, from the admin panel, by audience × alert category (10-08) |
| Wishlist storage | **A new `wishlist` table**; the old `favorites` API and the collection's `wishlist` type are removed (10-08) |
| Wishlist placement | **An Owned · Wishlist switch on the Collection tab**, plus a Home section. No fifth tab. |

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
| **Deal check** card on the bottle page | `market/widgets/benchmark_deal_check.dart`, logic in `data/deal_check.dart` (pure, unit tested) |

  - The user types an asking price; a marker shows it on the low–high bar, with a tick at the
    average.
  - Verdicts: *below the recent low* · *good* (≥5% under the average) · *fair* (within ±5%) ·
    *above average* · *above the recent high*.
  - It adds a "limited price data" caption when the price is thin or manual.

| Feature | Where |
|---|---|
| **× retail** chip | `BottleDetails.retailMultiple` / `retailMultipleLabel`, on `MarketBottleRow` and in the `BenchmarkTopSummary` tags |
| **Range change** chip ("+11.0% 1Y"), falling back to "last move" | `BenchmarkDetailController.rangeChangePercent` |
| "Prices updated …" caption on Market | `MarketController.lastUpdatedText` |
| Thousands formatter moved to core | `core/utils/thousands_number_input_formatter.dart` |

### Phase 2: market data (backend) + Market tab (app)

#### Backend (`../oakspireweb`)

**Schema:** `database/2026-10-05_market_stats_and_indexes.sql` (safe to re-run).

| Table | Purpose |
|---|---|
| `bluebook_market_stats` | Per eligible bottle: `change_30d`, `change_90d`, `change_365d`, `high_365d`, `low_365d`, `first_priced_on`, rewritten nightly |
| `market_indexes` | Index definitions: `slug`, `name`, `description`, `rule_type` (`all` / `indexed` / `allocated` / `rare` / `category`) + `rule_value`, `base_date`, `base_value` (1000), `is_headline`, `sort_order`, `active` |
| `market_index_values` | One value per index per day, plus `constituents` |

The seeded indexes are **Oak Spire Index** (`market`, all eligible bottles, headline),
**Allocated** and **Rare**.

**Nightly commands**, chained after `priceUpdate` in `.docker/php/price-cron.sh`:

| Command | What it does |
|---|---|
| `php cli marketStats` | Rewrites `bluebook_market_stats`. The price N days ago is the latest history row on or before that day; NULL if there was none. Batched per 1000 bottles. Clears the Redis `market#` cache. |
| `php cli marketIndexUpdate [--rebuild]` | Brings every active index up to today. The first run backfills from `base_date`. |

**Index method** (`Models/MarketIndex.php`): equal-weighted and chain-linked. Each day,
r = (sum of that day's returns) ÷ (bottles priced the day before), value = previous × (1 + r).
A daily return is capped at ±50%, and a new bottle never moves the index.

**Endpoints** (`Controllers/Api/Market.php`, cached in Redis under `market#` for an hour):

| Endpoint | Params | Returns |
|---|---|---|
| `market/overview` | `days` 30/90/365 | Headline index summary, top 10 gainers and losers, `last_updated` |
| `market/indexes` | — | Every index with values, headline first |
| `market/index-detail` | `slug`, `days` 30/90/180/365 | Series, risers, fallers, methodology text |
| `market/highlights` | `days` 30/90/365 (breadth window) | Breadth (rising / falling), hot with collectors, most collected, top rated in collections, new to the market |

**Sort on `bluebook/get-all-bluebooks`:** `name` (default), `price_desc`, `price_asc`,
`gain_30d`, `loss_30d`, `premium`. Every row carries a `market` object.

**Sparklines:** `bluebook/sparklines` (`ids` ≤ 60, `days`), 24 evenly spaced as-of prices per
bottle, cached 3 hours.

#### App

| Piece | Where |
|---|---|
| Models / data | `market_models.dart`, `bottle_market_stats.dart`, `MarketRepository` (1-hour `AppCache`) |
| Market tab | `MarketIndexStrip`, search, category chips, "Prices updated", `MarketSortButton`, the paged list. Rows show the 30-day change and a 90-day sparkline. |
| Index detail | `/market-index`: level and change, 1M / 3M / 6M / 1Y chart, risers, fallers, "How this index works" |

### Phase 2.5: Home and Collection rework (10-06 to 10-08)

**Home** (`modules/dashboard`), one vertical scroll, each section hidden when empty:
1. **The market**: the headline index card with breadth (rising / falling over 90 days).
2. **Your collection**: today's value, gain vs paid, the move line, a value sparkline, bottle /
   sealed / opened / rare counts, and the range's move beside the index's. An "Add your first
   bottle" CTA when empty.
3. **Your bottles on the move**: the 3 collection bottles whose 90-day line moved most.
4. **Biggest movers**: Rising / Falling toggle, 5 each, "See all" to the index page.
5. **Hot with collectors**, **Most collected**, **Top rated in collections**, **New to the market**.

**Collection tab**, top to bottom:
1. **Quick stats**: 8 tiles (collection, drunk, rating, rare, duplicates, doubled, gaining,
   losing). **Each tile opens All bottles filtered to what it counts.**
2. **Collection value**: today's value, invested, gain vs paid.
3. **Portfolio mix**: Type / Brand share of today's value (`PortfolioBreakdown`).
4. **You vs the market**: 1M / 3M / 6M / 1Y scoreboard against the Oak Spire Index, with the
   "Ahead of / Behind the market by N pts" chip and the chart.
5. **Top priced bottles** (5), then "View all bottles (N)".

**All bottles** (`/collection/bottles`): sort menu, a chip bar of the quick-stat filters (All,
Drunk, Rated, Rare, Duplicates, Doubled, Gaining, Losing), and the full list. The tile that
opened it starts selected.

**Wishlist (10-08)**

Bottles you want, with the price they had when you added them and an optional target price.
- **Backend:**
  - New `wishlist` table (`database/2026-10-08_wishlist.sql`), one row per user + bottle, with
    `added_price`, `target_price` and `note`.
  - `Api\Wishlist`: `wishlist/all`, `wishlist/save`, `wishlist/remove`.
  - Removed: the `favorites` API and the collection's `wishlist` type. The migration copies any old
    wishlist-type collection rows across; the `favorites` table is kept.
  - The ingest merge repoints `wishlist.bluebook_id` when two bottles are merged.
- **App** (`modules/wishlist/`, one shared `WishlistController`):
  - Adding: a bookmark on every market row (one tap), a **Want / Wanted** pill on the bottle page
    (opens a sheet with the target, quick chips and a note), and "Set $X as my wishlist target" in
    the Deal check.
  - **Collection tab:** an **Owned · Wishlist** switch. Wishlist shows what the list costs today,
    its move since added, how many bottles are at or near their target, All / At target / Falling /
    Rising chips, and the rows. A row opens View bottle / **I bought it** / Edit target / Remove.
  - **I bought it** opens add-to-collection with the target as the price paid, then takes the bottle
    off the wishlist and shows Owned.
  - **Home:** a "Your wishlist" section, bottles at target first.

**Push notifications (10-08)**
- The admin panel's sender went to the FCM topic `uncategorized`, which the app never subscribed
  to, so no device received anything.
- It now sends by **audience** (everyone, members, premium, paid, free premium, members without
  premium, new sign-ups, guests, signed-out) × **topic** (the app's four alert toggles, or
  "Account notice"). Both go into one FCM condition, so each device gets it once and only if the
  user left that toggle on.
- Admins can send now or schedule, cancel a scheduled send, and see sent / failed with the error.
- A tap opens the chosen screen (`NotificationTapRouter`).
- Migration: `database/2026-10-08_notification_topics.sql`.

---

## 4. Verified

| Check | Result |
|---|---|
| `flutter analyze` | No issues (10-08) |
| `flutter test` | 31 pass: deal check, retail multiple, market payloads, collection value, portfolio breakdown, chart index alignment, quick-stat filters agree with their tile counts, wishlist figures and filters |
| PHP lint (`php -l`, PHP 7.4 in `lampp:php`) on every changed backend file | Clean |
| Market migration + commands on the local DB (55,710 eligible bottles) | `marketStats` 2–4s, `marketIndexUpdate` backfilled 278 days in 0.5s |
| Index maths with two temporary history rows | +25% / −20% and 1000 → 1025, as calculated by hand |
| Endpoints | Clean JSON; an unknown slug gives `NOT_OK "Index not found"`; an invalid sort falls back to `name` |
| Wishlist API on the local stack | Add, update, list and remove work; a bad target and an unknown bottle are refused; `favorite/*` now 404s and `collection/add type=wishlist` is refused. The migration ran twice cleanly. |
| Wishlist on the emulator (10-08) | Home section, Collection's Wishlist view, row actions, editing the target, the market bookmark, Want / Wanted on the bottle page, the Deal check target link, and I bought it (which first returned no result; fixed and re-run) |
| Notification conditions | All 45 audience × topic pairs checked: each ≤ 5 topics, signed-out + an alert topic is refused, and the kreait message builds |
| Notification migration on the local DB | Ran twice cleanly; it turned the local `status` enum (`sent`, `pending`) into a varchar so the new states fit |
| Emulator (Android, local API), 10-05 | Market tab, index card, movers, sort pill and index detail rendered with real data |

**Not yet checked on a device:** the Deal check, the new Home, the Collection rework and its
quick-stat filters, the admin notification pages, a real push and its tap. A real send was not
tried: the local Firebase credentials are live, so it would reach real phones.

---

## 5. What remains

### Open items
- [ ] **PRs**: open `market-centric` → `main` (app) and → `phase6` (backend).
- [ ] **Run the app through** everything in "Not yet checked on a device" above.
- [ ] **Send a test push** to a test device (e.g. "New sign-ups" right after signing up on it)
      before using the panel for real.
- [ ] **Server cron:** `php cli firebaseMessage` every minute, or scheduled notifications never
      go out.
- [ ] **Production data check before publishing indexes:** look at the `price_basis` /
      `price_confidence` mix. If most prices are admin-set, label the index an "Oak Spire price
      index" or wait for the ingest bot's sold data.
- [ ] **Allocated / Rare / category indexes:** no bottle is flagged `is_allocated` or `is_rare`
      locally, so those indexes are empty. Flag bottles, add category indexes in
      `market_indexes`, run `marketIndexUpdate`.
- [ ] **MSRP data:** no bottle has `msrp` locally, so "× retail" and the premium sort show
      nothing.
- [ ] **Community lists** need ≥ 3 collectors per bottle (≥ 2 recent adders for "hot"), so they
      stay hidden until there are enough users.
- [ ] **Admin screen** for indexes (today they're edited by SQL).
- [ ] **Performance:** `price_desc` / `premium` sort 258k rows without an index; watch them in
      production, consider an index on `bluebook.average`.
- [ ] **Naming tidy-up (optional):** `HomeController` and `modules/home/widgets/` now serve the
      Collection tab and Home's collection card. Rename them when convenient.

### Phase 3: signals
- **Signals** on owned bottles beyond the quick stats: "at a 12-month high" (`high_365d`) on a
  collection row, "now below what you paid" as a Home line.
- **Wishlist follow-up:** a free-plan cap on wishlist size, once subscriptions are revisited.

### Phase 4: alerts and discovery
- **Price alerts** on wishlist targets: a nightly comparison job and a send-to-token method on
  `Models\Firebase` (kreait multicast to `user_fcm` tokens). Topic sending is done; per-user
  sending is not.
- **"Similar bottles"** on the bottle page, via the vector search in `ai-features-plan.md` §1.

### Subscriptions (parked by request)
Later: decide which market features are free and which are premium. For example, the indexes and
movers free; wishlist size, alerts and longer chart ranges premium.

---

## 6. Deploying

1. **Database first** (each is safe to re-run except where noted):
   ```bash
   mysql <db> < database/2026-10-05_market_stats_and_indexes.sql
   mysql <db> < database/2026-10-06_market_highlights.sql      # not re-runnable
   mysql <db> < database/2026-10-08_notification_topics.sql
   mysql <db> < database/2026-10-08_wishlist.sql
   ```
2. **Deploy the backend:** `sh scripts/deploy.sh` once the branch is merged to `phase6`.
3. **Fill the tables once:**
   ```bash
   php cli marketStats && php cli marketIndexUpdate
   ```
   After that, `price-cron` runs both nightly after `priceUpdate`.
4. **Add the notification cron** on the server: `* * * * * php cli firebaseMessage`.
5. **Ship the app.** It handles a server without the market endpoints: the overview and indexes
   just don't appear, and rows fall back to the last price move.

---

## 7. Local dev state to clean up

- **Docker Desktop** was started on 10-08 to lint PHP and test the migrations; the stack was
  stopped again afterwards. The local database has the new `notifications` columns and the
  `wishlist` table (empty: the test rows were deleted).
- **php and apache were recreated with `WEBSITE_URL=10.0.2.2`** for the emulator (restore below).
- Recorded on 10-05 and not re-checked since:
  - **Containers** ran with `WEBSITE_URL=10.0.2.2` (for the emulator). To restore them:
    ```bash
    docker compose up -d php apache
    ```
  - **Two temporary history rows** feed the local movers: bottles **1** and **9**, dated
    `2026-09-01`, in `bluebook_price_history`. Delete them, then:
    ```bash
    docker compose exec php php cli marketStats
    docker compose exec php php cli marketIndexUpdate --rebuild
    ```
  - **A collection row** (`collections.id = 7`, user 109, bottle 257827, paid $20) was added
    from the emulator during testing and left as is.
