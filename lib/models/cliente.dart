class Cliente {
  final String id;
  final String nome;
  final String? telefone;
  final String? endereco;
  final DateTime dataCadastro;

  Cliente({
    required this.id,
    required this.nome,
    this.telefone,
    this.endereco,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'endereco': endereco,
      'dataCadastro': dataCadastro.toIso8601String(),
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as String,
      nome: map['nome'] as String,
      telefone: map['telefone'] as String?,
      endereco: map['endereco'] as String?,
      dataCadastro: DateTime.parse(map['dataCadastro'] as String),
    );
  }
} 