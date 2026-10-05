// PLACEHOLDER ONLY.
// Run `flutterfire configure` to replace this file with your real Firebase options.
// This placeholder allows the project to compile; it is not a working Firebase configuration.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'REPLACE_WITH_FIREBASE_API_KEY',
          appId: 'REPLACE_WITH_FIREBASE_APP_ID',
          messagingSenderId: 'REPLACE_WITH_SENDER_ID',
          projectId: 'REPLACE_WITH_PROJECT_ID',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'REPLACE_WITH_FIREBASE_API_KEY',
          appId: 'REPLACE_WITH_FIREBASE_APP_ID',
          messagingSenderId: 'REPLACE_WITH_SENDER_ID',
          projectId: 'REPLACE_WITH_PROJECT_ID',
          iosBundleId: 'com.whereweare',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }
}
