import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'FirebaseOptions nao configurado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAbYh9oAV4H5EPZJytRZq4HM4DG7q0iYIc',
    appId: '1:16911555826:web:addd018a6120ee67ef846b',
    messagingSenderId: '16911555826',
    projectId: 'bloquinhodigital',
    authDomain: 'bloquinhodigital.firebaseapp.com',
    storageBucket: 'bloquinhodigital.firebasestorage.app',
    measurementId: 'G-K6H8VS1F95',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8WHXek0Bmk8lpuE6iP5U8NSRDP3X9hFM',
    appId: '1:16911555826:android:abbce1cf443c3eddef846b',
    messagingSenderId: '16911555826',
    projectId: 'bloquinhodigital',
    storageBucket: 'bloquinhodigital.firebasestorage.app',
  );
}
