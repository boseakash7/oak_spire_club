/// One plan's limits from `package/limits`. Null means unlimited.
class PlanTierLimits {
  const PlanTierLimits({
    this.maxBottles,
    this.dailySearches,
    this.insightsLocked = false,
  });

  factory PlanTierLimits.fromJson(Object? json) {
    if (json is! Map) return const PlanTierLimits();
    return PlanTierLimits(
      maxBottles: _limit(json['max_bottles']),
      dailySearches: _limit(json['daily_searches']),
      insightsLocked: _flag(json['insights_locked']),
    );
  }

  /// Bottles in a collection.
  final int? maxBottles;

  /// Searches a day, counted and enforced by `bluebook/search`.
  final int? dailySearches;

  /// Price range, history and deal check are Premium. Locked in the app
  /// ([PlanAccessController.insightsLocked]): the bottle page and Market rows.
  final bool insightsLocked;

  /// A positive whole number, else null (unlimited). The server may send
  /// numbers, strings, `'null'` or 0.
  static int? _limit(Object? raw) {
    final n = int.tryParse(raw?.toString().trim() ?? '');
    return n != null && n > 0 ? n : null;
  }

  static bool _flag(Object? raw) {
    final s = raw?.toString().trim().toLowerCase();
    return s == 'true' || s == '1';
  }
}

/// The free and premium plans' limits, edited on admin > Plan limits.
class PlanLimits {
  const PlanLimits({required this.free, required this.premium});

  factory PlanLimits.fromJson(Map<String, dynamic> json) => PlanLimits(
    free: PlanTierLimits.fromJson(json['free']),
    premium: PlanTierLimits.fromJson(json['premium']),
  );

  /// What the subscription screen shows when the server has no
  /// `package/limits` yet or the call fails.
  static const fallback = PlanLimits(
    free: PlanTierLimits(dailySearches: 10, insightsLocked: true),
    premium: PlanTierLimits(),
  );

  final PlanTierLimits free;
  final PlanTierLimits premium;

  /// What each plan card lists: collection, bottle insights, searches. A
  /// limit both plans share is left out, so switching it off in the admin
  /// takes it off the screen.
  List<PlanComparisonRow> comparisonRows() => [
    if (free.maxBottles != premium.maxBottles)
      PlanComparisonRow(
        kind: PlanFeature.collection,
        free: _bottles(free.maxBottles),
        premium: _bottles(premium.maxBottles),
      ),
    if (free.insightsLocked != premium.insightsLocked)
      PlanComparisonRow(
        kind: PlanFeature.insights,
        free: free.insightsLocked ? 'Bottle insights' : _insights,
        premium: premium.insightsLocked ? 'Bottle insights' : _insights,
        freeLocked: free.insightsLocked,
        premiumLocked: premium.insightsLocked,
      ),
    if (free.dailySearches != premium.dailySearches)
      PlanComparisonRow(
        kind: PlanFeature.searches,
        free: _searches(free.dailySearches),
        premium: _searches(premium.dailySearches),
      ),
  ];

  static const _insights = 'Price range, history, deal check';

  static String _bottles(int? n) => n == null
      ? 'Unlimited bottles'
      : 'Up to $n ${n == 1 ? 'bottle' : 'bottles'}';

  static String _searches(int? n) =>
      n == null ? 'Unlimited searches' : '$n searches a day';
}

enum PlanFeature { collection, insights, searches }

/// One feature as each plan has it. A locked side shows a lock.
class PlanComparisonRow {
  const PlanComparisonRow({
    required this.kind,
    required this.free,
    required this.premium,
    this.freeLocked = false,
    this.premiumLocked = false,
  });

  final PlanFeature kind;
  final String free;
  final String premium;
  final bool freeLocked;
  final bool premiumLocked;
}
