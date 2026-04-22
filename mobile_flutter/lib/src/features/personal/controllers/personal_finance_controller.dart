import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/personal_account.dart';
import '../models/personal_category.dart';
import '../models/personal_transaction.dart';
import '../services/personal_finance_service.dart';

class PersonalFinanceController extends ChangeNotifier {
  PersonalFinanceController({required this.service}) {
    _initialize();
  }

  final PersonalFinanceService service;
  final List<StreamSubscription> _subscriptions = [];

  List<PersonalAccount> _accounts = [];
  List<PersonalCategory> _categories = [];
  List<PersonalTransaction> _transactions = [];
  Map<String, double> _accountBalances = {};

  List<PersonalAccount> get accounts => List.unmodifiable(_accounts);
  List<PersonalCategory> get categories => List.unmodifiable(_categories);
  List<PersonalTransaction> get transactions => List.unmodifiable(_transactions);
  Map<String, double> get accountBalances => Map.unmodifiable(_accountBalances);

  // Filtros
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterCategoriaId;
  String? _filterContaId;
  TipoTransacao? _filterTipo;
  StatusTransacao? _filterStatus;

  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String? get filterCategoriaId => _filterCategoriaId;
  String? get filterContaId => _filterContaId;
  TipoTransacao? get filterTipo => _filterTipo;
  StatusTransacao? get filterStatus => _filterStatus;

  void _initialize() {
    // Inicializar categorias padrão
    service.initializeDefaultCategories();

    // Watch accounts
    _subscriptions.add(
      service.watchAccounts().listen(
        (accounts) {
          _accounts = accounts;
          _updateAccountBalances();
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Erro ao carregar contas: $error');
        },
      ),
    );

    // Watch categories
    _subscriptions.add(
      service.watchCategories().listen(
        (categories) {
          _categories = categories;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Erro ao carregar categorias: $error');
        },
      ),
    );

    // Watch transactions with filters
    _watchTransactions();
  }

  void _watchTransactions() {
    _subscriptions.add(
      service
          .watchTransactions(
            startDate: _filterStartDate,
            endDate: _filterEndDate,
            categoriaId: _filterCategoriaId,
            contaId: _filterContaId,
            tipo: _filterTipo,
            status: _filterStatus,
          )
          .listen(
        (transactions) {
          _transactions = transactions;
          _updateAccountBalances();
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Erro ao carregar transações: $error');
        },
      ),
    );
  }

  Future<void> _updateAccountBalances() async {
    for (final account in _accounts) {
      try {
        final balance = await service.calculateAccountBalance(account.id);
        _accountBalances[account.id] = balance;
      } catch (e) {
        debugPrint('Erro ao calcular saldo da conta ${account.id}: $e');
      }
    }
    notifyListeners();
  }

  // ==================== FILTROS ====================

  void setFilters({
    DateTime? startDate,
    DateTime? endDate,
    String? categoriaId,
    String? contaId,
    TipoTransacao? tipo,
    StatusTransacao? status,
  }) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    _filterCategoriaId = categoriaId;
    _filterContaId = contaId;
    _filterTipo = tipo;
    _filterStatus = status;

    // Recarregar transações com novos filtros
    _subscriptions.last.cancel();
    _watchTransactions();
  }

  void clearFilters() {
    _filterStartDate = null;
    _filterEndDate = null;
    _filterCategoriaId = null;
    _filterContaId = null;
    _filterTipo = null;
    _filterStatus = null;

    _subscriptions.last.cancel();
    _watchTransactions();
  }

  void setMonthFilter(DateTime month) {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    setFilters(startDate: startDate, endDate: endDate);
  }

  // ==================== CONTAS ====================

  Future<void> createAccount({
    required String nome,
    required double saldoInicial,
  }) async {
    await service.createAccount(nome: nome, saldoInicial: saldoInicial);
  }

  Future<void> updateAccount({
    required String accountId,
    required String nome,
    required double saldoInicial,
  }) async {
    await service.updateAccount(
      accountId: accountId,
      nome: nome,
      saldoInicial: saldoInicial,
    );
  }

  Future<void> deleteAccount(String accountId) async {
    await service.deleteAccount(accountId);
  }

  double getAccountBalance(String accountId) {
    return _accountBalances[accountId] ?? 0;
  }

  double get totalBalance {
    return _accountBalances.values.fold(0, (sum, balance) => sum + balance);
  }

  // ==================== CATEGORIAS ====================

  Future<void> createCategory({
    required String nome,
    required TipoTransacao tipo,
    required int iconeCodePoint,
    required int corValue,
  }) async {
    await service.createCategory(
      nome: nome,
      tipo: tipo,
      iconeCodePoint: iconeCodePoint,
      corValue: corValue,
    );
  }

  Future<void> updateCategory({
    required String categoryId,
    required String nome,
    required int iconeCodePoint,
    required int corValue,
  }) async {
    await service.updateCategory(
      categoryId: categoryId,
      nome: nome,
      iconeCodePoint: iconeCodePoint,
      corValue: corValue,
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    await service.deleteCategory(categoryId);
  }

  PersonalCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  List<PersonalCategory> getCategoriesByType(TipoTransacao tipo) {
    return _categories.where((c) => c.tipo == tipo).toList();
  }

  // ==================== TRANSAÇÕES ====================

  Future<void> createTransaction({
    required TipoTransacao tipo,
    required String nome,
    required String categoriaId,
    required String contaId,
    required double valor,
    required DateTime dataPrevista,
    StatusTransacao status = StatusTransacao.pendente,
    bool recorrente = false,
    FrequenciaRecorrencia? frequencia,
    bool parcelado = false,
    int? numeroParcelas,
    bool notificar = false,
    int? diasAntesNotificacao,
    String? observacao,
  }) async {
    await service.createTransaction(
      tipo: tipo,
      nome: nome,
      categoriaId: categoriaId,
      contaId: contaId,
      valor: valor,
      dataPrevista: dataPrevista,
      status: status,
      recorrente: recorrente,
      frequencia: frequencia,
      parcelado: parcelado,
      numeroParcelas: numeroParcelas,
      notificar: notificar,
      diasAntesNotificacao: diasAntesNotificacao,
      observacao: observacao,
    );
  }

  Future<void> markAsPaid({
    required String transactionId,
    DateTime? dataPagamento,
  }) async {
    await service.markAsPaid(
      transactionId: transactionId,
      dataPagamento: dataPagamento ?? DateTime.now(),
    );
  }

  Future<void> markAsPending(String transactionId) async {
    await service.markAsPending(transactionId);
  }

  Future<void> updateTransaction({
    required String transactionId,
    required String nome,
    required String categoriaId,
    required double valor,
    required DateTime dataPrevista,
    StatusTransacao? status,
    bool? notificar,
    int? diasAntesNotificacao,
    String? observacao,
  }) async {
    await service.updateTransaction(
      transactionId: transactionId,
      nome: nome,
      categoriaId: categoriaId,
      valor: valor,
      dataPrevista: dataPrevista,
      status: status,
      notificar: notificar,
      diasAntesNotificacao: diasAntesNotificacao,
      observacao: observacao,
    );
  }

  Future<void> deleteTransaction(String transactionId) async {
    await service.deleteTransaction(transactionId);
  }

  // ==================== RESUMOS E ESTATÍSTICAS ====================

  double get totalReceitas {
    return _transactions
        .where((t) => t.tipo == TipoTransacao.receita)
        .fold(0, (sum, t) => sum + t.valor);
  }

  double get totalDespesas {
    return _transactions
        .where((t) => t.tipo == TipoTransacao.despesa)
        .fold(0, (sum, t) => sum + t.valor);
  }

  double get totalReceitasPagas {
    return _transactions
        .where((t) => t.tipo == TipoTransacao.receita && t.status == StatusTransacao.pago)
        .fold(0, (sum, t) => sum + t.valor);
  }

  double get totalDespesasPagas {
    return _transactions
        .where((t) => t.tipo == TipoTransacao.despesa && t.status == StatusTransacao.pago)
        .fold(0, (sum, t) => sum + t.valor);
  }

  double get saldoAtual {
    return totalReceitasPagas - totalDespesasPagas;
  }

  int get transacoesPendentes {
    return _transactions.where((t) => t.status == StatusTransacao.pendente).length;
  }

  List<PersonalTransaction> get proximasContas {
    final now = DateTime.now();
    final proximos7Dias = now.add(const Duration(days: 7));

    return _transactions
        .where((t) =>
            t.status == StatusTransacao.pendente &&
            t.dataPrevista.isAfter(now) &&
            t.dataPrevista.isBefore(proximos7Dias))
        .toList()
      ..sort((a, b) => a.dataPrevista.compareTo(b.dataPrevista));
  }

  Future<Map<String, dynamic>> getMonthSummary(DateTime month) async {
    return await service.getMonthSummary(month);
  }

  Future<Map<String, double>> getCategoryTotals({
    required DateTime startDate,
    required DateTime endDate,
    required TipoTransacao tipo,
  }) async {
    return await service.getCategoryTotals(
      startDate: startDate,
      endDate: endDate,
      tipo: tipo,
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
