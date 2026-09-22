/// Hero tags shared between a list row and the detail screen it opens.
///
/// Both ends must build the same string, so they live here rather than being
/// spelled out at each call site.
abstract final class AppHeroTags {
  /// Bottle art flying from a market / collection row into its detail screen.
  ///
  /// Returns null when the row has no stable id — a Hero without a unique tag
  /// throws if two of them are on screen at once, so the caller skips the
  /// animation instead.
  static String? bottleImage(String? bottleId) {
    final id = bottleId?.trim();
    if (id == null || id.isEmpty || id == 'null') return null;
    return 'bottle-image-$id';
  }
}
