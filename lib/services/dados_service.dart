import '../models/venda.dart';
import '../models/fiado.dart';
import '../models/produto.dart';
import '../models/cliente.dart';
import '../models/conta.dart';
import 'database_service.dart';

class DadosService {
  static final DadosService _instancia = DadosService._interno();
  factory DadosService() => _instancia;
  DadosService._interno();

  // Dados de exemplo
  final List<Produto> produtos = [
    Produto(id: '1', nome: 'Arroz', preco: 25.00, unidade: 'kg', quantidadeEstoque: 50),
    Produto(id: '2', nome: 'Feijão', preco: 8.00, unidade: 'kg', quantidadeEstoque: 30),
    Produto(id: '3', nome: 'Óleo', preco: 12.00, unidade: 'L', quantidadeEstoque: 20),
    Produto(id: '4', nome: 'Açúcar', preco: 5.50, unidade: 'kg', quantidadeEstoque: 40),
    Produto(id: '5', nome: 'Café', preco: 15.00, unidade: 'kg', quantidadeEstoque: 25),
    Produto(id: '6', nome: 'Macarrão', preco: 4.50, unidade: 'pacote', quantidadeEstoque: 5),
    Produto(id: '7', nome: 'Farinha', preco: 3.80, unidade: 'kg', quantidadeEstoque: 15),
    Produto(id: '8', nome: 'Sal', preco: 2.50, unidade: 'kg', quantidadeEstoque: 8),
  ];

  final List<Cliente> clientes = [
    Cliente(id: '1', nome: 'João Silva', telefone: '11999999999'),
    Cliente(id: '2', nome: 'Maria Santos', telefone: '11888888888'),
    Cliente(id: '3', nome: 'Pedro Costa', telefone: '11777777777'),
    Cliente(id: '4', nome: 'Ana Oliveira', telefone: '11666666666'),
    Cliente(id: '5', nome: 'Carlos Ferreira', telefone: '11555555555'),
  ];

  final List<Fiado> fiados = [
    Fiado(
      id: '1',
      cliente: Cliente(id: '1', nome: 'João Silva'),
      valorTotal: 150.00,
      valorPago: 50.00,
      dataFiado: DateTime.now().subtract(const Duration(days: 5)),
      dataVencimento: DateTime.now().add(const Duration(days: 2)),
      observacao: 'Compra de mantimentos',
    ),
    Fiado(
      id: '2',
      cliente: Cliente(id: '2', nome: 'Maria Santos'),
      valorTotal: 75.50,
      valorPago: 0.0,
      dataFiado: DateTime.now().subtract(const Duration(days: 3)),
      dataVencimento: DateTime.now().subtract(const Duration(days: 1)),
      observacao: 'Produtos de limpeza',
    ),
    Fiado(
      id: '3',
      cliente: Cliente(id: '3', nome: 'Pedro Costa'),
      valorTotal: 200.00,
      valorPago: 200.00,
      dataFiado: DateTime.now().subtract(const Duration(days: 10)),
      dataVencimento: DateTime.now().subtract(const Duration(days: 5)),
      observacao: 'Compra grande - PAGO',
    ),
  ];

  final List<Venda> vendas = [
    Venda(
      id: '1',
      itens: [
        ItemVenda(
          produto: Produto(id: '1', nome: 'Arroz', preco: 25.00, unidade: 'kg'),
          quantidade: 2,
          precoUnitario: 25.00,
        ),
        ItemVenda(
          produto: Produto(id: '2', nome: 'Feijão', preco: 8.00, unidade: 'kg'),
          quantidade: 1,
          precoUnitario: 8.00,
        ),
      ],
      cliente: Cliente(id: '1', nome: 'João Silva'),
      formaPagamento: FormaPagamento.dinheiro,
      dataVenda: DateTime.now().subtract(const Duration(days: 0)),
    ),
    Venda(
      id: '2',
      itens: [
        ItemVenda(
          produto: Produto(id: '3', nome: 'Óleo', preco: 12.00, unidade: 'L'),
          quantidade: 3,
          precoUnitario: 12.00,
        ),
      ],
      cliente: Cliente(id: '2', nome: 'Maria Santos'),
      formaPagamento: FormaPagamento.pix,
      dataVenda: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Venda(
      id: '3',
      itens: [
        ItemVenda(
          produto: Produto(id: '1', nome: 'Arroz', preco: 25.00, unidade: 'kg'),
          quantidade: 1,
          precoUnitario: 25.00,
        ),
        ItemVenda(
          produto: Produto(id: '4', nome: 'Açúcar', preco: 5.50, unidade: 'kg'),
          quantidade: 2,
          precoUnitario: 5.50,
        ),
      ],
      cliente: Cliente(id: '1', nome: 'João Silva'),
      formaPagamento: FormaPagamento.cartao,
      dataVenda: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Venda(
      id: '4',
      itens: [
        ItemVenda(
          produto: Produto(id: '5', nome: 'Café', preco: 15.00, unidade: 'kg'),
          quantidade: 1,
          precoUnitario: 15.00,
        ),
      ],
      cliente: Cliente(id: '3', nome: 'Pedro Costa'),
      formaPagamento: FormaPagamento.dinheiro,
      dataVenda: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  // Métodos utilitários
  double getVendasHoje() {
    final hoje = DateTime.now();
    return vendas
        .where((v) => v.dataVenda.year == hoje.year && v.dataVenda.month == hoje.month && v.dataVenda.day == hoje.day)
        .fold(0.0, (sum, v) => sum + v.total);
  }

  double getFiadosPendentes() {
    return fiados
        .where((f) => f.status != StatusFiado.pago)
        .fold(0.0, (sum, f) => sum + f.valorRestante);
  }

  int getEstoqueBaixo([int minimo = 10]) {
    return produtos.where((p) => p.quantidadeEstoque <= minimo).length;
  }

  // Métodos para adicionar novos dados
  void adicionarVenda(Venda venda) {
    vendas.add(venda);
  }

  void adicionarFiado(Fiado fiado) {
    fiados.add(fiado);
  }

  void adicionarProduto(Produto produto) {
    produtos.add(produto);
  }

  void adicionarCliente(Cliente cliente) {
    clientes.add(cliente);
  }

  // Carregar dados reais do banco
  Future<void> carregarDadosReais() async {
    try {
      final db = await DatabaseService().database;
      
      // Carregar produtos
      final produtosData = await db.query('produtos');
      produtos.clear();
      produtos.addAll(produtosData.map((data) => Produto(
        id: data['id'] as String,
        nome: data['nome'] as String,
        preco: (data['preco'] as num).toDouble(),
        unidade: data['unidade'] as String,
        quantidadeEstoque: data['quantidadeEstoque'] as int,
      )));

      // Carregar clientes
      final clientesData = await db.query('clientes2');
      clientes.clear();
      clientes.addAll(clientesData.map((data) => Cliente(
        id: data['id'] as String,
        nome: data['nome'] as String,
        telefone: data['telefone'] as String?,
        endereco: data['endereco'] as String?,
        dataCadastro: DateTime.parse(data['dataCadastro'] as String),
      )));

      // Carregar vendas
      final vendasData = await db.query('vendas');
      vendas.clear();
      for (var vendaData in vendasData) {
        final itensData = await db.query(
          'itens_venda',
          where: 'venda_id = ?',
          whereArgs: [vendaData['id']],
        );
        
        List<ItemVenda> itens = [];
        for (var itemData in itensData) {
          final produtoData = await db.query(
            'produtos',
            where: 'id = ?',
            whereArgs: [itemData['produto_id']],
          );
          
          if (produtoData.isNotEmpty) {
            final produto = Produto(
              id: produtoData.first['id'] as String,
              nome: produtoData.first['nome'] as String,
              preco: (produtoData.first['preco'] as num).toDouble(),
              unidade: produtoData.first['unidade'] as String,
              quantidadeEstoque: produtoData.first['quantidadeEstoque'] as int,
            );
            
            itens.add(ItemVenda(
              produto: produto,
              quantidade: itemData['quantidade'] as int,
              precoUnitario: (itemData['precoUnitario'] as num).toDouble(),
            ));
          }
        }
        
        final clienteData = await db.query(
          'clientes2',
          where: 'id = ?',
          whereArgs: [vendaData['cliente_id']],
        );
        
        Cliente? cliente;
        if (clienteData.isNotEmpty) {
          cliente = Cliente(
            id: clienteData.first['id'] as String,
            nome: clienteData.first['nome'] as String,
            telefone: clienteData.first['telefone'] as String?,
            endereco: clienteData.first['endereco'] as String?,
            dataCadastro: DateTime.parse(clienteData.first['dataCadastro'] as String),
          );
        }
        
        if (cliente != null) {
          vendas.add(Venda(
            id: vendaData['id'] as String,
            itens: itens,
            cliente: cliente,
            formaPagamento: FormaPagamento.values[vendaData['formaPagamento'] as int],
            dataVenda: DateTime.parse(vendaData['dataVenda'] as String),
          ));
        }
      }

      // Carregar fiados
      final fiadosData = await db.query('fiados');
      fiados.clear();
      print('🔍 Carregando fiados do banco: encontrados ${fiadosData.length}');
      for (var fiadoData in fiadosData) {
        final clienteData = await db.query(
          'clientes2',
          where: 'id = ?',
          whereArgs: [fiadoData['cliente_id']],
        );
        
        if (clienteData.isNotEmpty) {
          final cliente = Cliente(
            id: clienteData.first['id'] as String,
            nome: clienteData.first['nome'] as String,
            telefone: clienteData.first['telefone'] as String?,
            endereco: clienteData.first['endereco'] as String?,
            dataCadastro: DateTime.parse(clienteData.first['dataCadastro'] as String),
          );
          final fiado = Fiado(
            id: fiadoData['id'] as String,
            cliente: cliente,
            valorTotal: (fiadoData['valorTotal'] as num).toDouble(),
            valorPago: (fiadoData['valorPago'] as num).toDouble(),
            dataFiado: DateTime.parse(fiadoData['dataFiado'] as String),
            dataVencimento: DateTime.parse(fiadoData['dataVencimento'] as String),
            observacao: fiadoData['observacao'] as String?,
          );
          print('🔍 Fiado carregado: id=${fiado.id}, cliente=${fiado.cliente.nome}, valorTotal=${fiado.valorTotal}, valorPago=${fiado.valorPago}, dataFiado=${fiado.dataFiado}, dataVencimento=${fiado.dataVencimento}, observacao=${fiado.observacao}');
          fiados.add(fiado);
        }
      }
    } catch (e) {
      print('Erro ao carregar dados reais: $e');
      rethrow;
    }
  }

  // Métodos para buscar dados por cliente
  Future<List<Venda>> obterVendasPorCliente(String clienteId) async {
    try {
      final db = await DatabaseService.instance.database;
      
      final vendasData = await db.query(
        'vendas',
        where: 'cliente_id = ?',
        whereArgs: [clienteId],
        orderBy: 'dataVenda DESC',
      );
      
      List<Venda> vendasCliente = [];
      for (var vendaData in vendasData) {
        final itensData = await db.query(
          'itens_venda',
          where: 'venda_id = ?',
          whereArgs: [vendaData['id']],
        );
        
        List<ItemVenda> itens = [];
        for (var itemData in itensData) {
          final produtoData = await db.query(
            'produtos',
            where: 'id = ?',
            whereArgs: [itemData['produto_id']],
          );
          
          if (produtoData.isNotEmpty) {
            final produto = Produto(
              id: produtoData.first['id'] as String,
              nome: produtoData.first['nome'] as String,
              preco: (produtoData.first['preco'] as num).toDouble(),
              unidade: produtoData.first['unidade'] as String,
              quantidadeEstoque: produtoData.first['quantidadeEstoque'] as int,
            );
            
            itens.add(ItemVenda(
              produto: produto,
              quantidade: itemData['quantidade'] as int,
              precoUnitario: (itemData['precoUnitario'] as num).toDouble(),
            ));
          }
        }
        
        final clienteData = await db.query(
          'clientes2',
          where: 'id = ?',
          whereArgs: [vendaData['cliente_id']],
        );
        
        if (clienteData.isNotEmpty) {
          final cliente = Cliente(
            id: clienteData.first['id'] as String,
            nome: clienteData.first['nome'] as String,
            telefone: clienteData.first['telefone'] as String?,
            endereco: clienteData.first['endereco'] as String?,
            dataCadastro: DateTime.parse(clienteData.first['dataCadastro'] as String),
          );
          
          vendasCliente.add(Venda(
            id: vendaData['id'] as String,
            itens: itens,
            cliente: cliente,
            formaPagamento: FormaPagamento.values[vendaData['formaPagamento'] as int],
            dataVenda: DateTime.parse(vendaData['dataVenda'] as String),
          ));
        }
      }
      
      return vendasCliente;
    } catch (e) {
      print('❌ Erro ao buscar vendas por cliente: $e');
      return [];
    }
  }

  Future<List<Fiado>> obterFiadosPorCliente(String clienteId) async {
    try {
      final db = await DatabaseService.instance.database;
      
      final fiadosData = await db.query(
        'fiados',
        where: 'cliente_id = ?',
        whereArgs: [clienteId],
        orderBy: 'dataFiado DESC',
      );
      
      List<Fiado> fiadosCliente = [];
      for (var fiadoData in fiadosData) {
        final clienteData = await db.query(
          'clientes2',
          where: 'id = ?',
          whereArgs: [fiadoData['cliente_id']],
        );
        
        if (clienteData.isNotEmpty) {
          final cliente = Cliente(
            id: clienteData.first['id'] as String,
            nome: clienteData.first['nome'] as String,
            telefone: clienteData.first['telefone'] as String?,
            endereco: clienteData.first['endereco'] as String?,
            dataCadastro: DateTime.parse(clienteData.first['dataCadastro'] as String),
          );
          
          fiadosCliente.add(Fiado(
            id: fiadoData['id'] as String,
            cliente: cliente,
            valorTotal: (fiadoData['valorTotal'] as num).toDouble(),
            valorPago: (fiadoData['valorPago'] as num).toDouble(),
            dataFiado: DateTime.parse(fiadoData['dataFiado'] as String),
            dataVencimento: DateTime.parse(fiadoData['dataVencimento'] as String),
            observacao: fiadoData['observacao'] as String?,
          ));
        }
      }
      
      return fiadosCliente;
    } catch (e) {
      print('❌ Erro ao buscar fiados por cliente: $e');
      return [];
    }
  }

  Future<List<Conta>> obterContasPorCliente(String clienteId) async {
    try {
      final db = await DatabaseService.instance.database;
      
             final contasData = await db.query(
         'contas',
         where: 'cliente_id = ?',
         whereArgs: [clienteId],
         orderBy: 'vencimento DESC',
       );
      
      List<Conta> contasCliente = [];
      for (var contaData in contasData) {
                 contasCliente.add(Conta(
           id: contaData['id'] as String,
           nome: contaData['nome'] as String,
           valor: (contaData['valor'] as num).toDouble(),
           vencimento: DateTime.parse(contaData['vencimento'] as String),
           status: StatusConta.values[(contaData['status'] as int? ?? 0)],
           dataPagamento: contaData['dataPagamento'] != null 
               ? DateTime.parse(contaData['dataPagamento'] as String)
               : null,
           observacoes: contaData['observacoes'] as String?,
         ));
      }
      
      return contasCliente;
    } catch (e) {
      print('❌ Erro ao buscar contas por cliente: $e');
      return [];
    }
  }

  // Singleton instance
  static DadosService get instance => _instancia;
} 