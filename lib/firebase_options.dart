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
      print('>>> [FirebaseOptions] Loading Web configuration');
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        print('>>> [FirebaseOptions] Loading Android configuration');
        return android;
      case TargetPlatform.iOS:
        print('>>> [FirebaseOptions] Loading iOS configuration');
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios.',
        );
      case TargetPlatform.windows:
        print('>>> [FirebaseOptions] Loading Windows configuration');
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDbGQTgEvICou4j0NQsM1CjQNDLKL8IknI',
    appId: '1:932777946783:web:913f0f4bb91030d3313caa',
    messagingSenderId: '932777946783',
    projectId: 'flutter-firebase-2913c',
    authDomain: 'flutter-firebase-2913c.firebaseapp.com',
    storageBucket: 'flutter-firebase-2913c.firebasestorage.app',
    measurementId: 'G-853XTZS426',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBKGZ1Am3ngShgP0GrsdmnEqZdOUTIG4ig',
    appId: '1:932777946783:android:956d225f3990797b313caa',
    messagingSenderId: '932777946783',
    projectId: 'flutter-firebase-2913c',
    storageBucket: 'flutter-firebase-2913c.firebasestorage.app',
  );
}
