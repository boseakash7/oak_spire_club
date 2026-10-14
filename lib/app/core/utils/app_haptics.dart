import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

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

  /// Whether the phone can play a shaped vibration (a pattern with its own
  /// strengths): Android's vibrator, iOS Core Haptics. False until
  /// [probeRumble] has answered, and wherever it can't.
  static bool get canRumble => _canRumble;
  static bool _canRumble = false;
  static Future<void>? _probe;

  /// Asks once whether [rumble] can play; call it before the first use.
  static Future<void> probeRumble() => _probe ??= () async {
    try {
      // Not hasVibrator(): the plugin says false on every emulator, and on
      // Android the vibrate call itself checks for a vibrator. On iOS this is
      // Core Haptics support.
      _canRumble = await Vibration.hasCustomVibrationsSupport();
    } catch (_) {
      _canRumble = false;
    }
  }();

  /// Plays [pattern] (milliseconds, alternating wait and buzz, starting with a
  /// wait) at [intensities] (1-255, 0 for a wait). Replaces any rumble already
  /// playing. Does nothing unless [canRumble].
  static void rumble(List<int> pattern, List<int> intensities) {
    if (!_canRumble) return;
    Vibration.vibrate(
      pattern: pattern,
      intensities: intensities,
    ).catchError((_) {});
  }

  /// Stops a [rumble] that is still playing.
  static void stopRumble() {
    if (!_canRumble) return;
    Vibration.cancel().catchError((_) {});
  }

  static void unawaitedHaptic(Future<void> Function() action) {
    // Ignore platform failures; haptics are never load-bearing.
    action().catchError((_) {});
  }
}
