import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
    required this.active,
  });

  final String id;
  final String name;
  final String phone;
  final DateTime? createdAt;
  final bool active;

  factory CustomerModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CustomerModel(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      active: (data['active'] ?? true) as bool,
    );
  }
}
