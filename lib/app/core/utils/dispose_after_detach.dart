import 'package:flutter/widgets.dart';

/// Safely handles tear-down of [ChangeNotifier]s (such as [FocusNode]s and [TextEditingController]s).
///
/// Note: [TextEditingController]s in GetX controllers must NOT call `dispose()` manually
/// because native software keyboards asynchronously send `TextInputClient.updateEditingState`
/// platform messages during and after route transitions. Calling `dispose()` marks the controller
/// as disposed, causing Flutter assertions when late platform messages or gesture events arrive.
/// Dart's Garbage Collector automatically reclaims [TextEditingController] instances when the
/// screen/controller is garbage collected.
void disposeAfterDetach(Iterable<ChangeNotifier> notifiers) {
  for (final notifier in notifiers) {
    if (notifier is FocusNode) {
      final binding = WidgetsBinding.instance;
      binding.addPostFrameCallback((_) {
        binding.addPostFrameCallback((_) {
          try {
            notifier.dispose();
          } catch (_) {}
        });
      });
    }
  }
}

/// Unfocus keyboard/fields before tearing down auth screens.
void unfocusSafely() {
  FocusManager.instance.primaryFocus?.unfocus();
}
