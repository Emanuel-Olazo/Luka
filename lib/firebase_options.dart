import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDNu17DHgPyAJ5BxtEt_gPxsiLzrAWWoTM',
    appId: '1:876833650784:android:5fe8fc8420b5d2af166b05',
    messagingSenderId: '876833650784',
    projectId: 'luka-finanzas-3d8b9',
    storageBucket: 'luka-finanzas-3d8b9.firebasestorage.app',
  );
}
