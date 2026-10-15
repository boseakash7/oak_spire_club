import 'package:flutter_test/flutter_test.dart';
import 'package:oakspire_club/app/data/models/app_current_version_model.dart';

void main() {
  group('AppCurrentVersion', () {
    test('split rule: latest, minimum, name and notes', () {
      final v = AppCurrentVersion.fromJson({
        'android_latest': 42,
        'android_min': '38',
        'ios_latest': '40',
        'ios_min': 0,
        'version_name': '1.8.0',
        'notes': '- Remove a single bottle\n\n• Faster search\nnull',
        // Legacy keys are ignored once the split ones are there.
        'android': '38',
        'is_forced': 1,
      });
      expect(v.androidLatest, 42);
      expect(v.androidMin, 38);
      expect(v.iosLatest, 40);
      expect(v.iosMin, isNull);
      expect(v.versionName, '1.8.0');
      expect(v.notes, ['Remove a single bottle', 'Faster search']);
    });

    test('legacy forced rule is a minimum', () {
      final v = AppCurrentVersion.fromJson({
        'android': '30',
        'ios': '28',
        'is_forced': '1',
      });
      expect(v.androidMin, 30);
      expect(v.androidLatest, 30);
      expect(v.iosMin, 28);
    });

    test('legacy optional rule is only a latest', () {
      final v = AppCurrentVersion.fromJson({'android': '30', 'is_forced': 0});
      expect(v.androidLatest, 30);
      expect(v.androidMin, isNull);
    });

    test('survives a round trip through storage', () {
      final v = AppCurrentVersion.fromJson(
        AppCurrentVersion.fromJson({
          'android_latest': 42,
          'android_min': 38,
          'notes': 'One\nTwo',
          'version_name': '1.8.0',
        }).toJson(),
      );
      expect(v.androidLatest, 42);
      expect(v.androidMin, 38);
      expect(v.notes, ['One', 'Two']);
      expect(v.versionName, '1.8.0');
    });
  });
}
