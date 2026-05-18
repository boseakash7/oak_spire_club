// Generated from `android/app/google-services.json` for package `com.oak.spireclub`.
// To add iOS / Web / desktop, register those apps in the Firebase console and run:
//   dart pub global activate flutterfire_cli
//   flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — '
        'add a web app in Firebase and run `flutterfire configure`.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS — '
          'add GoogleService-Info.plist and run `flutterfire configure`.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS — '
          'run `flutterfire configure`.',
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for desktop — '
          'run `flutterfire configure` if you need Firebase on this target.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC6qMLuAi2RGC9UxQjZhCqgMFodMzxQykA',
    appId: '1:1078950606869:android:4d336f8ce94fc789e5761c',
    messagingSenderId: '1078950606869',
    projectId: 'oakspireclub',
    storageBucket: 'oakspireclub.firebasestorage.app',
  );
}
