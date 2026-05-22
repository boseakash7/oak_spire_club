/// Time-of-day greetings for headers and profile UI.
abstract final class GreetingFormatter {
  GreetingFormatter._();

  /// Returns "Good morning", "Good afternoon", "Good evening", or "Good night".
  static String timeOfDayLabel([DateTime? at]) {
    final hour = (at ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  /// First word of [fullName], or [fallback] when empty.
  static String firstNameFrom(String? fullName, {String fallback = 'there'}) {
    final trimmed = fullName?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  /// e.g. "Good afternoon, Alex"
  static String personalized(
    String? fullName, {
    String fallback = 'there',
    DateTime? at,
  }) {
    final name = firstNameFrom(fullName, fallback: fallback);
    return '${timeOfDayLabel(at)}, $name';
  }
}
