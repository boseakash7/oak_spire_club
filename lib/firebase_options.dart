// Firebase options for Android (`google-services.json`) and iOS (`GoogleService-Info.plist`).
// Re-run `flutterfire configure` after adding platforms in the Firebase console.

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
        return ios;
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

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCSpCdjwqnY8HlIxOVk99DDGi9Dyq18sI8',
    appId: '1:1078950606869:ios:5ae6112900b6c689e5761c',
    messagingSenderId: '1078950606869',
    projectId: 'oakspireclub',
    storageBucket: 'oakspireclub.firebasestorage.app',
    iosBundleId: 'com.oak.spireclub',
  );
}
