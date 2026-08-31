import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-qi3Csnn3qbmothMVlQ4MMpYHw5VrTqs',
    appId: '1:889510277964:android:0d719c79311ee4ffe7d5e9',
    messagingSenderId: '889510277964',
    projectId: 'supernote-c5604',
    storageBucket: 'supernote-c5604.firebasestorage.app',
  );
}
