// lib/config/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // REPLACE THESE WITH YOUR ACTUAL VALUES FROM FIREBASE CONSOLE
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDEvDjT7YVjJ3OviBeIByqbaxrf7RwfccE',
    appId: '1:123456789:android:abc123def456',
    messagingSenderId: '123456789',
    projectId: 'vocifer-12345',
    storageBucket: 'vocifer-12345.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDEvDjT7YVjJ3OviBeIByqbaxrf7RwfccE',
    appId: '1:123456789:ios:abc123def456',
    messagingSenderId: '123456789',
    projectId: 'vocifer-12345',
    storageBucket: 'vocifer-12345.appspot.com',
    iosBundleId: 'com.example.vocifer',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDEvDjT7YVjJ3OviBeIByqbaxrf7RwfccE',
    appId: '1:123456789:web:abc123def456',
    messagingSenderId: '123456789',
    projectId: 'vocifer-12345',
    storageBucket: 'vocifer-12345.appspot.com',
  );
}

// ========================================
// HOW TO GET YOUR FIREBASE CONFIG VALUES:
// ========================================
//
// 1. Go to: https://console.firebase.google.com/
// 2. Select your project (or create new one)
// 3. Click gear icon → "Project Settings"
// 4. Scroll to "Your apps" section
// 5. Click on your platform (Android/iOS/Web)
// 6. Copy these values:
//    - apiKey
//    - appId
//    - messagingSenderId
//    - projectId
//    - storageBucket
//
// 7. Paste them above, replacing the placeholder values