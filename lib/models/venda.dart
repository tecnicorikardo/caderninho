import 'cliente.dart';
import 'produto.dart';

enum FormaPagamento { dinheiro, cartao, pix, fiado }

enum TipoAdicional { taxa_servico, emprestimo }

class Adicional {
  final String id;
  final TipoAdicional tipo;
  final String descricao;
  final double valor;
  final DateTime data;

  Adicional({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.valor,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo.index,
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String(),
    };
  }

  factory Adicional.fromMap(Map<String, dynamic> map) {
    return Adicional(
      id: map['id'],
      tipo: TipoAdicional.values[map['tipo']],
      descricao: map['descricao'],
      valor: map['valor'].toDouble(),
      data: DateTime.parse(map['data']),
    );
  }
}

class ItemVenda {
  final Produto produto;
  final int quantidade;
  final double precoUnitario;

  ItemVenda({
    required this.produto,
    required this.quantidade,
    required this.precoUnitario,
  });

  double get total => quantidade * precoUnitario;

  Map<String, dynamic> toMap() {
    return {
      'produto': produto.toMap(),
      'quantidade': quantidade,
      'precoUnitario': precoUnitario,
    };
  }

  factory ItemVenda.fromMap(Map<String, dynamic> map) {
    return ItemVenda(
      produto: Produto.fromMap(map['produto']),
      quantidade: map['quantidade'],
      precoUnitario: map['precoUnitario'].toDouble(),
    );
  }
}

class Venda {
  final String id;
  final List<ItemVenda> itens;
  final List<Adicional> adicionais;
  final Cliente? cliente;
  final FormaPagamento formaPagamento;
  final DateTime dataVenda;
  final double total;

  Venda({
    required this.id,
    required this.itens,
    this.adicionais = const [],
    this.cliente,
    required this.formaPagamento,
    required this.dataVenda,
  })  : total = (itens.fold(0.0, (sum, item) => sum + item.total) + 
           adicionais.fold(0.0, (sum, adicional) => sum + adicional.valor));

  double get subtotal => itens.fold(0.0, (sum, item) => sum + item.total);
  
  double get totalAdicionais => adicionais.fold(0.0, (sum, adicional) => sum + adicional.valor);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itens': itens.map((item) => item.toMap()).toList(),
      'adicionais': adicionais.map((adicional) => adicional.toMap()).toList(),
      'cliente': cliente?.toMap(),
      'formaPagamento': formaPagamento.index,
      'dataVenda': dataVenda.toIso8601String(),
      'total': total,
    };
  }

  factory Venda.fromMap(Map<String, dynamic> map) {
    return Venda(
      id: map['id'],
      itens: (map['itens'] as List)
          .map((item) => ItemVenda.fromMap(item))
          .toList(),
      adicionais: map['adicionais'] != null 
          ? (map['adicionais'] as List)
              .map((adicional) => Adicional.fromMap(adicional))
              .toList()
          : [],
      cliente: map['cliente'] != null ? Cliente.fromMap(map['cliente']) : null,
      formaPagamento: FormaPagamento.values[map['formaPagamento']],
      dataVenda: DateTime.parse(map['dataVenda']),
    );
  }
} 