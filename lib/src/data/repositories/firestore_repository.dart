import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_model.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';

class FirestoreRepository {
  FirestoreRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _scope(String uid, String collection) {
    return _db.collection('users').doc(uid).collection(collection);
  }

  Stream<List<CustomerModel>> watchCustomers(String uid) {
    return _scope(uid, 'customers')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(CustomerModel.fromDoc).toList());
  }

  Future<void> addCustomer({
    required String uid,
    required String name,
    required String phone,
  }) async {
    await _scope(uid, 'customers').add({
      'name': name,
      'phone': phone,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCustomer({required String uid, required String customerId}) {
    return _scope(uid, 'customers').doc(customerId).delete();
  }

  Stream<List<ProductModel>> watchProducts(String uid) {
    return _scope(uid, 'products')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(ProductModel.fromDoc).toList());
  }

  Future<void> addProduct({
    required String uid,
    required String name,
    required String category,
    required double salePrice,
    required double cost,
    required double stock,
    required String unit,
  }) async {
    await _scope(uid, 'products').add({
      'name': name,
      'category': category,
      'salePrice': salePrice,
      'cost': cost,
      'stock': stock,
      'unit': unit,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _scope(uid, 'financial_entries').add({
      'type': 'expense',
      'origin': 'stock_entry',
      'description': 'Compra de estoque: $name',
      'amount': cost * stock,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct({required String uid, required String productId}) {
    return _scope(uid, 'products').doc(productId).delete();
  }

  Stream<List<SaleModel>> watchSalesOfDay(String uid, String dayKey) {
    return _scope(uid, 'sales')
        .where('dayKey', isEqualTo: dayKey)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SaleModel.fromDoc).toList());
  }

  Future<void> addFreeSale({
    required String uid,
    required String description,
    required double total,
    required String paymentMethod,
    required String dayKey,
  }) async {
    final salesRef = _scope(uid, 'sales').doc();
    final financialRef = _scope(uid, 'financial_entries').doc();

    final data = {
      'description': description,
      'total': total,
      'paymentMethod': paymentMethod,
      'mode': 'free',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'dayKey': dayKey,
    };

    await _db.runTransaction((txn) async {
      txn.set(salesRef, data);
      txn.set(financialRef, {
        'type': 'revenue',
        'origin': 'sale',
        'description': description,
        'amount': total,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'dayKey': dayKey,
      });
    });
  }

  Future<void> addProductSale({
    required String uid,
    required ProductModel product,
    required double quantity,
    required String paymentMethod,
    required String dayKey,
  }) async {
    final salesRef = _scope(uid, 'sales').doc();
    final financialRef = _scope(uid, 'financial_entries').doc();
    final productRef = _scope(uid, 'products').doc(product.id);
    final total = quantity * product.salePrice;

    await _db.runTransaction((txn) async {
      final productDoc = await txn.get(productRef);
      final currentStock = ((productDoc.data()?['stock'] ?? 0) as num).toDouble();
      if (currentStock < quantity) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'stock-insufficient',
          message: 'Estoque insuficiente para esta venda.',
        );
      }

      txn.update(productRef, {
        'stock': currentStock - quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      txn.set(salesRef, {
        'description': 'Venda de ${product.name}',
        'total': total,
        'paymentMethod': paymentMethod,
        'mode': 'product',
        'productId': product.id,
        'productName': product.name,
        'quantity': quantity,
        'unitPrice': product.salePrice,
        'estimatedProfit': (product.salePrice - product.cost) * quantity,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'dayKey': dayKey,
      });

      txn.set(financialRef, {
        'type': 'revenue',
        'origin': 'sale',
        'description': 'Venda de ${product.name}',
        'amount': total,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'dayKey': dayKey,
      });
    });
  }

  Future<void> deleteSale({
    required String uid,
    required String saleId,
  }) async {
    final saleRef = _scope(uid, 'sales').doc(saleId);
    
    await _db.runTransaction((txn) async {
      final saleDoc = await txn.get(saleRef);
      
      if (!saleDoc.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Venda não encontrada.',
        );
      }

      final saleData = saleDoc.data()!;
      final mode = saleData['mode'] as String?;
      final productId = saleData['productId'] as String?;
      final quantity = ((saleData['quantity'] ?? 0) as num).toDouble();

      // Se for venda de produto, devolver o estoque
      if (mode == 'product' && productId != null && quantity > 0) {
        final productRef = _scope(uid, 'products').doc(productId);
        final productDoc = await txn.get(productRef);
        
        if (productDoc.exists) {
          final currentStock = ((productDoc.data()?['stock'] ?? 0) as num).toDouble();
          txn.update(productRef, {
            'stock': currentStock + quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Deletar a venda
      txn.delete(saleRef);

      // Deletar entrada financeira relacionada
      final dayKey = saleData['dayKey'] as String?;
      if (dayKey != null) {
        final financialSnap = await _scope(uid, 'financial_entries')
            .where('origin', isEqualTo: 'sale')
            .where('dayKey', isEqualTo: dayKey)
            .get();
        
        for (final doc in financialSnap.docs) {
          txn.delete(doc.reference);
        }
      }
    });
  }
}

  Future<void> deleteAllTransactions(String uid) async {
    final batch = _db.batch();
    
    // Delete sales
    final salesSnap = await _scope(uid, 'sales').get();
    for (final doc in salesSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete financial entries
    final financialSnap = await _scope(uid, 'financial_entries').get();
    for (final doc in financialSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete debts (fiados)
    final debtsSnap = await _scope(uid, 'debts').get();
    for (final doc in debtsSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete debt payments
    final debtPaymentsSnap = await _scope(uid, 'debt_payments').get();
    for (final doc in debtPaymentsSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete loans
    final loansSnap = await _scope(uid, 'loans').get();
    for (final doc in loansSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete loan payments
    final loanPaymentsSnap = await _scope(uid, 'loan_payments').get();
    for (final doc in loanPaymentsSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> deleteAllData(String uid) async {
    // Delete transactions first
    await deleteAllTransactions(uid);

    final batch = _db.batch();

    // Delete customers
    final customersSnap = await _scope(uid, 'customers').get();
    for (final doc in customersSnap.docs) {
      batch.delete(doc.reference);
    }

    // Delete products
    final productsSnap = await _scope(uid, 'products').get();
    for (final doc in productsSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
