import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  SaleModel({
    required this.id,
    required this.description,
    required this.total,
    required this.paymentMethod,
    required this.mode,
    required this.createdAt,
  });

  final String id;
  final String description;
  final double total;
  final String paymentMethod;
  final String mode;
  final DateTime? createdAt;

  factory SaleModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return SaleModel(
      id: doc.id,
      description: (data['description'] ?? '') as String,
      total: ((data['total'] ?? 0) as num).toDouble(),
      paymentMethod: (data['paymentMethod'] ?? 'dinheiro') as String,
      mode: (data['mode'] ?? 'free') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
