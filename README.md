# Oak Spire Club (app)

Flutter app for bourbon and whiskey collectors: the Oak Spire market indexes and prices, a
collection valued against them, a wishlist, and a Premium subscription (Razorpay on Android,
Apple in-app purchase on iOS). Package `com.oak.spireclub`, Android and iOS only.

The API lives in the sibling repo `../oakspireweb`, documented in
[CLAUDE.md › Backend](CLAUDE.md#backend--oakspireweb).
[CLAUDE.md](CLAUDE.md) is the full guide to the code: architecture, screens, API and conventions.

## Running it

```sh
flutter pub get
flutter analyze
flutter test
flutter run                                                    # production API
flutter run --dart-define=API_BASE_URL=http://10.0.2.2/v2/api/  # local backend, Android emulator
```

For the local backend, start the oakspireweb Docker stack with the emulator's host
(`WEBSITE_URL=10.0.2.2 docker compose up -d php`), or every call is refused with
"You are not allowed to access from this domain". Start the emulator on the host GPU
(`emulator -avd Medium_Phone -gpu host`).

## Release builds

```sh
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

Signing reads `android/key.properties` (not in the repo). Keep `build/app/outputs/symbols`: it is
needed to read Crashlytics traces.

## Status: what's left (2026-10-11)

Branch `market-centric`. None of the work below is committed yet.

### Done in this round

- **Home:** a "Go Premium" card at the top for free-plan users. A new user gets a welcome card
  instead, with three steps and "Add your first bottle", plus a gold dot on the Collection tab,
  until the first bottle is added.
- **No subscription page after sign-up or sign-in.** Every signed-in user lands on Home.
- **Subscription checkout redesigned:**
  - Free and Premium plan cards built from the plan limits the admin sets.
  - A Monthly / Yearly switch, with Yearly as the default.
  - A renewal line under the button.
  - The fake countdown and the made-up "was" prices are gone.
- **Real, time-limited offers:**
  - The admin sets them per package. Anyone subscribing during the window keeps the offer price.
  - The checkout shows a live countdown to the real end, with the regular price crossed out.
- **Confirmation page** (`/subscription/confirm`) before payment: due today, trial end, first
  charge, what renews after, what's included, and the payment method.
- **Collection quick view:** an expand arrow on each bottle row.

### To finish

1. **One check left: the admin offer page in a browser.** It needs an admin login. Everything
   else was tested on the emulator against the local backend:
   - both migrations, which were also run twice to check they're safe to re-run;
   - the server's offer price check, including "offer ended";
   - the countdown, with the offer ending live on screen;
   - the plan cards, and the confirmation page with "Back to plans".

   "Confirm" wasn't pressed, because it would create a real Razorpay subscription.
2. **Roll out in this order:**
   1. Run `database/2026-10-11_plan_limits.sql` and `database/2026-10-11_package_offers.sql` on
      production.
   2. Deploy the PHP.
   3. Release the app.

   An older server still works with the new app: it falls back to default limits, no offers and a
   7-day trial.
3. **iPhone setup:**
   - Create an offer-priced product in App Store Connect for each offer, and enter its ID on the
     admin offer page. Without one, iPhone users see no offer.
   - Make the App Store free trial 7 days to match the server.
   - Restore purchases and App Store prices haven't been tested, because there's no iOS build
     machine here.
4. **Apple and the admin panel (decision needed).** The admin panel could manage the following
   through the App Store Connect and App Store Server APIs:
   - Apple prices and introductory offers, including the trial length.
   - Subscriber status, and free days added as a goodwill gesture.
   - Signed renewal and refund notifications. Today's Apple webhook doesn't verify the signature.

   It can't cancel or refund an Apple subscription. To be decided: either give every offer its own
   Apple product (locked in, like Razorpay), or use Apple introductory offers (first period only).
   This needs an App Store Connect API key, kept out of git.
5. **Limits that are shown but not enforced:** "10 searches a day" and "bottle insights hidden"
   for free users. Only the bottle cap is enforced, by the server. Enforcing the other two needs
   app and server work.
6. **Copy to fix:**
   - The sign-up screen and the "You are a Free user" screen still say "Join the club now and get
     50% off on life time subscription", which isn't a real offer.
   - Home's Premium card still lists "10,000+ bottles" and "No daily limits". It should read from
     the plan limits like the checkout.
7. **Smaller things:**
   - The subscription loading skeleton still draws the old stacked plan cards.
   - Home's market card shows "Prices updated 02.26.2025" while bottles were priced in October.
     Check `bluebook/get-last-update`.
   - Bottle images from `Application/Uploads` don't load against the local backend, because the
     files aren't in the local uploads folder.
8. **Local environment left behind by testing:**
   - The emulator app is signed into a throwaway local account.
   - The other project's `bourboneur-redis-stack-1` container is stopped, because it held port
     6379.
