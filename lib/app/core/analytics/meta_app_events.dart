import 'dart:async';

import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/user_model.dart';

/// Meta (Facebook) App Events: the standard events Meta's ads optimise on.
///
/// The SDK reads its app id and client token from native config
/// (`android/app/src/main/res/values/strings.xml`, `ios/Runner/Info.plist`)
/// and logs app installs and opens (`fb_mobile_activate_app`) by itself.
/// Everything here is a standard event with Meta's own parameter names, so
/// Events Manager recognises it without custom conversions.
///
/// Every call is fire-and-forget and never throws: a missing or broken SDK
/// costs only the event.
abstract final class MetaAppEvents {
  static final FacebookAppEvents _sdk = FacebookAppEvents();

  /// Prices in the app are US dollars (bluebook averages, Razorpay plans).
  static const String usd = 'USD';

  // Meta standard event names (AppEventsConstants / FBSDKAppEventName).
  static const _completedRegistration = 'fb_mobile_complete_registration';
  static const _viewedContent = 'fb_mobile_content_view';
  static const _searched = 'fb_mobile_search';
  static const _addedToWishlist = 'fb_mobile_add_to_wishlist';
  static const _initiatedCheckout = 'fb_mobile_initiated_checkout';
  static const _startTrial = 'StartTrial';
  static const _subscribe = 'Subscribe';

  // Meta standard parameter names.
  static const _registrationMethod = 'fb_registration_method';
  static const _contentType = 'fb_content_type';
  static const _contentId = 'fb_content_id';
  static const _currency = 'fb_currency';
  static const _searchString = 'fb_search_string';
  static const _success = 'fb_success';
  static const _numItems = 'fb_num_items';
  static const _paymentInfoAvailable = 'fb_payment_info_available';
  static const _orderId = 'fb_order_id';

  static const _yes = '1';
  static const _no = '0';

  /// A bottle, in Meta's catalog terms.
  static const _product = 'product';

  /// A Premium plan.
  static const _subscription = 'subscription';

  // --- Identity -------------------------------------------------------------

  /// Ties events to the signed-in user: the app's user id, plus the email
  /// and first name for Meta's advanced matching (the SDK hashes them with
  /// SHA-256 before they leave the device). Null clears both, on sign-out.
  static void identify(UserModel? user) {
    if (user == null || user.id.trim().isEmpty) {
      _run('clearUser', () async {
        await _sdk.clearUserID();
        await _sdk.clearUserData();
      });
      return;
    }
    final email = user.email?.trim();
    final name = user.name?.trim();
    final firstName = (name == null || name.isEmpty)
        ? null
        : name.split(RegExp(r'\s+')).first;
    _run('identify', () async {
      await _sdk.setUserID(user.id.trim());
      await _sdk.setUserData(
        email: (email == null || email.isEmpty) ? null : email.toLowerCase(),
        firstName: firstName?.toLowerCase(),
      );
    });
  }

  // --- Standard events ------------------------------------------------------

  /// A new account was created (sign-up succeeded).
  static void completedRegistration({String method = 'email'}) {
    _log(_completedRegistration, {_registrationMethod: method});
  }

  /// A bottle's page was opened.
  static void viewedContent({required String bottleId, double? price}) {
    _log(
      _viewedContent,
      {_contentType: _product, _contentId: bottleId, _currency: usd},
      valueToSum: price,
    );
  }

  /// A keyword search returned its first page.
  static void searched({required String query, required bool found}) {
    _log(_searched, {
      _contentType: _product,
      _searchString: query,
      _success: found ? _yes : _no,
    });
  }

  /// A bottle went onto the wishlist (not an edit of its target).
  static void addedToWishlist({required String bottleId, double? price}) {
    _log(
      _addedToWishlist,
      {_contentType: _product, _contentId: bottleId, _currency: usd},
      valueToSum: price,
    );
  }

  /// The user reviewed a plan and confirmed, so the payment sheet opens.
  static void initiatedCheckout({
    required String planId,
    double? price,
    String currency = usd,
    bool paymentInfoAvailable = false,
  }) {
    _log(
      _initiatedCheckout,
      {
        _contentType: _subscription,
        _contentId: planId,
        _numItems: 1,
        _currency: currency,
        _paymentInfoAvailable: paymentInfoAvailable ? _yes : _no,
      },
      valueToSum: price,
    );
  }

  /// A subscription was confirmed. A plan that began with free days is a
  /// `StartTrial`, otherwise a `Subscribe`; [price] is what the plan charges.
  static void subscribed({
    required bool trial,
    required String orderId,
    double? price,
    String currency = usd,
  }) {
    _log(
      trial ? _startTrial : _subscribe,
      {_orderId: orderId, _currency: currency},
      valueToSum: price,
    );
  }

  // --- Plumbing -------------------------------------------------------------

  static void _log(
    String name,
    Map<String, Object> parameters, {
    double? valueToSum,
  }) {
    _run(name, () {
      if (kDebugMode) {
        debugPrint('[MetaAppEvents] → $name  $parameters  value=$valueToSum');
      }
      return _sdk.logEvent(
        name: name,
        parameters: parameters,
        valueToSum: valueToSum,
      );
    });
  }

  static void _run(String what, Future<void> Function() call) {
    unawaited(
      Future<void>(call).catchError((Object e) {
        debugPrint('[MetaAppEvents] $what failed: $e');
      }),
    );
  }
}
