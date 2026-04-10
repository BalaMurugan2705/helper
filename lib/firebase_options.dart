// TODO: Firebase Configuration
// ============================================================
// SETUP INSTRUCTIONS:
// 1. Create a Firebase project at https://console.firebase.google.com/
// 2. Enable Firestore Database (Native mode)
// 3. Install FlutterFire CLI:
//    dart pub global activate flutterfire_cli
// 4. Run in this project directory:
//    flutterfire configure
//    (Select your Firebase project and target platforms: android, web)
// 5. This file will be auto-generated with your real config.
// 6. Then run: flutter run -d chrome (for web) OR flutter run (for Android)
// ============================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_9sumzqAVup0nUQAK64fB5-2HVUvpoFU',
    appId: '1:860448358647:web:48b82d07ff78b631f093f2',
    messagingSenderId: '860448358647',
    projectId: 'bmr-helper',
    authDomain: 'bmr-helper.firebaseapp.com',
    storageBucket: 'bmr-helper.firebasestorage.app',
  );

  // TODO: Replace with your actual Firebase web config after running `flutterfire configure`

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBAEUgy6xXQ8b4NBtEYaH93D28DIENCP5M',
    appId: '1:860448358647:android:9f77f543ff92fe65f093f2',
    messagingSenderId: '860448358647',
    projectId: 'bmr-helper',
    storageBucket: 'bmr-helper.firebasestorage.app',
  );

  // TODO: Replace with your actual Firebase Android config after running `flutterfire configure`
}