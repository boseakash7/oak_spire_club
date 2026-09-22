import 'package:flutter/services.dart';

/// Central haptic vocabulary so feedback stays consistent across the app.
///
/// Every call is fire-and-forget — a platform that does not support haptics
/// (or a device with them disabled) silently ignores the request, so call
/// sites never need to guard.
abstract final class AppHaptics {
  /// Tab switches, filter chips, range chips, radio / toggle rows.
  static void selection() => unawaitedHaptic(HapticFeedback.selectionClick);

  /// Primary buttons, FAB, card opens — anything that starts a real action.
  static void tap() => unawaitedHaptic(HapticFeedback.lightImpact);

  /// Confirmations that complete something (payment success, save, delete).
  static void confirm() => unawaitedHaptic(HapticFeedback.mediumImpact);

  /// Errors and rejected input (failed OTP, validation failure).
  static void error() => unawaitedHaptic(HapticFeedback.heavyImpact);

  static void unawaitedHaptic(Future<void> Function() action) {
    // Ignore platform failures; haptics are never load-bearing.
    action().catchError((_) {});
  }
}
