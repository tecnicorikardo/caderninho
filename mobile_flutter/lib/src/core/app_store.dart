import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_formatters.dart';

class AppStore extends ChangeNotifier {
  AppStore({required this.uid, FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance {
    _bindSnapshots();
    unawaited(_ensureUserRootDocument());
    unawaited(_loadSettings());
  }

  final String uid;
  final FirebaseFirestore _db;
  final List<StreamSubscription> _subscriptions = <StreamSubscription>[];

  List<BrandRecord> _brands = <BrandRecord>[];
  List<CustomerRecord> _customers = <CustomerRecord>[];
  List<ProductRecord> _products = <ProductRecord>[];
  List<SaleRecord> _sales = <SaleRecord>[];
  List<DebtRecord> _debts = <DebtRecord>[];
  List<PersonalDebtRecord> _personalDebts = <PersonalDebtRecord>[];
  List<LoanRecord> _loans = <LoanRecord>[];
  List<FinancialEntry> _financialEntries = <FinancialEntry>[];
  List<PersonalFinanceEntry> _personalEntries = <PersonalFinanceEntry>[];
  int _loanAlertDays = 3;
  int _personalDebtReminderDays = 3;
  ShopProfile _shopProfile = const ShopProfile.empty();

  UnmodifiableListView<BrandRecord> get brands => UnmodifiableListView(_brands);
  UnmodifiableListView<CustomerRecord> get customers =>
      UnmodifiableListView(_customers);
  UnmodifiableListView<ProductRecord> get products =>
      UnmodifiableListView(_products);
  UnmodifiableListView<SaleRecord> get sales => UnmodifiableListView(_sales);
  UnmodifiableListView<DebtRecord> get debts => UnmodifiableListView(_debts);
  UnmodifiableListView<PersonalDebtRecord> get personalDebts =>
      UnmodifiableListView(_personalDebts);
  UnmodifiableListView<LoanRecord> get loans => UnmodifiableListView(_loans);
  UnmodifiableListView<FinancialEntry> get financialEntries =>
      UnmodifiableListView(_financialEntries);
  UnmodifiableListView<PersonalFinanceEntry> get personalEntries =>
      UnmodifiableListView(_personalEntries);
  int get loanAlertDays => _loanAlertDays;
  int get personalDebtReminderDays => _personalDebtReminderDays;
  ShopProfile get shopProfile => _shopProfile;

  static const String _loanAlertDaysKey = 'loan_alert_days';
  static const String _personalDebtReminderDaysKey =
      'personal_debt_reminder_days';
  static const List<String> personalRevenueCategories = [
    'Vendas',
    'Servicos',
    'Recebimentos',
    'Outras receitas',
  ];
  static const List<String> personalExpenseCategories = [
    'Estoque',
    'Operacional',
    'Impostos',
    'Despesas pessoais',
    'Outras despesas',
  ];
  static const List<String> personalDebtCategories = [
    'Fornecedor',
    'Cartao',
    'Emprestimo',
    'Impostos',
    'Pessoal',
    'Outras dividas',
  ];

  CollectionReference<Map<String, dynamic>> _col(String collection) {
    return _db.collection('users').doc(uid).collection(collection);
  }

  Future<void> _ensureUserRootDocument() async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'is_active': true,
        'updatedAt': DateTime.now(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Falha ao garantir users/$uid: $error');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loanDays = prefs.getInt(_loanAlertDaysKey);
      if (loanDays != null && (loanDays == 3 || loanDays == 5)) {
        _loanAlertDays = loanDays;
      }

      final debtDays = prefs.getInt(_personalDebtReminderDaysKey);
      if (debtDays != null &&
          (debtDays == 1 || debtDays == 3 || debtDays == 7)) {
        _personalDebtReminderDays = debtDays;
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Falha ao carregar configuracoes locais: $error');
    }
  }

  Future<void> setLoanAlertDays(int days) async {
    if (days != 3 && days != 5) return;
    _loanAlertDays = days;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_loanAlertDaysKey, days);
    } catch (error) {
      debugPrint('Falha ao salvar configuracao de alerta: $error');
    }
  }

  Future<void> setPersonalDebtReminderDays(int days) async {
    if (days != 1 && days != 3 && days != 7) return;
    _personalDebtReminderDays = days;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_personalDebtReminderDaysKey, days);
    } catch (error) {
      debugPrint('Falha ao salvar configuracao de lembrete de dividas: $error');
    }
  }

  void _bindSnapshots() {
    _subscriptions.add(
      _col('brands').snapshots().listen(
        (snapshot) {
          _brands = snapshot.docs.map(BrandRecord.fromDoc).toList()
            ..sort((a, b) {
              if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Erro ao ler brands: $error');
        },
      ),
    );

    _subscriptions.add(
      _col('customers').snapshots().listen(
        (snapshot) {
          _customers = snapshot.docs.map(CustomerRecord.fromDoc).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Erro ao ler customers: $error');
        },
      ),
    );

    _subscriptions.add(
      _col('products').snapshots().listen(
        (snapshot) {
          _products = snapshot.docs.map(ProductRecord.fromDoc).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Erro ao ler products: $error');
        },
      ),
    );

    _subscriptions.add(
      _col('sales').snapshots().listen(
        (snapshot) {
          _sales = snapshot.docs.map(SaleRecord.fromDoc).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Erro ao ler sales: $error');
        },
      ),
    );

    _subscriptions.add(
      _col('debts').snapshots().listen(
        (snapshot) {
          _debts = snapshot.docs.map(DebtRecord.fromDoc).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Erro ao ler debts: $error');
        },
      ),
    );

    _subscriptions.add(
      _col('personal_debts').snapshots().listen(
        (snapshot) {
          _personalDebts =
              snapshot.docs.map(PersonalDebtRecord.fromDoc).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Erro ao ler personal_debts: $error');
        },
      ),
    );

    _subscriptions.add(
      _col('loans').snapshots().listen(
        (snapshot) {
          _loans = snapshot.docs.map(LoanRecord.fromDoc).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Erro ao ler loans: $error');
        },
      ),
    );

    _subscriptions.add(
      _col('financial_entries').snapshots().listen(
        (snapshot) {
          _financialEntries = snapshot.docs.map(FinancialEntry.fromDoc).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Erro ao ler financial_entries: $error');
        },
      ),
    );

    _subscriptions.add(
      _col('personal_entries').snapshots().listen(
        (snapshot) {
          _personalEntries =
              snapshot.docs.map(PersonalFinanceEntry.fromDoc).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Erro ao ler personal_entries: $error');
        },
      ),
    );

    _subscriptions.add(
      _col('settings')
          .doc('store_profile')
          .snapshots()
          .listen(
            (snapshot) {
              _shopProfile = ShopProfile.fromDoc(snapshot);
              notifyListeners();
            },
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('Erro ao ler settings/store_profile: $error');
            },
          ),
    );
  }

  Future<void> saveShopProfile({
    required String storeName,
    required String address,
    required String phone,
    required String pixKey,
    required String storeSlug,
    required bool isActive,
  }) {
    final normalizedSlug = _normalizeSlug(storeSlug);
    final now = DateTime.now();
    final batch = _db.batch();
    final settingsRef = _col('settings').doc('store_profile');
    final userRef = _db.collection('users').doc(uid);
    batch.set(settingsRef, {
      'storeName': storeName.trim(),
      'address': address.trim(),
      'phone': phone.trim(),
      'pixKey': pixKey.trim(),
      'storeSlug': normalizedSlug,
      'isActive': isActive,
      'updatedAt': now,
    }, SetOptions(merge: true));
    batch.set(userRef, {
      'storeSlug': normalizedSlug,
      'is_active': isActive,
      'storeName': storeName.trim(),
      'phone': phone.trim(),
      'updatedAt': now,
    }, SetOptions(merge: true));
    return batch.commit();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  int get todaysSalesCount =>
      _sales.where((s) => _isSameDay(s.createdAt, _today)).length;

  double get todaysSalesTotal => _sales
      .where((s) => _isSameDay(s.createdAt, _today))
      .fold<double>(0, (acc, item) => acc + item.total);

  int get todaysFiadosCount {
    final debtCount = _debts
        .where((d) => _isSameDay(d.createdAt, _today))
        .length;
    final loanCount = _loans
        .where((l) => _isSameDay(l.createdAt, _today))
        .length;
    return debtCount + loanCount;
  }

  double get todaysFiadosOpenTotal {
    final debtTotal = _debts
        .where((d) => _isSameDay(d.createdAt, _today))
        .fold<double>(0, (acc, d) => acc + d.openAmount);
    final loanTotal = _loans
        .where((l) => _isSameDay(l.createdAt, _today))
        .fold<double>(0, (acc, l) => acc + getLoanOpenAmount(l));
    return debtTotal + loanTotal;
  }

  double get todayRevenue => _financialEntries
      .where((e) => e.type == FinancialEntryType.revenue)
      .where((e) => _isSameDay(e.createdAt, _today))
      .fold<double>(0, (acc, e) => acc + e.amount);

  double get todayExpense => _financialEntries
      .where(
        (e) =>
            e.type == FinancialEntryType.expense ||
            e.type == FinancialEntryType.stock,
      )
      .where((e) => _isSameDay(e.createdAt, _today))
      .fold<double>(0, (acc, e) => acc + e.amount);

  double get todayBalance => todayRevenue - todayExpense;

  double get totalOpenDebts =>
      _debts.fold<double>(0, (acc, d) => acc + d.openAmount);

  double get totalOpenLoans =>
      _loans.fold<double>(0, (acc, l) => acc + getLoanOpenAmount(l));

  double get totalOpenPersonalDebts =>
      _personalDebts.fold<double>(0, (acc, debt) => acc + debt.openAmount);

  Future<void> addPersonalRevenue({
    required String description,
    required double amount,
    required String category,
    required DateTime expectedDate,
    PersonalEntryRecurrence recurrence = PersonalEntryRecurrence.once,
    bool remindersEnabled = true,
  }) {
    return _addPersonalEntry(
      type: FinancialEntryType.revenue,
      description: description,
      amount: amount,
      category: category,
      origin: 'personal_manual',
      expectedDate: expectedDate,
      recurrence: recurrence,
      remindersEnabled: remindersEnabled,
    );
  }

  Future<void> addPersonalExpense({
    required String description,
    required double amount,
    required String category,
    required DateTime expectedDate,
    PersonalEntryRecurrence recurrence = PersonalEntryRecurrence.once,
    bool remindersEnabled = true,
  }) {
    return _addPersonalEntry(
      type: FinancialEntryType.expense,
      description: description,
      amount: amount,
      category: category,
      origin: 'personal_manual',
      expectedDate: expectedDate,
      recurrence: recurrence,
      remindersEnabled: remindersEnabled,
    );
  }

  Future<void> _addPersonalEntry({
    required FinancialEntryType type,
    required String description,
    required double amount,
    required String category,
    required String origin,
    required DateTime expectedDate,
    required PersonalEntryRecurrence recurrence,
    required bool remindersEnabled,
  }) async {
    final normalizedDescription = description.trim();
    final normalizedCategory = category.trim();
    final plannedDate = DateTime(
      expectedDate.year,
      expectedDate.month,
      expectedDate.day,
      12,
    );
    if (normalizedDescription.isEmpty) {
      throw StateError('Informe uma descricao para o lancamento.');
    }
    if (normalizedCategory.isEmpty) {
      throw StateError('Informe uma categoria para o lancamento.');
    }
    if (amount <= 0) {
      throw StateError('Valor deve ser maior que zero.');
    }

    await _col('personal_entries').add({
      'type': type.name,
      'description': normalizedDescription,
      'category': normalizedCategory,
      'amount': amount,
      'origin': origin,
      'expectedDate': plannedDate,
      'recurrence': recurrence.name,
      'remindersEnabled': remindersEnabled,
      'createdAt': DateTime.now(),
    });
  }

  List<PersonalFinanceEntry> personalEntriesForPeriod(FinancialPeriod period) {
    final now = DateTime.now();
    final start = _periodStart(period, now);
    final end = _periodEnd(period, now);

    final filtered = _personalEntries.where((entry) {
      return _personalEntryOccurrenceInRange(entry, start: start, end: end) !=
          null;
    }).toList();

    filtered.sort((a, b) {
      final aDate =
          _personalEntryOccurrenceInRange(a, start: start, end: end) ??
          a.expectedDate ??
          a.createdAt;
      final bDate =
          _personalEntryOccurrenceInRange(b, start: start, end: end) ??
          b.expectedDate ??
          b.createdAt;
      return aDate.compareTo(bDate);
    });
    return filtered;
  }

  DateTime? personalEntryOccurrenceForPeriod(
    PersonalFinanceEntry entry,
    FinancialPeriod period,
  ) {
    final now = DateTime.now();
    final start = _periodStart(period, now);
    final end = _periodEnd(period, now);
    return _personalEntryOccurrenceInRange(entry, start: start, end: end);
  }

  DateTime? personalEntryNextOccurrence(
    PersonalFinanceEntry entry, {
    DateTime? from,
  }) {
    final reference = _startOfDay(from ?? DateTime.now());
    final baseDate = _startOfDay(entry.expectedDate ?? entry.createdAt);

    if (entry.recurrence == PersonalEntryRecurrence.once) {
      return baseDate.isBefore(reference) ? null : baseDate;
    }

    var monthCursor = DateTime(reference.year, reference.month, 1);
    for (var i = 0; i < 24; i++) {
      final occurrence = _monthlyOccurrenceForMonth(
        baseDate,
        monthCursor.year,
        monthCursor.month,
      );
      if (!occurrence.isBefore(baseDate) && !occurrence.isBefore(reference)) {
        return occurrence;
      }
      monthCursor = DateTime(monthCursor.year, monthCursor.month + 1, 1);
    }
    return null;
  }

  Future<void> addCustomer({required String name, required String phone}) {
    return _col('customers').add({
      'name': name,
      'phone': phone,
      'isActive': true,
      'createdAt': DateTime.now(),
    });
  }

  Future<void> updateCustomer({
    required String customerId,
    required String name,
    required String phone,
  }) {
    return _col('customers').doc(customerId).update({
      'name': name,
      'phone': phone,
      'updatedAt': DateTime.now(),
    });
  }

  Future<CustomerRemovalOutcome> removeCustomerWithPolicy({
    required CustomerRecord customer,
  }) async {
    final hasOpenDebts = _debts.any(
      (debt) =>
          debt.customerName.trim().toLowerCase() ==
              customer.name.trim().toLowerCase() &&
          debt.openAmount > 0,
    );
    final hasOpenLoans = _loans.any(
      (loan) =>
          loan.customerName.trim().toLowerCase() ==
              customer.name.trim().toLowerCase() &&
          getLoanOpenAmount(loan) > 0,
    );

    final customerRef = _col('customers').doc(customer.id);
    if (hasOpenDebts || hasOpenLoans) {
      await customerRef.update({
        'isActive': false,
        'inactiveReason': 'Possui pendencias em aberto',
        'updatedAt': DateTime.now(),
      });
      return CustomerRemovalOutcome.inactivated;
    }

    await customerRef.delete();
    return CustomerRemovalOutcome.deleted;
  }

  Future<void> reactivateCustomer({required String customerId}) {
    return _col('customers').doc(customerId).update({
      'isActive': true,
      'inactiveReason': FieldValue.delete(),
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> addBrand({
    required String name,
    String? logoUrl,
    required double defaultCommissionPercent,
    bool isActive = true,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw StateError('Informe o nome da marca.');
    }

    final now = DateTime.now();
    await _col('brands').add({
      'name': trimmedName,
      'logoUrl': logoUrl?.trim() ?? '',
      'defaultCommissionPercent': defaultCommissionPercent < 0
          ? 0
          : defaultCommissionPercent,
      'isActive': isActive,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateBrand({
    required String brandId,
    required String name,
    String? logoUrl,
    required double defaultCommissionPercent,
    required bool isActive,
    bool syncProducts = false,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw StateError('Informe o nome da marca.');
    }

    final now = DateTime.now();
    final brandRef = _col('brands').doc(brandId);
    await brandRef.update({
      'name': trimmedName,
      'logoUrl': logoUrl?.trim() ?? '',
      'defaultCommissionPercent': defaultCommissionPercent < 0
          ? 0
          : defaultCommissionPercent,
      'isActive': isActive,
      'updatedAt': now,
    });

    final productsSnap = await _col(
      'products',
    ).where('brandId', isEqualTo: brandId).get();
    if (productsSnap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in productsSnap.docs) {
      final data = doc.data();
      final hasCustomCommission =
          (data['hasCustomCommission'] as bool?) ?? false;
      final payload = <String, dynamic>{
        'brandName': trimmedName,
        'updatedAt': now,
      };
      if (syncProducts && !hasCustomCommission) {
        payload['commissionPercent'] = defaultCommissionPercent < 0
            ? 0
            : defaultCommissionPercent;
      }
      batch.update(doc.reference, payload);
    }
    await batch.commit();
  }

  Future<void> addProduct({
    required String name,
    required String category,
    required double salePrice,
    required double cost,
    required double stock,
    required String unit,
    required bool showInWeb,
    String? sku,
    String? barcode,
    String? brandId,
    String? brandName,
    String? description,
    String? sizeLabel,
    String? variation,
    double commissionPercent = 0,
    bool hasCustomCommission = false,
    ProductSituation situation = ProductSituation.current,
    double automaticDiscountPercent = 0,
    double stockMinimum = 0,
    DateTime? expiryDate,
    String? batchCode,
    String? storageLocation,
    String? imageUrl,
    String? thumbnailUrl,
    String? notes,
    bool registerStockExpense = false,
  }) async {
    final now = DateTime.now();
    final batch = _db.batch();
    final productRef = _col('products').doc();
    batch.set(productRef, {
      'name': name,
      'category': category,
      'salePrice': salePrice,
      'cost': cost,
      'stock': stock,
      'unit': unit,
      'sku': sku?.trim() ?? '',
      'barcode': barcode?.trim() ?? '',
      'brandId': brandId?.trim() ?? '',
      'brandName': brandName?.trim() ?? '',
      'description': description?.trim() ?? '',
      'sizeLabel': sizeLabel?.trim() ?? '',
      'variation': variation?.trim() ?? '',
      'commissionPercent': commissionPercent < 0 ? 0 : commissionPercent,
      'hasCustomCommission': hasCustomCommission,
      'situation': situation.firestoreKey,
      'automaticDiscountPercent': _normalizeDiscountPercent(
        automaticDiscountPercent,
      ),
      'stockMinimum': stockMinimum < 0 ? 0 : stockMinimum,
      'expiryDate': expiryDate,
      'batch': batchCode?.trim() ?? '',
      'storageLocation': storageLocation?.trim() ?? '',
      'showInWeb': showInWeb,
      'userId': uid,
      'imageUrl': imageUrl?.trim() ?? '',
      'thumbnailUrl': thumbnailUrl?.trim() ?? '',
      'notes': notes?.trim() ?? '',
      'createdAt': now,
    });

    if (registerStockExpense && cost > 0 && stock > 0) {
      final expenseRef = _col('financial_entries').doc();
      batch.set(expenseRef, {
        'type': 'stock',
        'description': 'Compra de estoque: $name',
        'category': 'Estoque',
        'amount': cost * stock,
        'origin': 'stock',
        'createdAt': now,
      });
    }

    await batch.commit();
  }

  Future<void> updateProduct({
    required String productId,
    required String name,
    required String category,
    required double salePrice,
    required double cost,
    required double stock,
    required String unit,
    required bool showInWeb,
    required String sku,
    required String barcode,
    required String brandId,
    required String brandName,
    required String description,
    required String sizeLabel,
    required String variation,
    required double commissionPercent,
    required bool hasCustomCommission,
    required ProductSituation situation,
    required double automaticDiscountPercent,
    required double stockMinimum,
    required DateTime? expiryDate,
    required String batchCode,
    required String storageLocation,
    String? imageUrl,
    String? thumbnailUrl,
    required String notes,
    String? stockChangeReason,
    bool registerStockMovement = true,
    bool registerStockFinancialEntry = false,
  }) async {
    final productRef = _col('products').doc(productId);
    final now = DateTime.now();

    await _db.runTransaction((txn) async {
      final snap = await txn.get(productRef);
      if (!snap.exists) {
        throw StateError('Produto nao encontrado.');
      }

      final current = ProductRecord.fromDoc(snap);
      txn.update(productRef, {
        'name': name,
        'category': category,
        'salePrice': salePrice,
        'cost': cost,
        'stock': stock,
        'unit': unit,
        'sku': sku.trim(),
        'barcode': barcode.trim(),
        'brandId': brandId.trim(),
        'brandName': brandName.trim(),
        'description': description.trim(),
        'sizeLabel': sizeLabel.trim(),
        'variation': variation.trim(),
        'commissionPercent': commissionPercent < 0 ? 0 : commissionPercent,
        'hasCustomCommission': hasCustomCommission,
        'situation': situation.firestoreKey,
        'automaticDiscountPercent': _normalizeDiscountPercent(
          automaticDiscountPercent,
        ),
        'stockMinimum': stockMinimum < 0 ? 0 : stockMinimum,
        'expiryDate': expiryDate,
        'batch': batchCode.trim(),
        'storageLocation': storageLocation.trim(),
        'showInWeb': showInWeb,
        'userId': uid,
        'imageUrl': imageUrl?.trim() ?? '',
        'thumbnailUrl': thumbnailUrl?.trim() ?? '',
        'notes': notes.trim(),
        'updatedAt': now,
      });

      final stockDelta = stock - current.stock;
      if (stockDelta == 0 || !registerStockMovement) return;

      final reason = (stockChangeReason ?? '').trim().isEmpty
          ? 'Ajuste manual em edicao'
          : stockChangeReason!.trim();

      final movementRef = _col('stock_movements').doc();
      txn.set(movementRef, {
        'productId': productId,
        'productName': name,
        'delta': stockDelta,
        'stockBefore': current.stock,
        'stockAfter': stock,
        'reason': reason,
        'createdAt': now,
      });

      if (registerStockFinancialEntry && cost > 0) {
        final amount = cost * stockDelta.abs();
        final entryRef = _col('financial_entries').doc();
        final movementLabel = stockDelta > 0
            ? 'Entrada de estoque'
            : 'Baixa de estoque';
        txn.set(entryRef, {
          'type': 'expense',
          'description': '$movementLabel: $name | Motivo: $reason',
          'category': 'Estoque',
          'amount': amount,
          'origin': 'stock_adjustment',
          'createdAt': now,
        });
      }
    });
  }

  Future<void> adjustProductStock({
    required ProductRecord product,
    required double quantity,
    required String reason,
  }) async {
    if (quantity <= 0) {
      throw StateError('Quantidade deve ser maior que zero.');
    }
    final nextStock = product.stock + quantity;
    await updateProduct(
      productId: product.id,
      name: product.name,
      category: product.category,
      salePrice: product.salePrice,
      cost: product.cost,
      stock: nextStock,
      unit: product.unit,
      showInWeb: product.showInWeb,
      sku: product.sku,
      barcode: product.barcode,
      brandId: product.brandId,
      brandName: product.brandName,
      description: product.description,
      sizeLabel: product.sizeLabel,
      variation: product.variation,
      commissionPercent: product.commissionPercent,
      hasCustomCommission: product.hasCustomCommission,
      situation: product.situation,
      automaticDiscountPercent: product.automaticDiscountPercent,
      stockMinimum: product.stockMinimum,
      expiryDate: product.expiryDate,
      batchCode: product.batchCode,
      storageLocation: product.storageLocation,
      imageUrl: product.imageUrl,
      thumbnailUrl: product.thumbnailUrl,
      notes: product.notes,
      stockChangeReason: reason,
    );
  }

  Future<void> deleteProduct({
    required ProductRecord product,
    String reason = 'Exclusao do produto',
  }) async {
    final now = DateTime.now();
    final productRef = _col('products').doc(product.id);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(productRef);
      if (!snap.exists) {
        throw StateError('Produto nao encontrado.');
      }

      final current = ProductRecord.fromDoc(snap);
      if (current.stock > 0) {
        final movementRef = _col('stock_movements').doc();
        txn.set(movementRef, {
          'productId': current.id,
          'productName': current.name,
          'delta': -current.stock,
          'stockBefore': current.stock,
          'stockAfter': 0,
          'reason': reason,
          'createdAt': now,
        });
      }

      txn.delete(productRef);
    });
  }

  Future<void> registerFreeSale({
    required String description,
    required double total,
    required String paymentMethod,
    String? customerName,
    DateTime? loanDueDate,
    double loanInterestRate = 2,
    LoanInterestUnit loanInterestUnit = LoanInterestUnit.month,
  }) async {
    final now = DateTime.now();
    final dayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final batch = _db.batch();
    final saleRef = _col('sales').doc();
    final trimmedCustomerName = (customerName ?? '').trim();
    final isFiado = paymentMethod == 'fiado';
    final isLoan = paymentMethod == 'emprestimo';
    DocumentReference<Map<String, dynamic>>? debtRef;
    DocumentReference<Map<String, dynamic>>? loanRef;
    DocumentReference<Map<String, dynamic>>? revenueRef;

    batch.set(saleRef, {
      'description': description,
      'total': total,
      'mode': 'free',
      'paymentMethod': paymentMethod,
      'customerName': trimmedCustomerName.isEmpty ? null : trimmedCustomerName,
      'productName': null,
      'productId': null,
      'quantity': null,
      'brandId': null,
      'brandName': null,
      'commissionPercent': null,
      'commissionAmount': null,
      'debtId': null,
      'loanId': null,
      'financialEntryId': null,
      'dayKey': dayKey,
      'createdAt': now,
    });

    if (isFiado) {
      debtRef = _col('debts').doc();
      batch.set(debtRef, {
        'saleId': saleRef.id,
        'customerName': trimmedCustomerName.isEmpty
            ? 'Cliente nao informado'
            : trimmedCustomerName,
        'description': 'Fiado de venda: $description',
        'category': 'Fiado',
        'originalAmount': total,
        'openAmount': total,
        'createdAt': now,
      });
    } else if (isLoan) {
      if (loanDueDate == null) {
        throw StateError('Informe o vencimento para emprestimo.');
      }
      loanRef = _col('loans').doc();
      batch.set(loanRef, {
        'saleId': saleRef.id,
        'customerName': trimmedCustomerName.isEmpty
            ? 'Cliente nao informado'
            : trimmedCustomerName,
        'principal': total,
        'paidAmount': 0,
        'dueDate': loanDueDate,
        'interestRate': loanInterestRate,
        'interestUnit': loanInterestUnit.name,
        'createdAt': now,
      });
    } else {
      revenueRef = _col('financial_entries').doc();
      batch.set(revenueRef, {
        'saleId': saleRef.id,
        'type': 'revenue',
        'description': description,
        'category': 'Vendas',
        'amount': total,
        'origin': 'sale',
        'dayKey': dayKey,
        'createdAt': now,
      });
    }

    batch.update(saleRef, {
      'debtId': debtRef?.id,
      'loanId': loanRef?.id,
      'financialEntryId': revenueRef?.id,
    });

    await batch.commit();
  }

  String _productLotGroupKey(ProductRecord product) {
    final sku = product.sku.trim().toLowerCase();
    if (sku.isNotEmpty) return 'sku:$sku';
    final barcode = product.barcode.trim().toLowerCase();
    if (barcode.isNotEmpty) return 'barcode:$barcode';
    return [
      product.name.trim().toLowerCase(),
      product.brandId.trim().toLowerCase(),
      product.brandName.trim().toLowerCase(),
      product.category.trim().toLowerCase(),
    ].join('|');
  }

  int _compareLots(ProductRecord a, ProductRecord b) {
    final aDate = a.expiryDate ?? a.createdAt;
    final bDate = b.expiryDate ?? b.createdAt;
    final dateCompare = aDate.compareTo(bDate);
    if (dateCompare != 0) return dateCompare;
    final batchCompare = a.batchCode.compareTo(b.batchCode);
    if (batchCompare != 0) return batchCompare;
    return a.createdAt.compareTo(b.createdAt);
  }

  List<ProductRecord> _lotCandidatesFor(ProductRecord selected) {
    final key = _productLotGroupKey(selected);
    final candidates = _products
        .where((product) => product.stock > 0)
        .where((product) => _productLotGroupKey(product) == key)
        .toList();
    if (candidates.every((product) => product.id != selected.id)) {
      candidates.add(selected);
    }
    candidates.sort(_compareLots);
    return candidates;
  }

  Future<String?> registerProductSale({
    required String productId,
    required double quantity,
    required String paymentMethod,
    String? customerName,
    DateTime? loanDueDate,
    double loanInterestRate = 2,
    LoanInterestUnit loanInterestUnit = LoanInterestUnit.month,
  }) async {
    if (quantity <= 0) {
      return 'Quantidade deve ser maior que zero.';
    }

    final now = DateTime.now();
    final trimmedCustomerName = (customerName ?? '').trim();
    final isFiado = paymentMethod == 'fiado';
    final isLoan = paymentMethod == 'emprestimo';

    try {
      await _db.runTransaction((txn) async {
        final productRef = _col('products').doc(productId);
        final productSnap = await txn.get(productRef);
        if (!productSnap.exists) {
          throw StateError('Produto nao encontrado.');
        }

        final selectedProduct = ProductRecord.fromDoc(productSnap);
        final selectedKey = _productLotGroupKey(selectedProduct);
        final candidates = _lotCandidatesFor(selectedProduct);
        var remaining = quantity;
        var total = 0.0;
        var originalTotal = 0.0;
        var commissionAmount = 0.0;
        final lotBreakdown = <Map<String, dynamic>>[];

        for (final candidate in candidates) {
          if (remaining <= 0) break;
          final ref = _col('products').doc(candidate.id);
          final snap = candidate.id == selectedProduct.id
              ? productSnap
              : await txn.get(ref);
          if (!snap.exists) continue;

          final lot = ProductRecord.fromDoc(snap);
          if (_productLotGroupKey(lot) != selectedKey || lot.stock <= 0) {
            continue;
          }

          final take = lot.stock >= remaining ? remaining : lot.stock;
          final unitPrice = lot.effectiveSalePrice;
          final originalUnitPrice = lot.salePrice;
          total += unitPrice * take;
          originalTotal += originalUnitPrice * take;
          commissionAmount +=
              (unitPrice * take) * (lot.commissionPercent / 100);

          txn.update(ref, {'stock': lot.stock - take, 'updatedAt': now});

          lotBreakdown.add({
            'productId': lot.id,
            'productName': lot.name,
            'batch': lot.batchCode,
            'expiryDate': lot.expiryDate,
            'quantity': take,
            'unitPrice': unitPrice,
            'originalUnitPrice': originalUnitPrice,
            'discountPercent': lot.hasAutomaticDiscount
                ? _normalizeDiscountPercent(lot.automaticDiscountPercent)
                : 0,
          });
          remaining -= take;
        }

        if (remaining > 0.000001) {
          throw StateError('Estoque insuficiente para a venda.');
        }

        final productName = selectedProduct.name;
        final brandId = selectedProduct.brandId;
        final brandName = selectedProduct.brandName;
        final commissionPercent = selectedProduct.commissionPercent;
        final discountAmount = originalTotal - total;
        final discountPercent = originalTotal <= 0
            ? 0.0
            : (discountAmount / originalTotal) * 100;
        final desc = 'Venda de $productName';
        final dayKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final saleRef = _col('sales').doc();
        DocumentReference<Map<String, dynamic>>? debtRef;
        DocumentReference<Map<String, dynamic>>? loanRef;
        DocumentReference<Map<String, dynamic>>? revenueRef;

        txn.set(saleRef, {
          'description': desc,
          'total': total,
          'mode': 'product',
          'paymentMethod': paymentMethod,
          'customerName': trimmedCustomerName.isEmpty
              ? null
              : trimmedCustomerName,
          'productName': productName,
          'productId': productId,
          'quantity': quantity,
          'unitSalePrice': quantity <= 0 ? 0 : total / quantity,
          'originalUnitPrice': quantity <= 0 ? 0 : originalTotal / quantity,
          'discountPercent': discountPercent,
          'discountAmount': discountAmount <= 0 ? 0 : discountAmount,
          'lotBreakdown': lotBreakdown,
          'brandId': brandId.isEmpty ? null : brandId,
          'brandName': brandName.isEmpty ? null : brandName,
          'commissionPercent': commissionPercent,
          'commissionAmount': commissionAmount,
          'debtId': null,
          'loanId': null,
          'financialEntryId': null,
          'dayKey': dayKey,
          'createdAt': now,
        });

        if (isFiado) {
          debtRef = _col('debts').doc();
          txn.set(debtRef, {
            'saleId': saleRef.id,
            'customerName': trimmedCustomerName.isEmpty
                ? 'Cliente nao informado'
                : trimmedCustomerName,
            'description': 'Fiado de venda: $desc',
            'category': 'Fiado',
            'originalAmount': total,
            'openAmount': total,
            'createdAt': now,
          });
        } else if (isLoan) {
          if (loanDueDate == null) {
            throw StateError('Informe o vencimento para emprestimo.');
          }
          loanRef = _col('loans').doc();
          txn.set(loanRef, {
            'saleId': saleRef.id,
            'customerName': trimmedCustomerName.isEmpty
                ? 'Cliente nao informado'
                : trimmedCustomerName,
            'principal': total,
            'paidAmount': 0,
            'dueDate': loanDueDate,
            'interestRate': loanInterestRate,
            'interestUnit': loanInterestUnit.name,
            'createdAt': now,
          });
        } else {
          revenueRef = _col('financial_entries').doc();
          txn.set(revenueRef, {
            'saleId': saleRef.id,
            'type': 'revenue',
            'description': desc,
            'category': 'Vendas',
            'amount': total,
            'origin': 'sale',
            'dayKey': dayKey,
            'createdAt': now,
          });
        }

        txn.update(saleRef, {
          'debtId': debtRef?.id,
          'loanId': loanRef?.id,
          'financialEntryId': revenueRef?.id,
        });
      });
      return null;
    } on StateError catch (error) {
      return error.message;
    } catch (_) {
      return 'Falha ao registrar venda com produto.';
    }
  }

  Future<void> addDebt({
    required String customerName,
    required String description,
    required double amount,
    String category = 'Outras dividas',
  }) {
    return _col('debts').add({
      'customerName': customerName,
      'description': description,
      'category': category.trim().isEmpty ? 'Outras dividas' : category.trim(),
      'originalAmount': amount,
      'openAmount': amount,
      'createdAt': DateTime.now(),
    });
  }

  Future<String?> payDebt({
    required String debtId,
    required double amount,
  }) async {
    if (amount <= 0) return 'Valor de pagamento invalido.';

    try {
      await _db.runTransaction((txn) async {
        final debtRef = _col('debts').doc(debtId);
        final debtSnap = await txn.get(debtRef);
        if (!debtSnap.exists) {
          throw StateError('Divida nao encontrada.');
        }
        final data = debtSnap.data() ?? <String, dynamic>{};
        final openAmount = (data['openAmount'] as num?)?.toDouble() ?? 0;
        if (amount > openAmount) {
          throw StateError('Pagamento maior que saldo da divida.');
        }

        txn.update(debtRef, {'openAmount': openAmount - amount});
        final entryRef = _col('financial_entries').doc();
        txn.set(entryRef, {
          'type': 'revenue',
          'description':
              'Pagamento de fiado: ${data['customerName'] ?? 'Cliente'}',
          'category': 'Recebimentos',
          'amount': amount,
          'origin': 'fiado_payment',
          'createdAt': DateTime.now(),
        });
      });
      return null;
    } on StateError catch (error) {
      return error.message;
    } catch (_) {
      return 'Falha ao registrar pagamento de fiado.';
    }
  }

  Future<void> addPersonalDebt({
    required String title,
    required double amount,
    String category = 'Outras dividas',
    DateTime? dueDate,
    String note = '',
    bool reminderEnabled = true,
  }) {
    if (title.trim().isEmpty) {
      throw StateError('Informe o nome da divida.');
    }
    if (amount <= 0) {
      throw StateError('Valor da divida deve ser maior que zero.');
    }

    final now = DateTime.now();
    return _col('personal_debts').add({
      'title': title.trim(),
      'category': category.trim().isEmpty ? 'Outras dividas' : category.trim(),
      'note': note.trim(),
      'originalAmount': amount,
      'openAmount': amount,
      'dueDate': dueDate,
      'reminderEnabled': reminderEnabled,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<String?> payPersonalDebt({
    required String debtId,
    required double amount,
  }) async {
    if (amount <= 0) return 'Valor de pagamento invalido.';

    try {
      await _db.runTransaction((txn) async {
        final debtRef = _col('personal_debts').doc(debtId);
        final debtSnap = await txn.get(debtRef);
        if (!debtSnap.exists) {
          throw StateError('Divida pessoal nao encontrada.');
        }
        final data = debtSnap.data() ?? <String, dynamic>{};
        final title = (data['title'] ?? 'Divida').toString();
        final debtCategory = (data['category'] ?? 'Despesas pessoais')
            .toString();
        final openAmount = (data['openAmount'] as num?)?.toDouble() ?? 0;
        if (amount > openAmount) {
          throw StateError('Pagamento maior que saldo da divida.');
        }

        final nextOpen = openAmount - amount;
        txn.update(debtRef, {
          'openAmount': nextOpen <= 0 ? 0 : nextOpen,
          'updatedAt': DateTime.now(),
        });

        final now = DateTime.now();
        final expectedDate = DateTime(now.year, now.month, now.day, 12);
        final entryRef = _col('personal_entries').doc();
        txn.set(entryRef, {
          'type': 'expense',
          'description': 'Pagamento de divida pessoal: $title',
          'category': debtCategory,
          'amount': amount,
          'origin': 'personal_debt_payment',
          'expectedDate': expectedDate,
          'recurrence': PersonalEntryRecurrence.once.name,
          'remindersEnabled': false,
          'createdAt': now,
        });
      });
      return null;
    } on StateError catch (error) {
      return error.message;
    } catch (_) {
      return 'Falha ao registrar pagamento da divida.';
    }
  }

  Future<String?> deletePersonalDebt({required String debtId}) async {
    try {
      await _col('personal_debts').doc(debtId).delete();
      return null;
    } catch (_) {
      return 'Falha ao excluir divida.';
    }
  }

  List<PersonalDebtReminder> upcomingPersonalDebtAlerts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alerts = <PersonalDebtReminder>[];

    for (final debt in _personalDebts) {
      if (debt.openAmount <= 0) continue;
      if (!debt.reminderEnabled || debt.dueDate == null) continue;
      final due = DateTime(
        debt.dueDate!.year,
        debt.dueDate!.month,
        debt.dueDate!.day,
      );
      final daysUntil = due.difference(today).inDays;
      if (daysUntil > _personalDebtReminderDays) continue;
      alerts.add(PersonalDebtReminder(debt: debt, daysUntilDue: daysUntil));
    }

    alerts.sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
    return alerts;
  }

  List<DebtPriorityInsight> personalDebtInsights({int limit = 3}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final insights = <DebtPriorityInsight>[];

    for (final debt in _personalDebts) {
      if (debt.openAmount <= 0) continue;
      final score = _personalDebtScore(debt, today);
      final reason = _personalDebtReason(debt, today);
      insights.add(
        DebtPriorityInsight(debt: debt, score: score, reason: reason),
      );
    }

    insights.sort((a, b) => b.score.compareTo(a.score));
    if (insights.length <= limit) return insights;
    return insights.take(limit).toList();
  }

  int _personalDebtScore(PersonalDebtRecord debt, DateTime today) {
    var score = 0;

    if (debt.dueDate != null) {
      final due = DateTime(
        debt.dueDate!.year,
        debt.dueDate!.month,
        debt.dueDate!.day,
      );
      final daysUntil = due.difference(today).inDays;
      if (daysUntil < 0) {
        final overdueDays = -daysUntil;
        score += 100 + (overdueDays > 20 ? 20 : overdueDays);
      } else if (daysUntil == 0) {
        score += 92;
      } else if (daysUntil <= 3) {
        score += 80 - (daysUntil * 5);
      } else if (daysUntil <= 7) {
        score += 60 - (daysUntil * 3);
      } else if (daysUntil <= 15) {
        score += 40;
      } else {
        score += 20;
      }
    } else {
      score += 18;
    }

    if (debt.openAmount >= 1000) {
      score += 45;
    } else if (debt.openAmount >= 500) {
      score += 30;
    } else if (debt.openAmount >= 200) {
      score += 20;
    } else if (debt.openAmount >= 100) {
      score += 12;
    } else {
      score += 6;
    }

    if (debt.reminderEnabled) {
      score += 5;
    }

    return score;
  }

  String _personalDebtReason(PersonalDebtRecord debt, DateTime today) {
    final value = AppFormatters.currency(debt.openAmount);
    if (debt.dueDate == null) {
      return 'Sem data definida | saldo $value';
    }

    final due = DateTime(
      debt.dueDate!.year,
      debt.dueDate!.month,
      debt.dueDate!.day,
    );
    final daysUntil = due.difference(today).inDays;
    if (daysUntil < 0) {
      return 'Atrasada ha ${-daysUntil} dia(s) | saldo $value';
    }
    if (daysUntil == 0) {
      return 'Vence hoje | saldo $value';
    }
    return 'Vence em $daysUntil dia(s) | saldo $value';
  }

  Future<void> addLoan({
    required String customerName,
    required double principal,
    required DateTime dueDate,
    required double interestRate,
    required LoanInterestUnit interestUnit,
  }) {
    return _col('loans').add({
      'customerName': customerName,
      'principal': principal,
      'paidAmount': 0,
      'dueDate': dueDate,
      'interestRate': interestRate,
      'interestUnit': interestUnit.name,
      'createdAt': DateTime.now(),
    });
  }

  Future<String?> payLoan({
    required String loanId,
    required double amount,
  }) async {
    if (amount <= 0) return 'Valor de pagamento invalido.';

    try {
      await _db.runTransaction((txn) async {
        final loanRef = _col('loans').doc(loanId);
        final loanSnap = await txn.get(loanRef);
        if (!loanSnap.exists) {
          throw StateError('Emprestimo nao encontrado.');
        }

        final loan = LoanRecord.fromDoc(loanSnap);
        final open = getLoanOpenAmount(loan);
        if (amount > open) {
          throw StateError('Pagamento maior que saldo do emprestimo.');
        }

        txn.update(loanRef, {'paidAmount': loan.paidAmount + amount});
        final entryRef = _col('financial_entries').doc();
        txn.set(entryRef, {
          'type': 'revenue',
          'description': 'Pagamento de emprestimo: ${loan.customerName}',
          'category': 'Recebimentos',
          'amount': amount,
          'origin': 'loan_payment',
          'createdAt': DateTime.now(),
        });
      });
      return null;
    } on StateError catch (error) {
      return error.message;
    } catch (_) {
      return 'Falha ao registrar pagamento de emprestimo.';
    }
  }

  Future<String?> cancelSale({required SaleRecord sale}) async {
    try {
      // Primeiro, buscar informações necessárias FORA da transação
      final saleRef = _col('sales').doc(sale.id);
      final saleSnap = await saleRef.get();

      if (!saleSnap.exists) {
        return 'Venda nao encontrada.';
      }

      final data = saleSnap.data() ?? <String, dynamic>{};
      final mode = (data['mode'] ?? 'free').toString();
      final paymentMethod = (data['paymentMethod'] ?? '').toString();
      final productId = data['productId']?.toString();
      final quantity = _toDouble(data['quantity']);
      final debtId = data['debtId']?.toString();
      final loanId = data['loanId']?.toString();
      final financialEntryId = data['financialEntryId']?.toString();
      final lotBreakdownRaw = data['lotBreakdown'];
      final saleDescription = (data['description'] ?? '').toString();
      final saleTotal = _toDouble(data['total']);

      // Validações antes da transação
      if (mode == 'product' && lotBreakdownRaw is List) {
        for (final rawLot in lotBreakdownRaw) {
          if (rawLot is! Map) continue;
          final lotProductId = rawLot['productId']?.toString();
          if (lotProductId == null || lotProductId.isEmpty) continue;
          final productSnap = await _col('products').doc(lotProductId).get();
          if (!productSnap.exists) {
            return 'Nao foi possivel cancelar: lote original nao encontrado.';
          }
        }
      } else if (mode == 'product' &&
          productId != null &&
          productId.isNotEmpty) {
        final productSnap = await _col('products').doc(productId).get();
        if (!productSnap.exists) {
          return 'Nao foi possivel cancelar: produto original nao encontrado.';
        }
      }

      if (paymentMethod == 'fiado' && debtId != null && debtId.isNotEmpty) {
        final debtSnap = await _col('debts').doc(debtId).get();
        if (debtSnap.exists) {
          final debtData = debtSnap.data() ?? <String, dynamic>{};
          final originalAmount = _toDouble(debtData['originalAmount']);
          final openAmount = _toDouble(debtData['openAmount']);
          if (openAmount < originalAmount) {
            return 'Nao e possivel cancelar: este fiado ja recebeu pagamento.';
          }
        }
      }

      if (paymentMethod == 'emprestimo' &&
          loanId != null &&
          loanId.isNotEmpty) {
        final loanSnap = await _col('loans').doc(loanId).get();
        if (loanSnap.exists) {
          final loanData = loanSnap.data() ?? <String, dynamic>{};
          final paidAmount = _toDouble(loanData['paidAmount']);
          if (paidAmount > 0) {
            return 'Nao e possivel cancelar: este emprestimo ja recebeu pagamento.';
          }
        }
      }

      // Agora executar as operações em batch (mais simples que transação)
      final batch = _db.batch();

      // Restaurar estoque se necessário
      if (mode == 'product' && lotBreakdownRaw is List) {
        for (final rawLot in lotBreakdownRaw) {
          if (rawLot is! Map) continue;
          final lotProductId = rawLot['productId']?.toString();
          final lotQuantity = _toDouble(rawLot['quantity']);
          if (lotProductId == null ||
              lotProductId.isEmpty ||
              lotQuantity <= 0) {
            continue;
          }
          final productRef = _col('products').doc(lotProductId);
          final productSnap = await productRef.get();
          if (productSnap.exists) {
            final productData = productSnap.data() ?? <String, dynamic>{};
            final currentStock = _toDouble(productData['stock']);
            batch.update(productRef, {'stock': currentStock + lotQuantity});
          }
        }
      } else if (mode == 'product' &&
          productId != null &&
          productId.isNotEmpty &&
          quantity > 0) {
        final productRef = _col('products').doc(productId);
        final productSnap = await productRef.get();
        if (productSnap.exists) {
          final productData = productSnap.data() ?? <String, dynamic>{};
          final currentStock = _toDouble(productData['stock']);
          batch.update(productRef, {'stock': currentStock + quantity});
        }
      }

      // Deletar dívida se necessário
      if (paymentMethod == 'fiado' && debtId != null && debtId.isNotEmpty) {
        batch.delete(_col('debts').doc(debtId));
      }

      // Deletar empréstimo se necessário
      if (paymentMethod == 'emprestimo' &&
          loanId != null &&
          loanId.isNotEmpty) {
        batch.delete(_col('loans').doc(loanId));
      }

      // Deletar entrada financeira se necessário
      if (paymentMethod != 'fiado' &&
          financialEntryId != null &&
          financialEntryId.isNotEmpty) {
        batch.delete(_col('financial_entries').doc(financialEntryId));
      }

      // Se não tem financialEntryId, criar estorno
      if (paymentMethod != 'fiado' &&
          (financialEntryId == null || financialEntryId.isEmpty)) {
        final reversalRef = _col('financial_entries').doc();
        batch.set(reversalRef, {
          'type': 'expense',
          'description': 'Estorno de venda cancelada: $saleDescription',
          'category': 'Operacional',
          'amount': saleTotal,
          'origin': 'sale_cancel_reversal',
          'saleId': sale.id,
          'createdAt': DateTime.now(),
        });
      }

      // Deletar a venda
      batch.delete(saleRef);

      // Executar batch
      await batch.commit();

      return null;
    } on StateError catch (error) {
      debugPrint(
        'Erro de regra ao cancelar venda ${sale.id}: ${error.message}',
      );
      return error.message;
    } on FirebaseException catch (error) {
      debugPrint(
        'Erro Firebase ao cancelar venda ${sale.id}: ${error.code} ${error.message}',
      );
      return error.message ?? 'Falha de permissao/Firestore ao cancelar venda.';
    } catch (error, stackTrace) {
      debugPrint('Falha inesperada ao cancelar venda ${sale.id}: $error');
      debugPrint('$stackTrace');
      return 'Falha ao cancelar venda: $error';
    }
  }

  double getLoanOpenAmount(LoanRecord loan) {
    final now = DateTime.now();
    final due = DateTime(
      loan.dueDate.year,
      loan.dueDate.month,
      loan.dueDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    var withInterest = loan.principal;

    if (today.isAfter(due)) {
      if (loan.interestUnit == LoanInterestUnit.day) {
        final days = today.difference(due).inDays;
        withInterest += loan.principal * (loan.interestRate / 100) * days;
      } else {
        final months = (today.year - due.year) * 12 + (today.month - due.month);
        final effectiveMonths = months <= 0 ? 1 : months;
        withInterest +=
            loan.principal * (loan.interestRate / 100) * effectiveMonths;
      }
    }

    final open = withInterest - loan.paidAmount;
    return open <= 0 ? 0 : open;
  }

  List<LoanDueAlert> upcomingLoanAlerts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alerts = <LoanDueAlert>[];

    for (final loan in _loans) {
      final due = DateTime(
        loan.dueDate.year,
        loan.dueDate.month,
        loan.dueDate.day,
      );
      final daysUntil = due.difference(today).inDays;
      if (daysUntil < 0 || daysUntil > _loanAlertDays) continue;
      final open = getLoanOpenAmount(loan);
      if (open <= 0) continue;
      alerts.add(
        LoanDueAlert(loan: loan, daysUntilDue: daysUntil, openAmount: open),
      );
    }

    alerts.sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
    return alerts;
  }

  List<FinancialEntry> financialEntriesForPeriod(FinancialPeriod period) {
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day);
    late final DateTime start;

    switch (period) {
      case FinancialPeriod.day:
        start = startDay;
      case FinancialPeriod.week:
        start = startDay.subtract(Duration(days: startDay.weekday - 1));
      case FinancialPeriod.month:
        start = DateTime(now.year, now.month, 1);
    }

    return _financialEntries
        .where((entry) => !entry.createdAt.isBefore(start))
        .toList();
  }

  Future<void> addExpense({
    required String description,
    required double amount,
    required bool isStock,
    String? category,
  }) {
    final now = DateTime.now();
    return _col('financial_entries').add({
      'type': isStock ? 'stock' : 'expense',
      'description': description.trim(),
      'category': category?.trim() ?? (isStock ? 'Estoque' : 'Operacional'),
      'amount': amount,
      'origin': isStock ? 'stock' : 'expense',
      'createdAt': now,
    });
  }

  Map<String, dynamic> getReportForPeriod(FinancialPeriod period) {
    final entries = financialEntriesForPeriod(period);
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day);
    late final DateTime start;

    switch (period) {
      case FinancialPeriod.day:
        start = startDay;
      case FinancialPeriod.week:
        start = startDay.subtract(Duration(days: startDay.weekday - 1));
      case FinancialPeriod.month:
        start = DateTime(now.year, now.month, 1);
    }

    final salesInPeriod = _sales
        .where((s) => !s.createdAt.isBefore(start))
        .toList();

    final revenue = entries
        .where((e) => e.type == FinancialEntryType.revenue)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final operationalExpenses = entries
        .where((e) => e.type == FinancialEntryType.expense)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final stockExpenses = entries
        .where((e) => e.type == FinancialEntryType.stock)
        .fold<double>(0, (sum, e) => sum + e.amount);

    // Calcular CPV (Custo dos Produtos Vendidos)
    double cpv = 0;
    for (final sale in salesInPeriod.where((s) => s.mode == SaleMode.product)) {
      final product = _products
          .where((p) => p.id == sale.productId || p.name == sale.productName)
          .firstOrNull;
      if (product != null && sale.quantity != null) {
        cpv += product.cost * sale.quantity!;
      }
    }

    final grossProfit = revenue - cpv;
    final netProfit = grossProfit - operationalExpenses;
    final margin = revenue > 0 ? (netProfit / revenue) * 100 : 0;

    final avgTicket = salesInPeriod.isNotEmpty
        ? revenue / salesInPeriod.length
        : 0.0;

    // Produto mais vendido
    final productSales = <String, int>{};
    for (final sale in salesInPeriod.where((s) => s.productName != null)) {
      final productName = sale.productName!;
      productSales[productName] = (productSales[productName] ?? 0) + 1;
    }

    String? topProduct;
    int maxSales = 0;
    productSales.forEach((name, count) {
      if (count > maxSales) {
        maxSales = count;
        topProduct = name;
      }
    });

    final brandRevenue = <String, double>{};
    final brandCommission = <String, double>{};
    double totalCommission = 0;
    for (final sale in salesInPeriod.where((s) => s.mode == SaleMode.product)) {
      final brandName = (sale.brandName ?? '').trim();
      if (brandName.isEmpty) continue;
      brandRevenue[brandName] = (brandRevenue[brandName] ?? 0) + sale.total;
      final commissionValue =
          sale.commissionAmount ??
          (sale.commissionPercent == null
              ? 0
              : sale.total * (sale.commissionPercent! / 100));
      brandCommission[brandName] =
          (brandCommission[brandName] ?? 0) + commissionValue;
      totalCommission += commissionValue;
    }

    String? topBrand;
    double topBrandRevenue = 0;
    brandRevenue.forEach((name, amount) {
      if (amount > topBrandRevenue) {
        topBrandRevenue = amount;
        topBrand = name;
      }
    });
    final topBrandCommission = topBrand == null
        ? 0.0
        : (brandCommission[topBrand] ?? 0.0);

    // Maior despesa
    final expensesByDesc = <String, double>{};
    for (final entry in entries.where(
      (e) => e.type == FinancialEntryType.expense,
    )) {
      expensesByDesc[entry.description] =
          (expensesByDesc[entry.description] ?? 0) + entry.amount;
    }

    String? topExpense;
    double maxExpenseAmount = 0;
    expensesByDesc.forEach((desc, amount) {
      if (amount > maxExpenseAmount) {
        maxExpenseAmount = amount;
        topExpense = desc;
      }
    });

    return {
      'revenue': revenue,
      'operationalExpenses': operationalExpenses,
      'stockExpenses': stockExpenses,
      'cpv': cpv,
      'grossProfit': grossProfit,
      'netProfit': netProfit,
      'margin': margin,
      'avgTicket': avgTicket,
      'salesCount': salesInPeriod.length,
      'topProduct': topProduct,
      'topProductCount': maxSales,
      'topBrand': topBrand,
      'topBrandRevenue': topBrandRevenue,
      'topBrandCommission': topBrandCommission,
      'totalCommission': totalCommission,
      'totalBrandsSold': brandRevenue.length,
      'topExpense': topExpense,
      'topExpenseAmount': maxExpenseAmount,
    };
  }

  Map<String, dynamic> getProductAgingReport({
    int stagnantDays = 90,
    int oldStockDays = 180,
  }) {
    final now = DateTime.now();
    final stagnantCutoff = now.subtract(Duration(days: stagnantDays));
    final oldStockCutoff = now.subtract(Duration(days: oldStockDays));
    final lastSaleByProductId = <String, DateTime>{};
    final lastSaleByProductName = <String, DateTime>{};

    for (final sale in _sales.where((sale) => sale.mode == SaleMode.product)) {
      final productId = sale.productId;
      if (productId != null && productId.isNotEmpty) {
        final previous = lastSaleByProductId[productId];
        if (previous == null || sale.createdAt.isAfter(previous)) {
          lastSaleByProductId[productId] = sale.createdAt;
        }
      }

      final productName = (sale.productName ?? '').trim().toLowerCase();
      if (productName.isNotEmpty) {
        final previous = lastSaleByProductName[productName];
        if (previous == null || sale.createdAt.isAfter(previous)) {
          lastSaleByProductName[productName] = sale.createdAt;
        }
      }
    }

    DateTime? lastSaleFor(ProductRecord product) {
      final byId = lastSaleByProductId[product.id];
      if (byId != null) return byId;
      return lastSaleByProductName[product.name.trim().toLowerCase()];
    }

    final productsWithStock = _products
        .where((product) => product.stock > 0)
        .toList();
    final noSales = <ProductRecord>[];
    final stagnant = <ProductRecord>[];
    final oldStock = <ProductRecord>[];
    final pausedIds = <String>{};

    for (final product in productsWithStock) {
      final lastSale = lastSaleFor(product);
      if (lastSale == null) {
        noSales.add(product);
        pausedIds.add(product.id);
      }

      final isStagnant = lastSale == null
          ? product.createdAt.isBefore(stagnantCutoff)
          : lastSale.isBefore(stagnantCutoff);
      if (isStagnant) {
        stagnant.add(product);
        pausedIds.add(product.id);
      }

      final isOldStock =
          product.situation.isOldInventory ||
          product.createdAt.isBefore(oldStockCutoff);
      if (isOldStock) {
        oldStock.add(product);
        pausedIds.add(product.id);
      }
    }

    final pausedValue = productsWithStock
        .where((product) => pausedIds.contains(product.id))
        .fold<double>(
          0,
          (sum, product) => sum + (product.cost * product.stock),
        );

    return {
      'stagnantProducts': stagnant,
      'stagnantProductsCount': stagnant.length,
      'oldStockProducts': oldStock,
      'oldStockCount': oldStock.length,
      'noSalesProducts': noSales,
      'noSalesCount': noSales.length,
      'pausedValue': pausedValue,
      'stagnantDays': stagnantDays,
      'oldStockDays': oldStockDays,
    };
  }

  DateTime _periodStart(FinancialPeriod period, DateTime now) {
    final startDay = DateTime(now.year, now.month, now.day);
    switch (period) {
      case FinancialPeriod.day:
        return startDay;
      case FinancialPeriod.week:
        return startDay.subtract(Duration(days: startDay.weekday - 1));
      case FinancialPeriod.month:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime _periodEnd(FinancialPeriod period, DateTime now) {
    final startDay = DateTime(now.year, now.month, now.day);
    switch (period) {
      case FinancialPeriod.day:
        return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      case FinancialPeriod.week:
        final weekStart = startDay.subtract(
          Duration(days: startDay.weekday - 1),
        );
        return DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 6,
          23,
          59,
          59,
          999,
        );
      case FinancialPeriod.month:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    }
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime? _personalEntryOccurrenceInRange(
    PersonalFinanceEntry entry, {
    required DateTime start,
    required DateTime end,
  }) {
    final baseDate = _startOfDay(entry.expectedDate ?? entry.createdAt);

    if (entry.recurrence == PersonalEntryRecurrence.once) {
      if (baseDate.isBefore(start) || baseDate.isAfter(end)) return null;
      return baseDate;
    }

    var monthCursor = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);
    while (!monthCursor.isAfter(endMonth)) {
      final occurrence = _monthlyOccurrenceForMonth(
        baseDate,
        monthCursor.year,
        monthCursor.month,
      );
      if (!occurrence.isBefore(baseDate) &&
          !occurrence.isBefore(start) &&
          !occurrence.isAfter(end)) {
        return occurrence;
      }
      monthCursor = DateTime(monthCursor.year, monthCursor.month + 1, 1);
    }
    return null;
  }

  DateTime _monthlyOccurrenceForMonth(DateTime baseDate, int year, int month) {
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final targetDay = baseDate.day <= lastDayOfMonth
        ? baseDate.day
        : lastDayOfMonth;
    return DateTime(year, month, targetDay);
  }

  Future<void> deleteAllTransactions() async {
    try {
      final batch = _db.batch();

      // Delete sales
      final salesSnap = await _col('sales').get();
      for (final doc in salesSnap.docs) {
        batch.delete(doc.reference);
      }

      // Delete financial entries
      final financialSnap = await _col('financial_entries').get();
      for (final doc in financialSnap.docs) {
        batch.delete(doc.reference);
      }

      // Delete debts (fiados)
      final debtsSnap = await _col('debts').get();
      for (final doc in debtsSnap.docs) {
        batch.delete(doc.reference);
      }

      // Delete debt payments
      final debtPaymentsSnap = await _col('debt_payments').get();
      for (final doc in debtPaymentsSnap.docs) {
        batch.delete(doc.reference);
      }

      // Delete loans
      final loansSnap = await _col('loans').get();
      for (final doc in loansSnap.docs) {
        batch.delete(doc.reference);
      }

      // Delete loan payments
      final loanPaymentsSnap = await _col('loan_payments').get();
      for (final doc in loanPaymentsSnap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (error) {
      debugPrint('Erro ao apagar transacoes: $error');
      rethrow;
    }
  }

  Future<void> deleteAllData() async {
    try {
      // Delete transactions first
      await deleteAllTransactions();

      final batch = _db.batch();

      // Delete customers
      final customersSnap = await _col('customers').get();
      for (final doc in customersSnap.docs) {
        batch.delete(doc.reference);
      }

      // Delete products
      final productsSnap = await _col('products').get();
      for (final doc in productsSnap.docs) {
        batch.delete(doc.reference);
      }

      // Delete brands
      final brandsSnap = await _col('brands').get();
      for (final doc in brandsSnap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (error) {
      debugPrint('Erro ao apagar todos os dados: $error');
      rethrow;
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

enum SaleMode { free, product }

enum FinancialEntryType { revenue, expense, stock }

enum PersonalEntryRecurrence { once, monthly }

enum LoanInterestUnit { day, month }

enum FinancialPeriod { day, week, month }

enum ProductSituation {
  newRelease,
  current,
  old,
  promotion,
  clearance,
  discontinued,
}

extension ProductSituationLabels on ProductSituation {
  String get firestoreKey {
    switch (this) {
      case ProductSituation.newRelease:
        return 'new_release';
      case ProductSituation.current:
        return 'current';
      case ProductSituation.old:
        return 'old';
      case ProductSituation.promotion:
        return 'promotion';
      case ProductSituation.clearance:
        return 'clearance';
      case ProductSituation.discontinued:
        return 'discontinued';
    }
  }

  String get label {
    switch (this) {
      case ProductSituation.newRelease:
        return 'Novo lancamento';
      case ProductSituation.current:
        return 'Atual';
      case ProductSituation.old:
        return 'Antigo';
      case ProductSituation.promotion:
        return 'Promocao';
      case ProductSituation.clearance:
        return 'Queima de estoque';
      case ProductSituation.discontinued:
        return 'Fora de linha';
    }
  }

  bool get isOldInventory {
    return this == ProductSituation.old ||
        this == ProductSituation.clearance ||
        this == ProductSituation.discontinued;
  }

  bool get canUseAutomaticDiscount {
    return isOldInventory || this == ProductSituation.promotion;
  }
}

DateTime _dateFrom(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}

DateTime? _nullableDateFrom(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

double _normalizeDiscountPercent(double value) {
  if (value <= 0) return 0;
  if (value > 90) return 90;
  return value;
}

ProductSituation _productSituationFrom(dynamic value) {
  final raw = (value ?? '').toString().trim().toLowerCase();
  switch (raw) {
    case 'new_release':
    case 'novo_lancamento':
    case 'novo lancamento':
    case 'novo':
      return ProductSituation.newRelease;
    case 'old':
    case 'antigo':
    case 'antiga':
      return ProductSituation.old;
    case 'promotion':
    case 'promocao':
    case 'promo':
      return ProductSituation.promotion;
    case 'clearance':
    case 'queima':
    case 'queima_de_estoque':
    case 'queima de estoque':
      return ProductSituation.clearance;
    case 'discontinued':
    case 'fora_de_linha':
    case 'fora de linha':
      return ProductSituation.discontinued;
    case 'current':
    case 'atual':
    default:
      return ProductSituation.current;
  }
}

String _defaultFinancialCategoryForOrigin({
  required String origin,
  required FinancialEntryType type,
}) {
  switch (origin) {
    case 'sale':
      return 'Vendas';
    case 'fiado_payment':
    case 'loan_payment':
      return 'Recebimentos';
    case 'stock':
    case 'stock_adjustment':
    case 'stock_delete':
      return 'Estoque';
    case 'personal_debt_payment':
      return 'Despesas pessoais';
    case 'sale_cancel_reversal':
      return 'Operacional';
    default:
      return type == FinancialEntryType.revenue
          ? 'Outras receitas'
          : 'Outras despesas';
  }
}

class SaleRecord {
  SaleRecord({
    required this.id,
    required this.description,
    required this.total,
    required this.mode,
    required this.paymentMethod,
    this.customerName,
    this.productName,
    this.productId,
    this.quantity,
    this.brandId,
    this.brandName,
    this.commissionPercent,
    this.commissionAmount,
    this.debtId,
    this.loanId,
    this.financialEntryId,
    required this.createdAt,
  });

  final String id;
  final String description;
  final double total;
  final SaleMode mode;
  final String paymentMethod;
  final String? customerName;
  final String? productName;
  final String? productId;
  final double? quantity;
  final String? brandId;
  final String? brandName;
  final double? commissionPercent;
  final double? commissionAmount;
  final String? debtId;
  final String? loanId;
  final String? financialEntryId;
  final DateTime createdAt;

  factory SaleRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final modeRaw = (data['mode'] ?? 'free').toString();
    return SaleRecord(
      id: doc.id,
      description: (data['description'] ?? '').toString(),
      total: (data['total'] as num?)?.toDouble() ?? 0,
      mode: modeRaw == 'product' ? SaleMode.product : SaleMode.free,
      paymentMethod: (data['paymentMethod'] ?? 'outros').toString(),
      customerName: data['customerName']?.toString(),
      productName: data['productName']?.toString(),
      productId: data['productId']?.toString(),
      quantity: (data['quantity'] as num?)?.toDouble(),
      brandId: data['brandId']?.toString(),
      brandName: data['brandName']?.toString(),
      commissionPercent: (data['commissionPercent'] as num?)?.toDouble(),
      commissionAmount: (data['commissionAmount'] as num?)?.toDouble(),
      debtId: data['debtId']?.toString(),
      loanId: data['loanId']?.toString(),
      financialEntryId: data['financialEntryId']?.toString(),
      createdAt: _dateFrom(data['createdAt']),
    );
  }
}

class BrandRecord {
  BrandRecord({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.defaultCommissionPercent,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String logoUrl;
  final double defaultCommissionPercent;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BrandRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BrandRecord(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      logoUrl: (data['logoUrl'] ?? '').toString(),
      defaultCommissionPercent:
          (data['defaultCommissionPercent'] as num?)?.toDouble() ?? 0,
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: _dateFrom(data['createdAt']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }
}

class LoanDueAlert {
  LoanDueAlert({
    required this.loan,
    required this.daysUntilDue,
    required this.openAmount,
  });

  final LoanRecord loan;
  final int daysUntilDue;
  final double openAmount;
}

class PersonalDebtReminder {
  PersonalDebtReminder({required this.debt, required this.daysUntilDue});

  final PersonalDebtRecord debt;
  final int daysUntilDue;
}

class DebtPriorityInsight {
  DebtPriorityInsight({
    required this.debt,
    required this.score,
    required this.reason,
  });

  final PersonalDebtRecord debt;
  final int score;
  final String reason;
}

class CustomerRecord {
  CustomerRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final bool isActive;
  final DateTime createdAt;

  factory CustomerRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CustomerRecord(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: _dateFrom(data['createdAt']),
    );
  }
}

enum CustomerRemovalOutcome { deleted, inactivated }

class ProductRecord {
  ProductRecord({
    required this.id,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.brandId,
    required this.brandName,
    required this.description,
    required this.sizeLabel,
    required this.variation,
    required this.salePrice,
    required this.cost,
    required this.commissionPercent,
    required this.hasCustomCommission,
    required this.situation,
    required this.automaticDiscountPercent,
    required this.stock,
    required this.stockMinimum,
    required this.expiryDate,
    required this.batchCode,
    required this.storageLocation,
    required this.unit,
    required this.showInWeb,
    required this.userId,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String sku;
  final String barcode;
  final String category;
  final String brandId;
  final String brandName;
  final String description;
  final String sizeLabel;
  final String variation;
  final double salePrice;
  final double cost;
  final double commissionPercent;
  final bool hasCustomCommission;
  final ProductSituation situation;
  final double automaticDiscountPercent;
  final double stock;
  final double stockMinimum;
  final DateTime? expiryDate;
  final String batchCode;
  final String storageLocation;
  final String unit;
  final bool showInWeb;
  final String userId;
  final String imageUrl;
  final String thumbnailUrl;
  final String notes;
  final DateTime createdAt;

  double get estimatedProfitPerUnit {
    return effectiveSalePrice -
        cost -
        (effectiveSalePrice * (commissionPercent / 100));
  }

  double get effectiveSalePrice {
    return salePrice - automaticDiscountAmount;
  }

  double get automaticDiscountAmount {
    if (!hasAutomaticDiscount) return 0;
    return salePrice *
        (_normalizeDiscountPercent(automaticDiscountPercent) / 100);
  }

  bool get hasAutomaticDiscount {
    return situation.canUseAutomaticDiscount && automaticDiscountPercent > 0;
  }

  bool get isLowStock {
    return stockMinimum > 0 && stock <= stockMinimum;
  }

  bool get isExpired {
    final due = expiryDate;
    if (due == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(due.year, due.month, due.day);
    return target.isBefore(today);
  }

  bool isExpiringWithin(int days) {
    final due = expiryDate;
    if (due == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(due.year, due.month, due.day);
    if (target.isBefore(today)) return false;
    return target.difference(today).inDays <= days;
  }

  factory ProductRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ProductRecord(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      sku: (data['sku'] ?? '').toString(),
      barcode: (data['barcode'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      brandId: (data['brandId'] ?? '').toString(),
      brandName: (data['brandName'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      sizeLabel: (data['sizeLabel'] ?? '').toString(),
      variation: (data['variation'] ?? '').toString(),
      salePrice: (data['salePrice'] as num?)?.toDouble() ?? 0,
      cost: (data['cost'] as num?)?.toDouble() ?? 0,
      commissionPercent: (data['commissionPercent'] as num?)?.toDouble() ?? 0,
      hasCustomCommission: (data['hasCustomCommission'] as bool?) ?? false,
      situation: _productSituationFrom(data['situation']),
      automaticDiscountPercent:
          (data['automaticDiscountPercent'] as num?)?.toDouble() ?? 0,
      stock: (data['stock'] as num?)?.toDouble() ?? 0,
      stockMinimum: (data['stockMinimum'] as num?)?.toDouble() ?? 0,
      expiryDate: _nullableDateFrom(data['expiryDate']),
      batchCode: (data['batch'] ?? '').toString(),
      storageLocation: (data['storageLocation'] ?? '').toString(),
      unit: (data['unit'] ?? 'un').toString(),
      showInWeb: (data['showInWeb'] as bool?) ?? false,
      userId: (data['userId'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      thumbnailUrl: (data['thumbnailUrl'] ?? '').toString(),
      notes: (data['notes'] ?? '').toString(),
      createdAt: _dateFrom(data['createdAt']),
    );
  }
}

class DebtRecord {
  DebtRecord({
    required this.id,
    required this.customerName,
    required this.description,
    required this.category,
    required this.originalAmount,
    required this.openAmount,
    required this.createdAt,
  });

  final String id;
  final String customerName;
  final String description;
  final String category;
  final double originalAmount;
  final double openAmount;
  final DateTime createdAt;

  factory DebtRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return DebtRecord(
      id: doc.id,
      customerName: (data['customerName'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? 'Outras dividas').toString(),
      originalAmount: (data['originalAmount'] as num?)?.toDouble() ?? 0,
      openAmount: (data['openAmount'] as num?)?.toDouble() ?? 0,
      createdAt: _dateFrom(data['createdAt']),
    );
  }
}

class PersonalDebtRecord {
  PersonalDebtRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.note,
    required this.originalAmount,
    required this.openAmount,
    required this.reminderEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
  });

  final String id;
  final String title;
  final String category;
  final String note;
  final double originalAmount;
  final double openAmount;
  final DateTime? dueDate;
  final bool reminderEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PersonalDebtRecord.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PersonalDebtRecord(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      category: (data['category'] ?? 'Outras dividas').toString(),
      note: (data['note'] ?? '').toString(),
      originalAmount: (data['originalAmount'] as num?)?.toDouble() ?? 0,
      openAmount: (data['openAmount'] as num?)?.toDouble() ?? 0,
      dueDate: _nullableDateFrom(data['dueDate']),
      reminderEnabled: (data['reminderEnabled'] as bool?) ?? true,
      createdAt: _dateFrom(data['createdAt']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }
}

class LoanRecord {
  LoanRecord({
    required this.id,
    required this.customerName,
    required this.principal,
    required this.paidAmount,
    required this.dueDate,
    required this.interestRate,
    required this.interestUnit,
    required this.createdAt,
  });

  final String id;
  final String customerName;
  final double principal;
  final double paidAmount;
  final DateTime dueDate;
  final double interestRate;
  final LoanInterestUnit interestUnit;
  final DateTime createdAt;

  factory LoanRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final interestUnit = (data['interestUnit'] ?? 'month').toString() == 'day'
        ? LoanInterestUnit.day
        : LoanInterestUnit.month;
    return LoanRecord(
      id: doc.id,
      customerName: (data['customerName'] ?? '').toString(),
      principal: (data['principal'] as num?)?.toDouble() ?? 0,
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0,
      dueDate: _dateFrom(data['dueDate']),
      interestRate: (data['interestRate'] as num?)?.toDouble() ?? 0,
      interestUnit: interestUnit,
      createdAt: _dateFrom(data['createdAt']),
    );
  }
}

class FinancialEntry {
  FinancialEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.category,
    required this.amount,
    required this.createdAt,
    required this.origin,
  });

  final String id;
  final FinancialEntryType type;
  final String description;
  final String category;
  final double amount;
  final DateTime createdAt;
  final String origin;

  factory FinancialEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final type = (data['type'] ?? 'expense').toString() == 'revenue'
        ? FinancialEntryType.revenue
        : FinancialEntryType.expense;
    return FinancialEntry(
      id: doc.id,
      type: type,
      description: (data['description'] ?? '').toString(),
      category:
          (data['category'] ??
                  _defaultFinancialCategoryForOrigin(
                    origin: (data['origin'] ?? '').toString(),
                    type: type,
                  ))
              .toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      createdAt: _dateFrom(data['createdAt']),
      origin: (data['origin'] ?? '').toString(),
    );
  }
}

class PersonalFinanceEntry {
  PersonalFinanceEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.category,
    required this.amount,
    required this.expectedDate,
    required this.recurrence,
    required this.remindersEnabled,
    required this.lastReminderAt,
    required this.createdAt,
    required this.origin,
  });

  final String id;
  final FinancialEntryType type;
  final String description;
  final String category;
  final double amount;
  final DateTime? expectedDate;
  final PersonalEntryRecurrence recurrence;
  final bool remindersEnabled;
  final DateTime? lastReminderAt;
  final DateTime createdAt;
  final String origin;

  factory PersonalFinanceEntry.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final type = (data['type'] ?? 'expense').toString() == 'revenue'
        ? FinancialEntryType.revenue
        : FinancialEntryType.expense;
    final recurrenceRaw = (data['recurrence'] ?? 'once').toString();
    return PersonalFinanceEntry(
      id: doc.id,
      type: type,
      description: (data['description'] ?? '').toString(),
      category:
          (data['category'] ??
                  _defaultFinancialCategoryForOrigin(
                    origin: (data['origin'] ?? '').toString(),
                    type: type,
                  ))
              .toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      expectedDate: _nullableDateFrom(data['expectedDate']),
      recurrence: recurrenceRaw == 'monthly'
          ? PersonalEntryRecurrence.monthly
          : PersonalEntryRecurrence.once,
      remindersEnabled: (data['remindersEnabled'] as bool?) ?? false,
      lastReminderAt: _nullableDateFrom(data['lastReminderAt']),
      createdAt: _dateFrom(data['createdAt']),
      origin: (data['origin'] ?? '').toString(),
    );
  }
}

class AppStoreScope extends InheritedNotifier<AppStore> {
  const AppStoreScope({super.key, required this.store, required super.child})
    : super(notifier: store);

  final AppStore store;

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStoreScope>();
    if (scope == null) {
      throw FlutterError('AppStoreScope nao encontrado no contexto.');
    }
    return scope.store;
  }
}

class ShopProfile {
  const ShopProfile({
    required this.storeName,
    required this.address,
    required this.phone,
    required this.pixKey,
    required this.storeSlug,
    required this.isActive,
  });

  const ShopProfile.empty()
    : storeName = '',
      address = '',
      phone = '',
      pixKey = '',
      storeSlug = '',
      isActive = true;

  final String storeName;
  final String address;
  final String phone;
  final String pixKey;
  final String storeSlug;
  final bool isActive;

  factory ShopProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ShopProfile(
      storeName: (data['storeName'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      pixKey: (data['pixKey'] ?? '').toString(),
      storeSlug: (data['storeSlug'] ?? '').toString(),
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }
}

String _normalizeSlug(String value) {
  final lowercase = value.trim().toLowerCase();
  final slug = lowercase
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp('-{2,}'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug;
}
