import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.salePrice,
    required this.cost,
    required this.stock,
    required this.unit,
    required this.active,
  });

  final String id;
  final String name;
  final String category;
  final double salePrice;
  final double cost;
  final double stock;
  final String unit;
  final bool active;

  factory ProductModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ProductModel(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      salePrice: ((data['salePrice'] ?? 0) as num).toDouble(),
      cost: ((data['cost'] ?? 0) as num).toDouble(),
      stock: ((data['stock'] ?? 0) as num).toDouble(),
      unit: (data['unit'] ?? 'un') as String,
      active: (data['active'] ?? true) as bool,
    );
  }
}
