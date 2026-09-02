import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA-qi3Csnn3qbmothMVlQ4MMpYHw5VrTqs',
    appId: '1:889510277964:web:0d719c79311ee4ffe7d5e9',
    messagingSenderId: '889510277964',
    projectId: 'supernote-c5604',
    storageBucket: 'supernote-c5604.firebasestorage.app',
    authDomain: 'supernote-c5604.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-qi3Csnn3qbmothMVlQ4MMpYHw5VrTqs',
    appId: '1:889510277964:android:0d719c79311ee4ffe7d5e9',
    messagingSenderId: '889510277964',
    projectId: 'supernote-c5604',
    storageBucket: 'supernote-c5604.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-qi3Csnn3qbmothMVlQ4MMpYHw5VrTqs',
    appId: '1:889510277964:ios:0d719c79311ee4ffe7d5e9',
    messagingSenderId: '889510277964',
    projectId: 'supernote-c5604',
    storageBucket: 'supernote-c5604.firebasestorage.app',
    iosBundleId: 'com.example.superNote',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA-qi3Csnn3qbmothMVlQ4MMpYHw5VrTqs',
    appId: '1:889510277964:macos:0d719c79311ee4ffe7d5e9',
    messagingSenderId: '889510277964',
    projectId: 'supernote-c5604',
    storageBucket: 'supernote-c5604.firebasestorage.app',
    iosBundleId: 'com.example.superNote',
  );
}
