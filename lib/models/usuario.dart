class Usuario {
  final String id;
  final String nome;
  final String email;
  final String senha;
  final String cargo;
  final DateTime dataCriacao;
  final bool ativo;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.senha,
    this.cargo = 'Vendedor',
    DateTime? dataCriacao,
    this.ativo = true,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'senha': senha, // Em produção, deve ser criptografada
      'cargo': cargo,
      'dataCriacao': dataCriacao.toIso8601String(),
      'ativo': ativo ? 1 : 0,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      nome: map['nome'],
      email: map['email'],
      senha: map['senha'],
      cargo: map['cargo'] ?? 'Vendedor',
      dataCriacao: DateTime.parse(map['dataCriacao']),
      ativo: map['ativo'] == 1,
    );
  }

  // Cria uma cópia do usuário com senha criptografada
  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? senha,
    String? cargo,
    DateTime? dataCriacao,
    bool? ativo,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      cargo: cargo ?? this.cargo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ativo: ativo ?? this.ativo,
    );
  }
} 