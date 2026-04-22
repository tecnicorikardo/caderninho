import 'package:cloud_firestore/cloud_firestore.dart';

import 'personal_category.dart';

enum StatusTransacao { pendente, pago }
enum FrequenciaRecorrencia { mensal, semanal, anual }

class PersonalTransaction {
  PersonalTransaction({
    required this.id,
    required this.tipo,
    required this.nome,
    required this.categoriaId,
    required this.contaId,
    required this.valor,
    required this.dataPrevista,
    this.dataPagamento,
    required this.status,
    required this.recorrente,
    this.frequencia,
    required this.parcelado,
    this.numeroParcelas,
    this.parcelaAtual,
    required this.notificar,
    this.diasAntesNotificacao,
    this.observacao,
    required this.criadoEm,
  });

  final String id;
  final TipoTransacao tipo;
  final String nome;
  final String categoriaId;
  final String contaId;
  final double valor;
  final DateTime dataPrevista;
  final DateTime? dataPagamento;
  final StatusTransacao status;
  final bool recorrente;
  final FrequenciaRecorrencia? frequencia;
  final bool parcelado;
  final int? numeroParcelas;
  final int? parcelaAtual;
  final bool notificar;
  final int? diasAntesNotificacao;
  final String? observacao;
  final DateTime criadoEm;

  factory PersonalTransaction.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return PersonalTransaction(
      id: doc.id,
      tipo: (data['tipo'] ?? 'despesa') == 'receita'
          ? TipoTransacao.receita
          : TipoTransacao.despesa,
      nome: (data['nome'] ?? '') as String,
      categoriaId: (data['categoriaId'] ?? '') as String,
      contaId: (data['contaId'] ?? '') as String,
      valor: ((data['valor'] ?? 0) as num).toDouble(),
      dataPrevista:
          (data['dataPrevista'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataPagamento: (data['dataPagamento'] as Timestamp?)?.toDate(),
      status: (data['status'] ?? 'pendente') == 'pago'
          ? StatusTransacao.pago
          : StatusTransacao.pendente,
      recorrente: (data['recorrente'] ?? false) as bool,
      frequencia: _parseFrequencia(data['frequencia']),
      parcelado: (data['parcelado'] ?? false) as bool,
      numeroParcelas: data['numeroParcelas'] as int?,
      parcelaAtual: data['parcelaAtual'] as int?,
      notificar: (data['notificar'] ?? false) as bool,
      diasAntesNotificacao: data['diasAntesNotificacao'] as int?,
      observacao: data['observacao'] as String?,
      criadoEm: (data['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static FrequenciaRecorrencia? _parseFrequencia(dynamic value) {
    if (value == null) return null;
    switch (value.toString()) {
      case 'mensal':
        return FrequenciaRecorrencia.mensal;
      case 'semanal':
        return FrequenciaRecorrencia.semanal;
      case 'anual':
        return FrequenciaRecorrencia.anual;
      default:
        return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo == TipoTransacao.receita ? 'receita' : 'despesa',
      'nome': nome,
      'categoriaId': categoriaId,
      'contaId': contaId,
      'valor': valor,
      'dataPrevista': Timestamp.fromDate(dataPrevista),
      'dataPagamento':
          dataPagamento != null ? Timestamp.fromDate(dataPagamento!) : null,
      'status': status == StatusTransacao.pago ? 'pago' : 'pendente',
      'recorrente': recorrente,
      'frequencia': frequencia?.name,
      'parcelado': parcelado,
      'numeroParcelas': numeroParcelas,
      'parcelaAtual': parcelaAtual,
      'notificar': notificar,
      'diasAntesNotificacao': diasAntesNotificacao,
      'observacao': observacao,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

  PersonalTransaction copyWith({
    String? id,
    TipoTransacao? tipo,
    String? nome,
    String? categoriaId,
    String? contaId,
    double? valor,
    DateTime? dataPrevista,
    DateTime? dataPagamento,
    StatusTransacao? status,
    bool? recorrente,
    FrequenciaRecorrencia? frequencia,
    bool? parcelado,
    int? numeroParcelas,
    int? parcelaAtual,
    bool? notificar,
    int? diasAntesNotificacao,
    String? observacao,
    DateTime? criadoEm,
  }) {
    return PersonalTransaction(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      nome: nome ?? this.nome,
      categoriaId: categoriaId ?? this.categoriaId,
      contaId: contaId ?? this.contaId,
      valor: valor ?? this.valor,
      dataPrevista: dataPrevista ?? this.dataPrevista,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      status: status ?? this.status,
      recorrente: recorrente ?? this.recorrente,
      frequencia: frequencia ?? this.frequencia,
      parcelado: parcelado ?? this.parcelado,
      numeroParcelas: numeroParcelas ?? this.numeroParcelas,
      parcelaAtual: parcelaAtual ?? this.parcelaAtual,
      notificar: notificar ?? this.notificar,
      diasAntesNotificacao: diasAntesNotificacao ?? this.diasAntesNotificacao,
      observacao: observacao ?? this.observacao,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
