class Produto {
  final String id;
  final String nome;
  final double preco;
  final String unidade; // kg, unidade, pacote, etc.
  int quantidadeEstoque;
  
  // ✅ NOVOS CAMPOS PARA CÁLCULO DE LUCRO
  final double? custoUnitario; // Custo por unidade
  final String? categoria; // Para agrupar produtos similares
  final String? fornecedor; // Para rastreamento

  Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.unidade,
    this.quantidadeEstoque = 0,
    this.custoUnitario,
    this.categoria,
    this.fornecedor,
  });

  // ✅ MÉTODO PARA CALCULAR LUCRO UNITÁRIO
  double get lucroUnitario {
    if (custoUnitario == null || custoUnitario == 0) {
      return preco; // Se não tem custo, considera todo valor como lucro
    }
    return preco - custoUnitario!;
  }

  // ✅ MÉTODO PARA CALCULAR MARGEM DE LUCRO (%)
  double get margemLucro {
    if (preco == 0) return 0;
    return (lucroUnitario / preco) * 100;
  }

  // ✅ MÉTODO PARA CALCULAR LUCRO TOTAL DO ESTOQUE
  double get lucroTotalEstoque {
    return lucroUnitario * quantidadeEstoque;
  }

  // ✅ MÉTODO PARA VERIFICAR SE TEM CUSTO DEFINIDO
  bool get temCustoDefinido => custoUnitario != null && custoUnitario! > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'preco': preco,
      'unidade': unidade,
      'quantidadeEstoque': quantidadeEstoque,
      'custoUnitario': custoUnitario,
      'categoria': categoria,
      'fornecedor': fornecedor,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'] as String,
      nome: map['nome'] as String,
      preco: (map['preco'] as num).toDouble(),
      unidade: map['unidade'] as String,
      quantidadeEstoque: map['quantidadeEstoque'] as int,
      custoUnitario: map['custoUnitario'] != null 
          ? (map['custoUnitario'] as num).toDouble() 
          : null,
      categoria: map['categoria'] as String?,
      fornecedor: map['fornecedor'] as String?,
    );
  }

  // ✅ MÉTODO PARA CRIAR CÓPIA COM DADOS ATUALIZADOS
  Produto copyWith({
    String? id,
    String? nome,
    double? preco,
    String? unidade,
    int? quantidadeEstoque,
    double? custoUnitario,
    String? categoria,
    String? fornecedor,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      preco: preco ?? this.preco,
      unidade: unidade ?? this.unidade,
      quantidadeEstoque: quantidadeEstoque ?? this.quantidadeEstoque,
      custoUnitario: custoUnitario ?? this.custoUnitario,
      categoria: categoria ?? this.categoria,
      fornecedor: fornecedor ?? this.fornecedor,
    );
  }
} 