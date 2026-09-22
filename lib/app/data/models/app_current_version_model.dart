/// Remote minimum build numbers from `config/all` → `current_version`.
class AppCurrentVersion {
  const AppCurrentVersion({
    this.android,
    this.ios,
    this.isForced = false,
  });

  final int? android;
  final int? ios;
  final bool isForced;

  factory AppCurrentVersion.fromJson(Map<String, dynamic> json) {
    return AppCurrentVersion(
      android: _parseBuild(json['android']),
      ios: _parseBuild(json['ios']),
      isForced: json['is_forced']?.toString() == '1',
    );
  }

  Map<String, dynamic> toJson() => {
    'android': android?.toString(),
    'ios': ios?.toString(),
    'is_forced': isForced ? '1' : '0',
  };

  static int? _parseBuild(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }
}
