import 'dart:collection';

import 'package:flutter/foundation.dart';

class AppStore extends ChangeNotifier {
  final List<CustomerRecord> _customers = <CustomerRecord>[];
  final List<ProductRecord> _products = <ProductRecord>[];
  final List<SaleRecord> _sales = <SaleRecord>[];
  final List<DebtRecord> _debts = <DebtRecord>[];
  final List<LoanRecord> _loans = <LoanRecord>[];
  final List<FinancialEntry> _financialEntries = <FinancialEntry>[];

  UnmodifiableListView<CustomerRecord> get customers => UnmodifiableListView(_customers);
  UnmodifiableListView<ProductRecord> get products => UnmodifiableListView(_products);
  UnmodifiableListView<SaleRecord> get sales => UnmodifiableListView(_sales);
  UnmodifiableListView<DebtRecord> get debts => UnmodifiableListView(_debts);
  UnmodifiableListView<LoanRecord> get loans => UnmodifiableListView(_loans);
  UnmodifiableListView<FinancialEntry> get financialEntries => UnmodifiableListView(_financialEntries);

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int get todaysSalesCount => _sales.where((s) => _isSameDay(s.createdAt, _today)).length;

  double get todaysSalesTotal => _sales
      .where((s) => _isSameDay(s.createdAt, _today))
      .fold<double>(0, (sum, item) => sum + item.total);

  int get todaysFiadosCount {
    final debtCount = _debts.where((d) => _isSameDay(d.createdAt, _today)).length;
    final loanCount = _loans.where((l) => _isSameDay(l.createdAt, _today)).length;
    return debtCount + loanCount;
  }

  double get todaysFiadosOpenTotal {
    final debtTotal = _debts
        .where((d) => _isSameDay(d.createdAt, _today))
        .fold<double>(0, (sum, d) => sum + d.openAmount);

    final loanTotal = _loans
        .where((l) => _isSameDay(l.createdAt, _today))
        .fold<double>(0, (sum, l) => sum + getLoanOpenAmount(l));

    return debtTotal + loanTotal;
  }

  double get todayRevenue => _financialEntries
      .where((e) => e.type == FinancialEntryType.revenue)
      .where((e) => _isSameDay(e.createdAt, _today))
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get todayExpense => _financialEntries
      .where((e) => e.type == FinancialEntryType.expense || e.type == FinancialEntryType.stock)
      .where((e) => _isSameDay(e.createdAt, _today))
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get todayBalance => todayRevenue - todayExpense;

  double get totalOpenDebts => _debts.fold<double>(0, (sum, d) => sum + d.openAmount);

  double get totalOpenLoans => _loans.fold<double>(0, (sum, l) => sum + getLoanOpenAmount(l));

  void addCustomer({required String name, required String phone}) {
    _customers.insert(
      0,
      CustomerRecord(
        id: _id('cli'),
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addProduct({
    required String name,
    required String category,
    required double salePrice,
    required double cost,
    required double stock,
    required String unit,
  }) {
    _products.insert(
      0,
      ProductRecord(
        id: _id('prd'),
        name: name,
        category: category,
        salePrice: salePrice,
        cost: cost,
        stock: stock,
        unit: unit,
        createdAt: DateTime.now(),
      ),
    );

    if (cost > 0 && stock > 0) {
      _financialEntries.insert(
        0,
        FinancialEntry(
          id: _id('fin'),
          type: FinancialEntryType.stock,
          description: 'Compra de estoque: $name',
          amount: cost * stock,
          createdAt: DateTime.now(),
          origin: 'stock',
        ),
      );
    }

    notifyListeners();
  }

  void registerFreeSale({
    required String description,
    required double total,
    required String paymentMethod,
  }) {
    _sales.insert(
      0,
      SaleRecord(
        id: _id('sale'),
        description: description,
        total: total,
        mode: SaleMode.free,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
      ),
    );

    _financialEntries.insert(
      0,
      FinancialEntry(
        id: _id('fin'),
        type: FinancialEntryType.revenue,
        description: description,
        amount: total,
        createdAt: DateTime.now(),
        origin: 'sale',
      ),
    );

    notifyListeners();
  }

  String? registerProductSale({
    required String productId,
    required double quantity,
    required String paymentMethod,
  }) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return 'Produto nao encontrado.';

    final product = _products[index];
    if (quantity <= 0) return 'Quantidade deve ser maior que zero.';
    if (product.stock < quantity) return 'Estoque insuficiente para a venda.';

    final updated = product.copyWith(stock: product.stock - quantity);
    _products[index] = updated;

    final total = product.salePrice * quantity;
    final desc = 'Venda de ${product.name}';

    _sales.insert(
      0,
      SaleRecord(
        id: _id('sale'),
        description: desc,
        total: total,
        mode: SaleMode.product,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        productId: product.id,
        quantity: quantity,
      ),
    );

    _financialEntries.insert(
      0,
      FinancialEntry(
        id: _id('fin'),
        type: FinancialEntryType.revenue,
        description: desc,
        amount: total,
        createdAt: DateTime.now(),
        origin: 'sale',
      ),
    );

    notifyListeners();
    return null;
  }

  Future<String?> deleteSale(String saleId) async {
    final saleIndex = _sales.indexWhere((s) => s.id == saleId);
    if (saleIndex == -1) return 'Venda nao encontrada.';

    final sale = _sales[saleIndex];

    // Se for venda de produto, devolver o estoque
    if (sale.mode == SaleMode.product && sale.productId != null && sale.quantity != null) {
      final productIndex = _products.indexWhere((p) => p.id == sale.productId);
      if (productIndex != -1) {
        final product = _products[productIndex];
        _products[productIndex] = product.copyWith(
          stock: product.stock + sale.quantity!,
        );
      }
    }

    // Remover a venda
    _sales.removeAt(saleIndex);

    // Remover entrada financeira relacionada
    _financialEntries.removeWhere((e) => 
      e.origin == 'sale' && 
      e.description == sale.description &&
      _isSameDay(e.createdAt, sale.createdAt)
    );

    notifyListeners();
    return null;
  }

  void addDebt({
    required String customerName,
    required String description,
    required double amount,
  }) {
    _debts.insert(
      0,
      DebtRecord(
        id: _id('debt'),
        customerName: customerName,
        description: description,
        originalAmount: amount,
        openAmount: amount,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  String? payDebt({required String debtId, required double amount}) {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index == -1) return 'Divida nao encontrada.';
    if (amount <= 0) return 'Valor de pagamento invalido.';

    final debt = _debts[index];
    if (amount > debt.openAmount) return 'Pagamento maior que saldo da divida.';

    _debts[index] = debt.copyWith(openAmount: debt.openAmount - amount);

    _financialEntries.insert(
      0,
      FinancialEntry(
        id: _id('fin'),
        type: FinancialEntryType.revenue,
        description: 'Pagamento de fiado: ${debt.customerName}',
        amount: amount,
        createdAt: DateTime.now(),
        origin: 'fiado_payment',
      ),
    );

    notifyListeners();
    return null;
  }

  void addLoan({
    required String customerName,
    required double principal,
    required DateTime dueDate,
    required double interestRate,
    required LoanInterestUnit interestUnit,
  }) {
    _loans.insert(
      0,
      LoanRecord(
        id: _id('loan'),
        customerName: customerName,
        principal: principal,
        paidAmount: 0,
        dueDate: dueDate,
        interestRate: interestRate,
        interestUnit: interestUnit,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  String? payLoan({required String loanId, required double amount}) {
    final index = _loans.indexWhere((l) => l.id == loanId);
    if (index == -1) return 'Emprestimo nao encontrado.';
    if (amount <= 0) return 'Valor de pagamento invalido.';

    final loan = _loans[index];
    final open = getLoanOpenAmount(loan);
    if (amount > open) return 'Pagamento maior que saldo do emprestimo.';

    _loans[index] = loan.copyWith(paidAmount: loan.paidAmount + amount);

    _financialEntries.insert(
      0,
      FinancialEntry(
        id: _id('fin'),
        type: FinancialEntryType.revenue,
        description: 'Pagamento de emprestimo: ${loan.customerName}',
        amount: amount,
        createdAt: DateTime.now(),
        origin: 'loan_payment',
      ),
    );

    notifyListeners();
    return null;
  }

  double getLoanOpenAmount(LoanRecord loan) {
    final now = DateTime.now();
    final overdueStart = DateTime(loan.dueDate.year, loan.dueDate.month, loan.dueDate.day);
    final today = DateTime(now.year, now.month, now.day);

    var withInterest = loan.principal;

    if (today.isAfter(overdueStart)) {
      if (loan.interestUnit == LoanInterestUnit.day) {
        final days = today.difference(overdueStart).inDays;
        withInterest += loan.principal * (loan.interestRate / 100) * days;
      } else {
        final months = (today.year - overdueStart.year) * 12 + (today.month - overdueStart.month);
        final effectiveMonths = months <= 0 ? 1 : months;
        withInterest += loan.principal * (loan.interestRate / 100) * effectiveMonths;
      }
    }

    final open = withInterest - loan.paidAmount;
    return open <= 0 ? 0 : open;
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

    return _financialEntries.where((e) => !e.createdAt.isBefore(start)).toList();
  }

  void addExpense({
    required String description,
    required double amount,
    required bool isStock,
  }) {
    _financialEntries.insert(
      0,
      FinancialEntry(
        id: _id('fin'),
        type: isStock ? FinancialEntryType.stock : FinancialEntryType.expense,
        description: description,
        amount: amount,
        createdAt: DateTime.now(),
        origin: isStock ? 'stock' : 'expense',
      ),
    );
    notifyListeners();
  }

  Map<String, dynamic> getReportForPeriod(FinancialPeriod period) {
    final entries = financialEntriesForPeriod(period);
    final salesInPeriod = _sales.where((s) {
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

      return !s.createdAt.isBefore(start);
    }).toList();

    final revenue = entries
        .where((e) => e.type == FinancialEntryType.revenue)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final operationalExpenses = entries
        .where((e) => e.type == FinancialEntryType.expense)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final stockExpenses = entries
        .where((e) => e.type == FinancialEntryType.stock)
        .fold<double>(0, (sum, e) => sum + e.amount);

    double cpv = 0;
    for (final sale in salesInPeriod) {
      final productName = sale.description.replaceFirst('Venda de ', '');
      final product = _products.where((p) => sale.description.contains(p.name)).firstOrNull;
      if (product != null) {
        final quantity = sale.total / product.salePrice;
        cpv += product.cost * quantity;
      }
    }

    final grossProfit = revenue - cpv;
    final netProfit = grossProfit - operationalExpenses;
    final margin = revenue > 0 ? (netProfit / revenue) * 100 : 0;

    final avgTicket = salesInPeriod.isNotEmpty 
        ? revenue / salesInPeriod.length 
        : 0;

    final productSales = <String, int>{};
    for (final sale in salesInPeriod) {
      final productName = sale.description.replaceFirst('Venda de ', '');
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

    final expensesByDesc = <String, double>{};
    for (final entry in entries.where((e) => e.type == FinancialEntryType.expense)) {
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
      'topExpense': topExpense,
      'topExpenseAmount': maxExpenseAmount,
    };
  }

  String _id(String prefix) {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-$ms-${_sales.length + _customers.length + _products.length + _debts.length + _loans.length}';
  }
}

enum SaleMode { free, product }

enum FinancialEntryType { revenue, expense, stock }

enum LoanInterestUnit { day, month }

enum FinancialPeriod { day, week, month }

class SaleRecord {
  SaleRecord({
    required this.id,
    required this.description,
    required this.total,
    required this.mode,
    required this.paymentMethod,
    required this.createdAt,
    this.productId,
    this.quantity,
  });

  final String id;
  final String description;
  final double total;
  final SaleMode mode;
  final String paymentMethod;
  final DateTime createdAt;
  final String? productId;
  final double? quantity;
}

class CustomerRecord {
  CustomerRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final DateTime createdAt;
}

class ProductRecord {
  ProductRecord({
    required this.id,
    required this.name,
    required this.category,
    required this.salePrice,
    required this.cost,
    required this.stock,
    required this.unit,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String category;
  final double salePrice;
  final double cost;
  final double stock;
  final String unit;
  final DateTime createdAt;

  ProductRecord copyWith({
    String? id,
    String? name,
    String? category,
    double? salePrice,
    double? cost,
    double? stock,
    String? unit,
    DateTime? createdAt,
  }) {
    return ProductRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      salePrice: salePrice ?? this.salePrice,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DebtRecord {
  DebtRecord({
    required this.id,
    required this.customerName,
    required this.description,
    required this.originalAmount,
    required this.openAmount,
    required this.createdAt,
  });

  final String id;
  final String customerName;
  final String description;
  final double originalAmount;
  final double openAmount;
  final DateTime createdAt;

  DebtRecord copyWith({
    String? id,
    String? customerName,
    String? description,
    double? originalAmount,
    double? openAmount,
    DateTime? createdAt,
  }) {
    return DebtRecord(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      description: description ?? this.description,
      originalAmount: originalAmount ?? this.originalAmount,
      openAmount: openAmount ?? this.openAmount,
      createdAt: createdAt ?? this.createdAt,
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

  LoanRecord copyWith({
    String? id,
    String? customerName,
    double? principal,
    double? paidAmount,
    DateTime? dueDate,
    double? interestRate,
    LoanInterestUnit? interestUnit,
    DateTime? createdAt,
  }) {
    return LoanRecord(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      principal: principal ?? this.principal,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      interestRate: interestRate ?? this.interestRate,
      interestUnit: interestUnit ?? this.interestUnit,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FinancialEntry {
  FinancialEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.createdAt,
    required this.origin,
  });

  final String id;
  final FinancialEntryType type;
  final String description;
  final double amount;
  final DateTime createdAt;
  final String origin;
}

class AppStoreScope extends InheritedNotifier<AppStore> {
  const AppStoreScope({super.key, required this.store, required super.child}) : super(notifier: store);

  final AppStore store;

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStoreScope>();
    if (scope == null) {
      throw FlutterError('AppStoreScope nao encontrado no contexto.');
    }
    return scope.store;
  }
}
