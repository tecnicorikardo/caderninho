class CasaAposta {
  final String id;
  final String nome;
  final String? url;
  final String? categoria; // Esportes, Cassino, Poker, etc.
  final String? observacoes;
  final DateTime dataCadastro;
  final bool ativo;

  CasaAposta({
    required this.id,
    required this.nome,
    this.url,
    this.categoria,
    this.observacoes,
    DateTime? dataCadastro,
    this.ativo = true,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'url': url,
      'categoria': categoria,
      'observacoes': observacoes,
      'dataCadastro': dataCadastro.toIso8601String(),
      'ativo': ativo ? 1 : 0,
    };
  }

  factory CasaAposta.fromMap(Map<String, dynamic> map) {
    return CasaAposta(
      id: map['id'] as String,
      nome: map['nome'] as String,
      url: map['url'] as String?,
      categoria: map['categoria'] as String?,
      observacoes: map['observacoes'] as String?,
      dataCadastro: DateTime.parse(map['dataCadastro'] as String),
      ativo: (map['ativo'] as int) == 1,
    );
  }

  CasaAposta copyWith({
    String? id,
    String? nome,
    String? url,
    String? categoria,
    String? observacoes,
    DateTime? dataCadastro,
    bool? ativo,
  }) {
    return CasaAposta(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      url: url ?? this.url,
      categoria: categoria ?? this.categoria,
      observacoes: observacoes ?? this.observacoes,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      ativo: ativo ?? this.ativo,
    );
  }
} 