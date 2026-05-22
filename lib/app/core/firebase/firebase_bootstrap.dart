import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:oakspire_club/firebase_options.dart';

import '../analytics/app_analytics_nav_observer.dart';
import 'firebase_push_notifications.dart';

/// Initializes Firebase Core, Analytics, Crashlytics, and Performance (Performance starts with Core).
Future<void> bootstrapFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebasePushNotifications.initialize();

  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // Performance Monitoring collects automatically after initialization; no Dart API required for defaults.

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    kReleaseMode,
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Custom route observer; screen events use `{screen}_view` via [AppAnalyticsController].
List<NavigatorObserver> firebaseAnalyticsNavObservers() => [
      AppAnalyticsNavObserver(),
    ];
