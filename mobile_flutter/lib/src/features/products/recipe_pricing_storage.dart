import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'recipe_pricing_models.dart';

/// Persiste fichas técnicas no Firestore em users/{uid}/recipe_sheets.
class RecipePricingStorage {
  RecipePricingStorage({required this.uid, FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(uid).collection('recipe_sheets');

  Future<List<RecipeTechnicalSheet>> loadRecipes() async {
    try {
      final snap = await _col.orderBy('updatedAt', descending: true).get();
      return snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        // Garante que o id do documento seja usado
        data['id'] = doc.id;
        // Converte Timestamp do Firestore para String ISO
        _convertTimestamps(data);
        return RecipeTechnicalSheet.fromJson(data);
      }).toList();
    } catch (e, st) {
      debugPrint('Falha ao carregar fichas tecnicas: $e\n$st');
      return const [];
    }
  }

  Future<void> saveRecipe(RecipeTechnicalSheet recipe) async {
    try {
      final data = recipe.toJson();
      data.remove('id'); // id é o doc id, não campo
      await _col.doc(recipe.id).set(data);
    } catch (e, st) {
      debugPrint('Falha ao salvar ficha tecnica: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteRecipe(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e, st) {
      debugPrint('Falha ao excluir ficha tecnica: $e\n$st');
      rethrow;
    }
  }

  /// Converte campos Timestamp do Firestore para String ISO8601.
  void _convertTimestamps(Map<String, dynamic> data) {
    for (final key in ['createdAt', 'updatedAt']) {
      final val = data[key];
      if (val is Timestamp) {
        data[key] = val.toDate().toIso8601String();
      }
    }
  }
}
