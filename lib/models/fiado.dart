import 'cliente.dart';

enum StatusFiado { pendente, pago, parcial }

class Fiado {
  final String id;
  final Cliente cliente;
  final double valorTotal;
  final double valorPago;
  final DateTime dataFiado;
  final DateTime? dataVencimento;
  final String? observacao;
  final List<PagamentoFiado> pagamentos;

  Fiado({
    required this.id,
    required this.cliente,
    required this.valorTotal,
    this.valorPago = 0.0,
    DateTime? dataFiado,
    this.dataVencimento,
    this.observacao,
    List<PagamentoFiado>? pagamentos,
  }) : 
    dataFiado = dataFiado ?? DateTime.now(),
    pagamentos = pagamentos ?? [];

  double get valorRestante => valorTotal - valorPago;
  
  StatusFiado get status {
    if (valorPago >= valorTotal) return StatusFiado.pago;
    if (valorPago > 0) return StatusFiado.parcial;
    return StatusFiado.pendente;
  }

  bool get estaVencido {
    if (dataVencimento == null) return false;
    return DateTime.now().isAfter(dataVencimento!) && status != StatusFiado.pago;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente': cliente.toMap(),
      'valorTotal': valorTotal,
      'valorPago': valorPago,
      'dataFiado': dataFiado.toIso8601String(),
      'dataVencimento': dataVencimento?.toIso8601String(),
      'observacao': observacao,
      'pagamentos': pagamentos.map((p) => p.toMap()).toList(),
    };
  }

  factory Fiado.fromMap(Map<String, dynamic> map) {
    return Fiado(
      id: map['id'],
      cliente: Cliente.fromMap(map['cliente']),
      valorTotal: map['valorTotal'].toDouble(),
      valorPago: map['valorPago'].toDouble(),
      dataFiado: DateTime.parse(map['dataFiado']),
      dataVencimento: map['dataVencimento'] != null 
          ? DateTime.parse(map['dataVencimento']) 
          : null,
      observacao: map['observacao'],
      pagamentos: (map['pagamentos'] as List)
          .map((p) => PagamentoFiado.fromMap(p))
          .toList(),
    );
  }
}

class PagamentoFiado {
  final String id;
  final double valor;
  final DateTime dataPagamento;
  final String? observacao;

  PagamentoFiado({
    required this.id,
    required this.valor,
    DateTime? dataPagamento,
    this.observacao,
  }) : dataPagamento = dataPagamento ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'valor': valor,
      'dataPagamento': dataPagamento.toIso8601String(),
      'observacao': observacao,
    };
  }

  factory PagamentoFiado.fromMap(Map<String, dynamic> map) {
    return PagamentoFiado(
      id: map['id'],
      valor: map['valor'].toDouble(),
      dataPagamento: DateTime.parse(map['dataPagamento']),
      observacao: map['observacao'],
    );
  }
} 