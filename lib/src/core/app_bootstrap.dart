import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class BootstrapResult {
  const BootstrapResult({required this.ok, this.message});

  final bool ok;
  final String? message;
}

class AppBootstrap {
  static Future<BootstrapResult> initialize() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      if (kIsWeb) {
        await FirebaseFirestore.instance.enablePersistence(
          const PersistenceSettings(synchronizeTabs: true),
        );
      }

      return const BootstrapResult(ok: true);
    } catch (e) {
      return BootstrapResult(ok: false, message: e.toString());
    }
  }
}
