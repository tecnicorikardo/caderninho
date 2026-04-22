import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/personal_account.dart';
import '../models/personal_category.dart';
import '../models/personal_transaction.dart';

class PersonalFinanceService {
  PersonalFinanceService({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String collection) {
    return _db.collection('users').doc(uid).collection(collection);
  }

  // ==================== CONTAS ====================

  Stream<List<PersonalAccount>> watchAccounts() {
    return _col('personal_accounts')
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(PersonalAccount.fromDoc).toList());
  }

  Future<void> createAccount({
    required String nome,
    required double saldoInicial,
  }) async {
    await _col('personal_accounts').add({
      'nome': nome,
      'saldoInicial': saldoInicial,
      'criadoEm': FieldValue.serverTimestamp(),
      'ativo': true,
    });
  }

  Future<void> updateAccount({
    required String accountId,
    required String nome,
    required double saldoInicial,
  }) async {
    await _col('personal_accounts').doc(accountId).update({
      'nome': nome,
      'saldoInicial': saldoInicial,
    });
  }

  Future<void> deleteAccount(String accountId) async {
    // Verificar se existem transações vinculadas
    final transactions = await _col('personal_transactions')
        .where('contaId', isEqualTo: accountId)
        .limit(1)
        .get();

    if (transactions.docs.isNotEmpty) {
      throw StateError(
        'Não é possível excluir conta com transações vinculadas',
      );
    }

    await _col('personal_accounts').doc(accountId).update({'ativo': false});
  }

  // Calcular saldo atual da conta
  Future<double> calculateAccountBalance(String accountId) async {
    final account = await _col('personal_accounts').doc(accountId).get();
    if (!account.exists) return 0;

    final accountData = PersonalAccount.fromDoc(account);
    final saldoInicial = accountData.saldoInicial;

    // Buscar transações pagas
    final transactions = await _col('personal_transactions')
        .where('contaId', isEqualTo: accountId)
        .where('status', isEqualTo: 'pago')
        .get();

    double receitas = 0;
    double despesas = 0;

    for (final doc in transactions.docs) {
      final trans = PersonalTransaction.fromDoc(doc);
      if (trans.tipo == TipoTransacao.receita) {
        receitas += trans.valor;
      } else {
        despesas += trans.valor;
      }
    }

    return saldoInicial + receitas - despesas;
  }

  // ==================== CATEGORIAS ====================

  Stream<List<PersonalCategory>> watchCategories() {
    return _col('personal_categories')
        .orderBy('nome')
        .snapshots()
        .map((s) => s.docs.map(PersonalCategory.fromDoc).toList());
  }

  Future<void> createCategory({
    required String nome,
    required TipoTransacao tipo,
    required int iconeCodePoint,
    required int corValue,
  }) async {
    await _col('personal_categories').add({
      'nome': nome,
      'tipo': tipo == TipoTransacao.receita ? 'receita' : 'despesa',
      'icone': iconeCodePoint,
      'cor': corValue,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory({
    required String categoryId,
    required String nome,
    required int iconeCodePoint,
    required int corValue,
  }) async {
    await _col('personal_categories').doc(categoryId).update({
      'nome': nome,
      'icone': iconeCodePoint,
      'cor': corValue,
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    // Verificar se existem transações vinculadas
    final transactions = await _col('personal_transactions')
        .where('categoriaId', isEqualTo: categoryId)
        .limit(1)
        .get();

    if (transactions.docs.isNotEmpty) {
      throw StateError(
        'Não é possível excluir categoria com transações vinculadas',
      );
    }

    await _col('personal_categories').doc(categoryId).delete();
  }

  // Inicializar categorias padrão
  Future<void> initializeDefaultCategories() async {
    final existing = await _col('personal_categories').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final category in PersonalCategory.defaultCategories()) {
      final ref = _col('personal_categories').doc();
      batch.set(ref, category.toMap());
    }
    await batch.commit();
  }

  // ==================== TRANSAÇÕES ====================

  Stream<List<PersonalTransaction>> watchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoriaId,
    String? contaId,
    TipoTransacao? tipo,
    StatusTransacao? status,
  }) {
    Query<Map<String, dynamic>> query = _col('personal_transactions');

    if (startDate != null) {
      query = query.where(
        'dataPrevista',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'dataPrevista',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    if (categoriaId != null) {
      query = query.where('categoriaId', isEqualTo: categoriaId);
    }

    if (contaId != null) {
      query = query.where('contaId', isEqualTo: contaId);
    }

    if (tipo != null) {
      query = query.where(
        'tipo',
        isEqualTo: tipo == TipoTransacao.receita ? 'receita' : 'despesa',
      );
    }

    if (status != null) {
      query = query.where(
        'status',
        isEqualTo: status == StatusTransacao.pago ? 'pago' : 'pendente',
      );
    }

    return query
        .orderBy('dataPrevista', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PersonalTransaction.fromDoc).toList());
  }

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
    if (parcelado && (numeroParcelas == null || numeroParcelas < 2)) {
      throw ArgumentError('Número de parcelas deve ser maior que 1');
    }

    if (recorrente && frequencia == null) {
      throw ArgumentError('Frequência é obrigatória para transações recorrentes');
    }

    final batch = _db.batch();

    if (parcelado) {
      // Criar múltiplas transações parceladas
      for (int i = 1; i <= numeroParcelas!; i++) {
        final ref = _col('personal_transactions').doc();
        final dataParcelada = _calculateNextDate(dataPrevista, frequencia ?? FrequenciaRecorrencia.mensal, i - 1);
        
        batch.set(ref, {
          'tipo': tipo == TipoTransacao.receita ? 'receita' : 'despesa',
          'nome': '$nome (${i}/$numeroParcelas)',
          'categoriaId': categoriaId,
          'contaId': contaId,
          'valor': valor / numeroParcelas,
          'dataPrevista': Timestamp.fromDate(dataParcelada),
          'status': 'pendente',
          'recorrente': false,
          'parcelado': true,
          'numeroParcelas': numeroParcelas,
          'parcelaAtual': i,
          'notificar': notificar,
          'diasAntesNotificacao': diasAntesNotificacao,
          'observacao': observacao,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
    } else if (recorrente) {
      // Criar transação recorrente + próximas 12 ocorrências
      for (int i = 0; i < 12; i++) {
        final ref = _col('personal_transactions').doc();
        final dataRecorrente = _calculateNextDate(dataPrevista, frequencia!, i);
        
        batch.set(ref, {
          'tipo': tipo == TipoTransacao.receita ? 'receita' : 'despesa',
          'nome': nome,
          'categoriaId': categoriaId,
          'contaId': contaId,
          'valor': valor,
          'dataPrevista': Timestamp.fromDate(dataRecorrente),
          'status': 'pendente',
          'recorrente': true,
          'frequencia': frequencia.name,
          'parcelado': false,
          'notificar': notificar,
          'diasAntesNotificacao': diasAntesNotificacao,
          'observacao': observacao,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
    } else {
      // Transação única
      final ref = _col('personal_transactions').doc();
      batch.set(ref, {
        'tipo': tipo == TipoTransacao.receita ? 'receita' : 'despesa',
        'nome': nome,
        'categoriaId': categoriaId,
        'contaId': contaId,
        'valor': valor,
        'dataPrevista': Timestamp.fromDate(dataPrevista),
        'status': status == StatusTransacao.pago ? 'pago' : 'pendente',
        'dataPagamento': status == StatusTransacao.pago ? Timestamp.fromDate(DateTime.now()) : null,
        'recorrente': false,
        'parcelado': false,
        'notificar': notificar,
        'diasAntesNotificacao': diasAntesNotificacao,
        'observacao': observacao,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  DateTime _calculateNextDate(
    DateTime base,
    FrequenciaRecorrencia frequencia,
    int occurrences,
  ) {
    switch (frequencia) {
      case FrequenciaRecorrencia.semanal:
        return base.add(Duration(days: 7 * occurrences));
      case FrequenciaRecorrencia.mensal:
        return DateTime(
          base.year,
          base.month + occurrences,
          base.day,
        );
      case FrequenciaRecorrencia.anual:
        return DateTime(
          base.year + occurrences,
          base.month,
          base.day,
        );
    }
  }

  Future<void> markAsPaid({
    required String transactionId,
    required DateTime dataPagamento,
  }) async {
    await _col('personal_transactions').doc(transactionId).update({
      'status': 'pago',
      'dataPagamento': Timestamp.fromDate(dataPagamento),
    });
  }

  Future<void> markAsPending(String transactionId) async {
    await _col('personal_transactions').doc(transactionId).update({
      'status': 'pendente',
      'dataPagamento': null,
    });
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
    final updateData = {
      'nome': nome,
      'categoriaId': categoriaId,
      'valor': valor,
      'dataPrevista': Timestamp.fromDate(dataPrevista),
      'notificar': notificar,
      'diasAntesNotificacao': diasAntesNotificacao,
      'observacao': observacao,
    };

    if (status != null) {
      updateData['status'] = status == StatusTransacao.pago ? 'pago' : 'pendente';
      if (status == StatusTransacao.pago) {
        updateData['dataPagamento'] = Timestamp.fromDate(DateTime.now());
      } else {
        updateData['dataPagamento'] = null;
      }
    }

    await _col('personal_transactions').doc(transactionId).update(updateData);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _col('personal_transactions').doc(transactionId).delete();
  }

  // ==================== RELATÓRIOS ====================

  Future<Map<String, double>> getCategoryTotals({
    required DateTime startDate,
    required DateTime endDate,
    required TipoTransacao tipo,
  }) async {
    final transactions = await _col('personal_transactions')
        .where('tipo', isEqualTo: tipo == TipoTransacao.receita ? 'receita' : 'despesa')
        .where('status', isEqualTo: 'pago')
        .where('dataPagamento', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('dataPagamento', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final Map<String, double> totals = {};

    for (final doc in transactions.docs) {
      final trans = PersonalTransaction.fromDoc(doc);
      totals[trans.categoriaId] = (totals[trans.categoriaId] ?? 0) + trans.valor;
    }

    return totals;
  }

  Future<Map<String, dynamic>> getMonthSummary(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final transactions = await _col('personal_transactions')
        .where('dataPrevista', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('dataPrevista', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    double receitasPrevistas = 0;
    double receitasPagas = 0;
    double despesasPrevistas = 0;
    double despesasPagas = 0;
    int pendentes = 0;

    for (final doc in transactions.docs) {
      final trans = PersonalTransaction.fromDoc(doc);
      
      if (trans.tipo == TipoTransacao.receita) {
        receitasPrevistas += trans.valor;
        if (trans.status == StatusTransacao.pago) {
          receitasPagas += trans.valor;
        }
      } else {
        despesasPrevistas += trans.valor;
        if (trans.status == StatusTransacao.pago) {
          despesasPagas += trans.valor;
        }
      }

      if (trans.status == StatusTransacao.pendente) {
        pendentes++;
      }
    }

    return {
      'receitasPrevistas': receitasPrevistas,
      'receitasPagas': receitasPagas,
      'despesasPrevistas': despesasPrevistas,
      'despesasPagas': despesasPagas,
      'saldoPrevisto': receitasPrevistas - despesasPrevistas,
      'saldoReal': receitasPagas - despesasPagas,
      'pendentes': pendentes,
    };
  }
}
