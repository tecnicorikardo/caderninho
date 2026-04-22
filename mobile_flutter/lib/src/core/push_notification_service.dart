import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Falha ao inicializar Firebase no background handler: $error');
  }
  debugPrint('Push background message: ${message.messageId ?? 'sem_id'}');
}

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  }) : _messagingOverride = messaging,
       _dbOverride = firestore;

  final FirebaseMessaging? _messagingOverride;
  final FirebaseFirestore? _dbOverride;
  FirebaseMessaging get _messaging => _messagingOverride ?? FirebaseMessaging.instance;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  String? _uid;
  bool _listenersBound = false;

  static void registerBackgroundHandler() {
    if (kIsWeb) return;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (error) {
      debugPrint('Falha ao registrar background handler de push: $error');
    }
  }

  Future<void> configureForUser(String uid) async {
    _uid = uid;
    _bindListenersOnce();

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        'Push permission status: ${settings.authorizationStatus.name}',
      );
    } catch (error) {
      debugPrint('Falha ao solicitar permissao de push: $error');
    }

    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    await _saveCurrentToken(uid);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        'Push abriu app pelo clique na notificacao: ${initialMessage.messageId ?? 'sem_id'}',
      );
    }
  }

  Future<void> clearUserContext() async {
    _uid = null;
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    _onTokenRefreshSub?.cancel();
  }

  void _bindListenersOnce() {
    if (_listenersBound) return;
    _listenersBound = true;

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'Notificacao';
      final body = message.notification?.body ?? '';
      debugPrint('Push foreground: $title | $body');
    });

    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      debugPrint('Push aberto: ${message.messageId ?? 'sem_id'}');
    });

    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      final uid = _uid;
      if (uid == null || token.isEmpty) return;
      await _saveToken(uid: uid, token: token);
    });
  }

  Future<void> _saveCurrentToken(String uid) async {
    try {
      String? token;
      if (kIsWeb) {
        final webVapidKey = const String.fromEnvironment('FCM_WEB_VAPID_KEY');
        if (webVapidKey.trim().isEmpty) {
          debugPrint(
            'Push web sem FCM_WEB_VAPID_KEY. Token nao sera registrado.',
          );
          return;
        }
        token = await _messaging.getToken(vapidKey: webVapidKey);
      } else {
        token = await _messaging.getToken();
      }

      if (token == null || token.isEmpty) {
        debugPrint('Push sem token FCM disponivel.');
        return;
      }
      debugPrint('FCM token ativo: $token');
      await _saveToken(uid: uid, token: token);
    } catch (error) {
      debugPrint('Falha ao obter/salvar token FCM: $error');
    }
  }

  Future<void> _saveToken({required String uid, required String token}) async {
    final now = DateTime.now();
    final userRef = _db.collection('users').doc(uid);
    final payload = {
      'token': token,
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
      'updatedAt': now,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await Future.wait([
      userRef.collection('device_tokens').doc(token).set(
            payload,
            SetOptions(merge: true),
          ),
      userRef.collection('fcm_tokens').doc(token).set(
            payload,
            SetOptions(merge: true),
          ),
    ]);
  }
}
