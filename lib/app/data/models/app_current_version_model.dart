/// The update rule from `config/all` → `current_version` (admin > Application
/// > Updater), per platform:
/// - a build below `*_min` must update (`/update-required`);
/// - a build below `*_latest` is offered it once per launch.
///
/// An older server sends only `android` / `ios` / `is_forced`: one build that
/// is the minimum when forced and the latest when not.
class AppCurrentVersion {
  const AppCurrentVersion({
    this.androidLatest,
    this.androidMin,
    this.iosLatest,
    this.iosMin,
    this.versionName,
    this.notes = const [],
  });

  final int? androidLatest;
  final int? androidMin;
  final int? iosLatest;
  final int? iosMin;

  /// As the store shows it ("1.8.0"), or null.
  final String? versionName;

  /// "What's new", one item per line.
  final List<String> notes;

  factory AppCurrentVersion.fromJson(Map<String, dynamic> json) {
    final legacyAndroid = _parseBuild(json['android']);
    final legacyIos = _parseBuild(json['ios']);
    final legacyForced = json['is_forced']?.toString() == '1';
    final hasSplit =
        json.containsKey('android_latest') || json.containsKey('ios_latest');

    final name = json['version_name']?.toString().trim();
    final rawNotes = json['notes'];
    final notes = rawNotes is List
        ? rawNotes.map((e) => e.toString())
        : (rawNotes?.toString() ?? '').split('\n');

    return AppCurrentVersion(
      androidLatest: hasSplit
          ? _parseBuild(json['android_latest'])
          : legacyAndroid,
      androidMin: hasSplit
          ? _parseBuild(json['android_min'])
          : (legacyForced ? legacyAndroid : null),
      iosLatest: hasSplit ? _parseBuild(json['ios_latest']) : legacyIos,
      iosMin: hasSplit
          ? _parseBuild(json['ios_min'])
          : (legacyForced ? legacyIos : null),
      versionName: name == null || name.isEmpty || name == 'null' ? null : name,
      notes: notes
          .map((s) => s.trim().replaceFirst(RegExp(r'^[-•*]\s*'), ''))
          .where((s) => s.isNotEmpty && s != 'null')
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'android_latest': androidLatest?.toString(),
    'android_min': androidMin?.toString(),
    'ios_latest': iosLatest?.toString(),
    'ios_min': iosMin?.toString(),
    'version_name': versionName,
    'notes': notes,
  };

  static int? _parseBuild(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    final n = int.tryParse(value);
    return n == null || n <= 0 ? null : n;
  }
}
