import 'casa_aposta.dart';
import 'deposito.dart';

class Saque {
  final String id;
  final CasaAposta casaAposta;
  final double valor;
  final MetodoPagamento metodoPagamento;
  final DateTime data;
  final String? observacoes;
  final bool confirmado;

  Saque({
    required this.id,
    required this.casaAposta,
    required this.valor,
    required this.metodoPagamento,
    DateTime? data,
    this.observacoes,
    this.confirmado = true,
  }) : data = data ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'casaApostaId': casaAposta.id,
      'valor': valor,
      'metodoPagamento': metodoPagamento.index,
      'data': data.toIso8601String(),
      'observacoes': observacoes,
      'confirmado': confirmado ? 1 : 0,
    };
  }

  factory Saque.fromMap(Map<String, dynamic> map, CasaAposta casaAposta) {
    return Saque(
      id: map['id'] as String,
      casaAposta: casaAposta,
      valor: (map['valor'] as num).toDouble(),
      metodoPagamento: MetodoPagamento.values[map['metodoPagamento'] as int],
      data: DateTime.parse(map['data'] as String),
      observacoes: map['observacoes'] as String?,
      confirmado: (map['confirmado'] as int) == 1,
    );
  }

  String get metodoPagamentoText {
    switch (metodoPagamento) {
      case MetodoPagamento.pix:
        return 'PIX';
      case MetodoPagamento.cartao_credito:
        return 'Cartão de Crédito';
      case MetodoPagamento.cartao_debito:
        return 'Cartão de Débito';
      case MetodoPagamento.transferencia:
        return 'Transferência';
      case MetodoPagamento.dinheiro:
        return 'Dinheiro';
    }
  }

  Saque copyWith({
    String? id,
    CasaAposta? casaAposta,
    double? valor,
    MetodoPagamento? metodoPagamento,
    DateTime? data,
    String? observacoes,
    bool? confirmado,
  }) {
    return Saque(
      id: id ?? this.id,
      casaAposta: casaAposta ?? this.casaAposta,
      valor: valor ?? this.valor,
      metodoPagamento: metodoPagamento ?? this.metodoPagamento,
      data: data ?? this.data,
      observacoes: observacoes ?? this.observacoes,
      confirmado: confirmado ?? this.confirmado,
    );
  }
} 