# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

**Oak Spire Club** (`oakspire_club`) — a Flutter mobile app for bourbon/whiskey collectors.
Users track a bottle collection, see its market value over time charted against the BSMI
benchmark index, browse market categories, and pay for a subscription (Razorpay on
Android, Apple IAP on iOS).

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
flutter test                    # only test/widget_test.dart exists (route constants)
flutter run

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
    app.dart                 GetMaterialApp (dark-only theme, fade/slide transitions)
    app_binding.dart         global DI graph, registered once at startup
    core/                    cross-cutting: network, cache, storage, theme, firebase,
                             analytics, animations, shared widgets, utils
    data/                    models, datasources (HTTP), repositories (cache + shaping)
    modules/<feature>/       <feature>_binding.dart / _controller.dart / _view.dart
    routes/                  app_routes.dart, app_pages.dart, *_navigation.dart helpers
```

### Adding a screen

1. Add the path constant to `AppRoutes` ([app_routes.dart](lib/app/routes/app_routes.dart)).
2. Register a `GetPage` in `AppPages.pages` ([app_pages.dart](lib/app/routes/app_pages.dart)).
3. Create `modules/<feature>/` with a binding (`Get.lazyPut` the controller), a
   `GetxController`, and a `GetView<Controller>` view. Views that need no controller may
   skip the binding (see `settingsHelp`, `settingsAbout`).

### Adding an API call

1. Add the endpoint as a `static const String` in the relevant `*_remote_datasource.dart`,
   plus a method that calls `_client.postJson(...)` (form-encoded POST) or `_client.get(...)`
   followed by `_client.parseEnvelope(response)`.
2. Wrap it in a repository method, which owns caching and any client-side shaping.
3. Register the datasource + repository pair in `AppBinding` with `Get.lazyPut(..., fenix: true)`.

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
| `/taste-bottles` | `modules/taste` | home empty state, home chart footer, collection empty state |
| `/add-to-collection` | `modules/add_collection` | taste list, benchmark detail — both via `AddToCollectionLauncher` |
| `/benchmark-detail` | `modules/market` | market list tap, collection item detail sheet |
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
as a lazy `IndexedStack`: `HomeView` (0), `CollectionView` (1), `MarketView` (2). Settings opens
as `showSettingsPopup(context)` from the shell header, not as a tab or route.

**Route arguments are untyped maps.** Only the subscription routes have helper accessors
(`SubscriptionLimitNavigation`, `SubscriptionPaymentSuccessNavigation`). The rest read
`Get.arguments` directly: `/verify-otp` and `/reset-password` take `{email}`,
`/benchmark-detail` takes a flat bottle map (`id`, `name`, `image`, `average`, `low`, `high`,
`proof`, `description`, `rating`) built by `CollectionItemDisplay.benchmarkDetailArguments` or
inline in `market_view`, and `/add-to-collection` takes
`{prefill, editMode?, originalBottleId?, navigateToCollectionOnSuccess, popBenchmarkDetailOnSuccess}`.

**Add-to-collection returns `true` on success.** `taste_view` and the empty states `await
Get.toNamed(...)` and call `forceReload()` when the result is `true`; keep that contract when
adding a new entry point.

`modules/category_detail/` is not wired to a route or opened from anywhere — treat it as dead
code, not as the screen behind the Market category chips (those filter the bluebook list in place).

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
| `bluebook/get-all-bluebooks` | GET | `getAll` | market search + pagination, taste search |
| `bluebook/create` | POST | `create` | add-to-collection when the bottle is not in the bluebook |
| `bluebook/get-last-update` | GET | `getLastUpdatedReadable` | market "last updated" label |
| `bluebook-price-history/chart-data-dashboard` | GET | `getChartDashboard` | benchmark detail chart (`bottleId`, `fromDate`, `endDate`) |
| `categories/list` | POST + query | `list` | market category chips, taste category chips |
| `categories/detail` | GET | `detail` | `CategoryDetailController` only — unreachable, see screen map |
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
`categories:detail:$categoryId`, and `bluebook:last-updated`. `bluebook/get-all-bluebooks`,
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
`collection:all:$userId` and `collection:chart:$userId:`.

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
`needsSubscriptionOffer`, `resolvedPaymentGateway` (`razorpay` | `apple_in_app`).
`SubscriptionController` picks one of three `SubscriptionScreenMode`s from these.

**Bottom nav indices are not stable.** The Taste tab is commented out in
[bottom_nav_shell.dart](lib/app/modules/navigation/bottom_nav_shell.dart), so Benchmark is
index **2**, and the `headerTitle` switch in `BottomNavController` matches. Keep the shell,
the controller, and `AnalyticsScreens.shellTabScreenName` in sync when tabs change. Settings
is a popup, not a tab.

**Analytics.** Custom events only: `AppAnalyticsController.to.logScreenView(key)` emits
`{key}_view`, `logTap(key)` emits `{key}_click`, both through `sanitizeKey`. Always guard
with `Get.isRegistered<AppAnalyticsController>()` and `unawaited(...)`, matching existing
call sites.

**FCM topics** are all prefixed `oakspire_` and are documented in
[fcm_topics_summary.txt](fcm_topics_summary.txt) — registration state, subscription tier,
and per-preference alert topics. `FirebaseNotificationTopics` owns subscribe/unsubscribe;
the last-applied registration and tier topics are cached in `AppStorage` so switches are
idempotent.

**Theming is dark-only and hand-tuned to Figma.** Colors come from `AppColors`, text from
`AppTextStyles` (Playfair Display for headings, Roboto/Inter for body, via `google_fonts`).
Avoid raw `Color(0x...)` or `TextStyle` literals in views — add a named token instead.
Motion durations live in `AppMotion`.

**User messaging** goes through `AppSnackbar.error/success/info` (a custom overlay toast
with the app icon), not `Get.snackbar` or `ScaffoldMessenger`.

**Chart math** is shared, not per-screen: `ChartIndexComparison` rebases each series so the
first point in the window is 100 (so collection value and BSMI compare on one axis), and
`CollectionValueCalculator` is the single source of truth for invested value and the
"Moved +N%" figure.

## Testing

There is effectively no test suite — `test/widget_test.dart` only asserts route constants.
Do not assume tests cover a change; verify behavior by running the app.

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
| `bluebook/*` | `Api/BlueBook.php` (`getAdminBottles` is the paginated, category-filtered market list) |
| `bluebook-price-history/chart-data-dashboard` | `Api/BluebookPriceHistory.php` |
| `categories/list`, `categories/detail` | `Api/Category.php` |
| `package/*` | `Api/Package.php` |
| `usertoken/*` | `Api/UserToken.php` (`user_fcm` table) |
| `notification-preferences/update` | `Api/NotificationPreference.php` |

`config/all` is where `upload_url` (`Application/Uploads`), `pour_image_placeholder`,
`razorpay_key_id` / `razorpay_key_secret`, `current_version` (the forced-update payload) and the
terms/privacy URLs come from. Bottle images uploaded through `collection/add` are moved to
`Application/Uploads/<rand>_<time>.<ext>` and resolved client-side against `upload_url`.

Chart shaping is split across `Api/V2/Collection::chartData`,
`Application/Models/Collection` (`getChartData`, `getOverallPriceTrend`, `getIndexDataDashboard`,
`getCollectionValueByDate`, `getInvestedValue`) and
`Controllers/Helpers/CollectionHelper` (`fillDailyBothDirections` forward/backward-fills missing
days, `calculateIndexLevel` rebases a series to 100). The app's `ChartIndexComparison` rebases
again on top of that — if a chart looks doubly normalized, this is where to look. Several of these
model methods are called with more arguments than they declare (`getChartData(..., true)`,
`getInvestedValue($userId, $type)`); PHP ignores the extras, so those trailing arguments do nothing.

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
