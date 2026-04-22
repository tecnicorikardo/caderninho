import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({required this.ok, this.message});

  final bool ok;
  final String? message;
}

class FirebaseBootstrap {
  static Future<FirebaseBootstrapResult> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // No Web, evitar forcar `settings` do Firestore.
      // Em algumas combinacoes de SDK/plugin isso pode gerar erro de interop
      // (FirebaseException tratado como JavaScriptObject).
      if (!kIsWeb) {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }
      return const FirebaseBootstrapResult(ok: true);
    } catch (error) {
      return FirebaseBootstrapResult(ok: false, message: error.toString());
    }
  }
}
