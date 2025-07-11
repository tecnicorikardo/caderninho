import 'package:uuid/uuid.dart';

enum StatusConta {
  pendente,
  pago,
  vencido
}

class Conta {
  final String id;
  final String nome;
  final double valor;
  final DateTime vencimento;
  final StatusConta status;
  final DateTime? dataPagamento;
  final DateTime dataCriacao;
  final String? observacoes;

  Conta({
    String? id,
    required this.nome,
    required this.valor,
    required this.vencimento,
    this.status = StatusConta.pendente,
    this.dataPagamento,
    DateTime? dataCriacao,
    this.observacoes,
  }) : id = id ?? const Uuid().v4(),
       dataCriacao = dataCriacao ?? DateTime.now();

  // Conversão para Map (banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'valor': valor,
      'vencimento': vencimento.millisecondsSinceEpoch,
      'status': status.index,
      'dataPagamento': dataPagamento?.millisecondsSinceEpoch,
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      'observacoes': observacoes,
    };
  }

  // Conversão de Map para Conta
  factory Conta.fromMap(Map<String, dynamic> map) {
    return Conta(
      id: map['id'],
      nome: map['nome'],
      valor: map['valor']?.toDouble() ?? 0.0,
      vencimento: DateTime.fromMillisecondsSinceEpoch(map['vencimento']),
      status: StatusConta.values[map['status'] ?? 0],
      dataPagamento: map['dataPagamento'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dataPagamento'])
          : null,
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(map['dataCriacao']),
      observacoes: map['observacoes'],
    );
  }

  // Cópia com alterações
  Conta copyWith({
    String? nome,
    double? valor,
    DateTime? vencimento,
    StatusConta? status,
    DateTime? dataPagamento,
    String? observacoes,
  }) {
    return Conta(
      id: id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      vencimento: vencimento ?? this.vencimento,
      status: status ?? this.status,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      dataCriacao: dataCriacao,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  // Verificar se está vencida
  bool get isVencida {
    if (status == StatusConta.pago) return false;
    return DateTime.now().isAfter(vencimento);
  }

  // Dias até vencimento
  int get diasAteVencimento {
    return vencimento.difference(DateTime.now()).inDays;
  }

  // Status formatado
  String get statusFormatado {
    switch (status) {
      case StatusConta.pendente:
        return 'Pendente';
      case StatusConta.pago:
        return 'Pago';
      case StatusConta.vencido:
        return 'Vencido';
    }
  }
} 