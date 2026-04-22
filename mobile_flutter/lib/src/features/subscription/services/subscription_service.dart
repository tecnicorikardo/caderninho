import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/subscription_model.dart';

class SubscriptionService {
  SubscriptionService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1'),
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  SubscriptionModel? _cachedSubscription;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  String? get _userId => _auth.currentUser?.uid;

  /// Verifica o status da assinatura
  Future<SubscriptionModel?> checkStatus() async {
    final userId = _userId;
    if (userId == null) return null;

    // Usar cache se disponível e válido
    if (_cachedSubscription != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedSubscription;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .get();

      if (!doc.exists) return null;

      _cachedSubscription = SubscriptionModel.fromDoc(doc);
      _cacheTime = DateTime.now();
      return _cachedSubscription;
    } catch (e) {
      print('Error checking subscription status: $e');
      return null;
    }
  }

  /// Stream da assinatura atual
  Stream<SubscriptionModel?> getCurrentSubscription() {
    final userId = _userId;
    if (userId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('current')
        .snapshots()
        .map((doc) {
      try {
        if (!doc.exists) return null;
        final subscription = SubscriptionModel.fromDoc(doc);
        _cachedSubscription = subscription;
        _cacheTime = DateTime.now();
        return subscription;
      } catch (e) {
        print('Error parsing subscription from snapshot: $e');
        // Retornar null em caso de erro ao invés de quebrar o stream
        return null;
      }
    }).handleError((error) {
      print('Error in subscription stream: $error');
      // Retornar null em caso de erro no stream
      return null;
    });
  }

  /// Cria preferência de pagamento no Mercado Pago
  Future<Map<String, dynamic>> createPaymentPreference(String plan) async {
    final userId = _userId;
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final callable = _functions.httpsCallable('createPaymentPreference');
      final result = await callable.call<Map<String, dynamic>>({
        'plan': plan,
      });

      return result.data;
    } catch (e) {
      print('Error creating payment preference: $e');
      rethrow;
    }
  }

  /// Verifica se pode acessar uma funcionalidade
  Future<bool> canAccess(String feature) async {
    final subscription = await checkStatus();
    if (subscription == null) return false;

    // Se está ativa ou em trial válido, pode acessar
    return subscription.isActive;
  }

  /// Calcula dias até expiração
  Future<int> daysUntilExpiration() async {
    final subscription = await checkStatus();
    if (subscription == null) return 0;

    return subscription.daysUntilExpiration;
  }

  /// Limpa o cache (útil após pagamento)
  void clearCache() {
    _cachedSubscription = null;
    _cacheTime = null;
  }

  /// Verifica se deve mostrar banner de aviso
  Future<bool> shouldShowWarning() async {
    final subscription = await checkStatus();
    if (subscription == null) return false;

    return subscription.shouldShowWarning;
  }

  /// Verifica se a assinatura está expirada
  Future<bool> isExpired() async {
    final subscription = await checkStatus();
    if (subscription == null) return true;

    return subscription.isExpired;
  }
}
