import 'package:uuid/uuid.dart';

enum StatusCompromisso {
  pendente,
  concluido,
  cancelado
}

class Compromisso {
  final String id;
  final DateTime data;
  final String? hora; // Formato "HH:mm" ou null se não especificado
  final String descricao;
  final StatusCompromisso status;
  final bool alertaUmDiaAntes;
  final DateTime dataCriacao;
  final DateTime? dataNotificacao; // Quando a notificação foi enviada

  Compromisso({
    String? id,
    required this.data,
    this.hora,
    required this.descricao,
    this.status = StatusCompromisso.pendente,
    this.alertaUmDiaAntes = false,
    DateTime? dataCriacao,
    this.dataNotificacao,
  }) : id = id ?? const Uuid().v4(),
       dataCriacao = dataCriacao ?? DateTime.now();

  // Conversão para Map (banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.millisecondsSinceEpoch,
      'hora': hora,
      'descricao': descricao,
      'status': status.index,
      'alertaUmDiaAntes': alertaUmDiaAntes ? 1 : 0,
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      'dataNotificacao': dataNotificacao?.millisecondsSinceEpoch,
    };
  }

  // Conversão de Map para Compromisso
  factory Compromisso.fromMap(Map<String, dynamic> map) {
    return Compromisso(
      id: map['id'],
      data: DateTime.fromMillisecondsSinceEpoch(map['data']),
      hora: map['hora'],
      descricao: map['descricao'],
      status: StatusCompromisso.values[map['status'] ?? 0],
      alertaUmDiaAntes: map['alertaUmDiaAntes'] == 1,
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(map['dataCriacao']),
      dataNotificacao: map['dataNotificacao'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dataNotificacao'])
          : null,
    );
  }

  // Cópia com alterações
  Compromisso copyWith({
    DateTime? data,
    String? hora,
    String? descricao,
    StatusCompromisso? status,
    bool? alertaUmDiaAntes,
    DateTime? dataNotificacao,
  }) {
    return Compromisso(
      id: id,
      data: data ?? this.data,
      hora: hora ?? this.hora,
      descricao: descricao ?? this.descricao,
      status: status ?? this.status,
      alertaUmDiaAntes: alertaUmDiaAntes ?? this.alertaUmDiaAntes,
      dataCriacao: dataCriacao,
      dataNotificacao: dataNotificacao ?? this.dataNotificacao,
    );
  }

  // Status formatado
  String get statusFormatado {
    switch (status) {
      case StatusCompromisso.pendente:
        return 'Pendente';
      case StatusCompromisso.concluido:
        return 'Concluído';
      case StatusCompromisso.cancelado:
        return 'Cancelado';
    }
  }

  // Data formatada para exibição
  String get dataFormatada {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  // Data e hora formatadas
  String get dataHoraFormatada {
    if (hora != null) {
      return '$dataFormatada às $hora';
    }
    return dataFormatada;
  }

  // Verificar se é hoje
  bool get isHoje {
    final hoje = DateTime.now();
    return data.year == hoje.year && 
           data.month == hoje.month && 
           data.day == hoje.day;
  }

  // Verificar se é amanhã
  bool get isAmanha {
    final amanha = DateTime.now().add(const Duration(days: 1));
    return data.year == amanha.year && 
           data.month == amanha.month && 
           data.day == amanha.day;
  }

  // Verificar se está atrasado
  bool get isAtrasado {
    if (status != StatusCompromisso.pendente) return false;
    return DateTime.now().isAfter(data);
  }

  // Dias até o compromisso
  int get diasAteCompromisso {
    return data.difference(DateTime.now()).inDays;
  }

  // Precisa de notificação (um dia antes e ainda não foi enviada)
  bool get precisaNotificacao {
    if (!alertaUmDiaAntes || dataNotificacao != null) return false;
    if (status != StatusCompromisso.pendente) return false;
    
    final agora = DateTime.now();
    final umDiaAntes = DateTime(data.year, data.month, data.day - 1);
    
    // Se já passou do dia da notificação ou se é o próprio dia
    return agora.isAfter(umDiaAntes) && agora.isBefore(data);
  }

  // Ícone baseado no status
  String get icone {
    switch (status) {
      case StatusCompromisso.pendente:
        if (isAtrasado) return '⚠️';
        if (isHoje) return '🔥';
        if (isAmanha) return '⏰';
        return '📅';
      case StatusCompromisso.concluido:
        return '✅';
      case StatusCompromisso.cancelado:
        return '❌';
    }
  }
} 