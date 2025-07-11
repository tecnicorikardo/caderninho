import 'package:uuid/uuid.dart';

class CartaoCredito {
  final String id;
  final String nome;
  final double limite;
  final double gastoMensal;
  final int diaVencimento;
  final DateTime dataCriacao;
  final bool ativo;

  CartaoCredito({
    String? id,
    required this.nome,
    required this.limite,
    this.gastoMensal = 0.0,
    required this.diaVencimento,
    DateTime? dataCriacao,
    this.ativo = true,
  }) : id = id ?? const Uuid().v4(),
       dataCriacao = dataCriacao ?? DateTime.now();

  // Conversão para Map (banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'limite': limite,
      'gastoMensal': gastoMensal,
      'diaVencimento': diaVencimento,
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      'ativo': ativo ? 1 : 0,
    };
  }

  // Conversão de Map para CartaoCredito
  factory CartaoCredito.fromMap(Map<String, dynamic> map) {
    return CartaoCredito(
      id: map['id'],
      nome: map['nome'],
      limite: map['limite']?.toDouble() ?? 0.0,
      gastoMensal: map['gastoMensal']?.toDouble() ?? 0.0,
      diaVencimento: map['diaVencimento'] ?? 1,
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(map['dataCriacao']),
      ativo: map['ativo'] == 1,
    );
  }

  // Cópia com alterações
  CartaoCredito copyWith({
    String? nome,
    double? limite,
    double? gastoMensal,
    int? diaVencimento,
    bool? ativo,
  }) {
    return CartaoCredito(
      id: id,
      nome: nome ?? this.nome,
      limite: limite ?? this.limite,
      gastoMensal: gastoMensal ?? this.gastoMensal,
      diaVencimento: diaVencimento ?? this.diaVencimento,
      dataCriacao: dataCriacao,
      ativo: ativo ?? this.ativo,
    );
  }

  // Limite disponível
  double get limiteDisponivel {
    return limite - gastoMensal;
  }

  // Percentual usado
  double get percentualUsado {
    if (limite == 0) return 0;
    return (gastoMensal / limite) * 100;
  }

  // Data de vencimento do mês atual
  DateTime get proximoVencimento {
    final agora = DateTime.now();
    var vencimento = DateTime(agora.year, agora.month, diaVencimento);
    
    // Se já passou do dia de vencimento, pega o próximo mês
    if (agora.day > diaVencimento) {
      vencimento = DateTime(agora.year, agora.month + 1, diaVencimento);
    }
    
    return vencimento;
  }

  // Dias até vencimento
  int get diasAteVencimento {
    return proximoVencimento.difference(DateTime.now()).inDays;
  }

  // Status do cartão baseado no uso
  String get statusUso {
    final percentual = percentualUsado;
    if (percentual >= 90) return 'Crítico';
    if (percentual >= 70) return 'Alto';
    if (percentual >= 50) return 'Moderado';
    return 'Baixo';
  }
} 