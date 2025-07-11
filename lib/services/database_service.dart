import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/produto.dart';
import '../models/cliente.dart';
import '../models/venda.dart';
import '../models/fiado.dart';
import '../models/conta.dart';
import '../models/cartao_credito.dart';
import '../models/compromisso.dart';
import '../models/casa_aposta.dart';
import '../models/deposito.dart';
import '../models/saque.dart';
import 'package:path_provider/path_provider.dart';
import 'notification_service.dart';
import 'dart:io';
import '../models/usuario.dart';

class DatabaseService {
  static final DatabaseService _instancia = DatabaseService._interno();
  factory DatabaseService() => _instancia;
  DatabaseService._interno();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // REMOVIDO: await _forceRecreateDatabase(); // ❌ Apagava dados desnecessariamente
    
    String path = join(await getDatabasesPath(), 'app_caderninho_definitivo.db');
    return await openDatabase(
      path, 
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Adicionado para futuras atualizações
    );
  }

  // Método para atualizações futuras do banco
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Atualizando banco da versão $oldVersion para $newVersion');
    // Implementar migrations aqui quando necessário
  }

  // MÉTODO PARA FORÇAR RECRIAÇÃO - APENAS PARA DEBUG/DESENVOLVIMENTO
  Future<void> _forceRecreateDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final files = ['app_caderninho.db', 'app_caderninho_novo.db', 'app_caderninho_v2.db', 'app_caderninho_definitivo.db'];
      
      for (String fileName in files) {
        final file = File(join(dbPath, fileName));
        if (await file.exists()) {
          await file.delete();
          print('Banco deletado: $fileName');
        }
      }
    } catch (e) {
      print('Erro ao deletar bancos: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Criando banco de dados versão $version
    
    // Tabela Produtos - ATUALIZADA COM CAMPOS DE CUSTO
    await db.execute('''
      CREATE TABLE produtos (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        preco REAL NOT NULL,
        unidade TEXT NOT NULL,
        quantidadeEstoque INTEGER NOT NULL,
        custoUnitario REAL,
        categoria TEXT,
        fornecedor TEXT
      )
    ''');

    // Tabela Clientes
    await db.execute('''
      CREATE TABLE clientes2 (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        telefone TEXT,
        endereco TEXT,
        dataCadastro TEXT NOT NULL
      )
    ''');
    print('✅ Tabela clientes criada');

    // Tabela Usuários
    await db.execute('''
      CREATE TABLE usuarios (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        senha TEXT NOT NULL,
        cargo TEXT NOT NULL,
        dataCriacao TEXT NOT NULL,
        ativo INTEGER NOT NULL
      )
    ''');
    print('✅ Tabela usuarios criada');

    // Tabela Vendas
    await db.execute('''
      CREATE TABLE vendas (
        id TEXT PRIMARY KEY,
        cliente_id TEXT,
        formaPagamento INTEGER NOT NULL,
        dataVenda TEXT NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (cliente_id) REFERENCES clientes2 (id)
      )
    ''');
    print('✅ Tabela vendas criada');

    // Tabela Itens de Venda
    await db.execute('''
      CREATE TABLE itens_venda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venda_id TEXT NOT NULL,
        produto_id TEXT NOT NULL,
        quantidade INTEGER NOT NULL,
        precoUnitario REAL NOT NULL,
        custoUnitario REAL,
        lucroUnitario REAL,
        FOREIGN KEY (venda_id) REFERENCES vendas (id),
        FOREIGN KEY (produto_id) REFERENCES produtos (id)
      )
    ''');
    print('✅ Tabela itens_venda criada');

    // Tabela Adicionais
    await db.execute('''
      CREATE TABLE adicionais (
        id TEXT PRIMARY KEY,
        venda_id TEXT NOT NULL,
        tipo INTEGER NOT NULL,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        FOREIGN KEY (venda_id) REFERENCES vendas (id)
      )
    ''');
    print('✅ Tabela adicionais criada');



    // Tabela Fiados
    await db.execute('''
      CREATE TABLE fiados (
        id TEXT PRIMARY KEY,
        cliente_id TEXT NOT NULL,
        valorTotal REAL NOT NULL,
        valorPago REAL NOT NULL,
        dataFiado TEXT NOT NULL,
        dataVencimento TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clientes2 (id)
      )
    ''');
    print('✅ Tabela fiados criada');

    // Tabela Contas
    await db.execute('''
      CREATE TABLE contas (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        valor REAL NOT NULL,
        vencimento INTEGER NOT NULL,
        status INTEGER NOT NULL,
        dataPagamento INTEGER,
        dataCriacao INTEGER NOT NULL,
        observacoes TEXT
      )
    ''');
    print('✅ Tabela contas criada');

    // Tabela Cartões de Crédito
    await db.execute('''
      CREATE TABLE cartoes_credito (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        limite REAL NOT NULL,
        gastoMensal REAL NOT NULL,
        diaVencimento INTEGER NOT NULL,
        dataCriacao INTEGER NOT NULL,
        ativo INTEGER NOT NULL
      )
    ''');
    print('✅ Tabela cartoes_credito criada');

    // Tabela Compromissos (Agenda)
    await db.execute('''
      CREATE TABLE compromissos (
        id TEXT PRIMARY KEY,
        data INTEGER NOT NULL,
        hora TEXT,
        descricao TEXT NOT NULL,
        status INTEGER NOT NULL,
        alertaUmDiaAntes INTEGER NOT NULL,
        dataCriacao INTEGER NOT NULL,
        dataNotificacao INTEGER
      )
    ''');
    print('✅ Tabela compromissos criada');

    // Tabela Casas de Aposta
    await db.execute('''
      CREATE TABLE casas_aposta (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        url TEXT,
        categoria TEXT,
        observacoes TEXT,
        dataCadastro TEXT NOT NULL,
        ativo INTEGER NOT NULL
      )
    ''');
    print('✅ Tabela casas_aposta criada');

    // Tabela Depósitos
    await db.execute('''
      CREATE TABLE depositos (
        id TEXT PRIMARY KEY,
        casaApostaId TEXT NOT NULL,
        valor REAL NOT NULL,
        metodoPagamento INTEGER NOT NULL,
        data TEXT NOT NULL,
        observacoes TEXT,
        confirmado INTEGER NOT NULL,
        FOREIGN KEY (casaApostaId) REFERENCES casas_aposta (id)
      )
    ''');
    print('✅ Tabela depositos criada');

    // Tabela Saques
    await db.execute('''
      CREATE TABLE saques (
        id TEXT PRIMARY KEY,
        casaApostaId TEXT NOT NULL,
        valor REAL NOT NULL,
        metodoPagamento INTEGER NOT NULL,
        data TEXT NOT NULL,
        observacoes TEXT,
        confirmado INTEGER NOT NULL,
        FOREIGN KEY (casaApostaId) REFERENCES casas_aposta (id)
      )
    ''');
    print('✅ Tabela saques criada');

    // Verificar se as colunas foram criadas
    await _verificarEstruturaBanco(db);

    // Inserir dados de exemplo
    await _inserirDadosExemplo(db);
    print('✅ Dados de exemplo inseridos');
  }

  // MÉTODO PARA VERIFICAR ESTRUTURA
  Future<void> _verificarEstruturaBanco(Database db) async {
    print('🔍 Verificando estrutura completa do banco...');
    
    // Verificar todas as tabelas
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print('📋 Tabelas encontradas:');
    for (var table in tables) {
      print('  - ${table['name']}');
    }
    
    // Verificar estrutura da tabela clientes2
    final result = await db.rawQuery("PRAGMA table_info(clientes2)");
    print('🔍 Estrutura da tabela clientes2:');
    for (var column in result) {
      print('  - ${column['name']}: ${column['type']}');
    }
    
    // Verificar se tem as colunas necessárias
    final columnNames = result.map((e) => e['name']).toList();
    if (!columnNames.contains('endereco')) {
      throw Exception('❌ Coluna endereco não encontrada!');
    }
    if (!columnNames.contains('dataCadastro')) {
      throw Exception('❌ Coluna dataCadastro não encontrada!');
    }
    print('✅ Estrutura da tabela clientes2 verificada');
    
    // Verificar estrutura da tabela contas
    final contasResult = await db.rawQuery("PRAGMA table_info(contas)");
    print('🔍 Estrutura da tabela contas:');
    for (var column in contasResult) {
      print('  - ${column['name']}: ${column['type']}');
    }
    
    // Verificar se a tabela contas tem todas as colunas necessárias
    final contasColumnNames = contasResult.map((e) => e['name']).toList();
    final colunasNecessarias = ['id', 'nome', 'valor', 'vencimento', 'status', 'dataPagamento', 'dataCriacao', 'observacoes'];
    
    for (var coluna in colunasNecessarias) {
      if (!contasColumnNames.contains(coluna)) {
        throw Exception('❌ Coluna $coluna não encontrada na tabela contas!');
      }
    }
    print('✅ Estrutura da tabela contas verificada');
    
    // Verificar estrutura da tabela cartoes_credito
    final cartoesResult = await db.rawQuery("PRAGMA table_info(cartoes_credito)");
    print('🔍 Estrutura da tabela cartoes_credito:');
    for (var column in cartoesResult) {
      print('  - ${column['name']}: ${column['type']}');
    }
    print('✅ Estrutura da tabela cartoes_credito verificada');
  }

  Future<void> _inserirDadosExemplo(Database db) async {
    print('📝 Inserindo dados de exemplo...');
    
    // Produtos de exemplo
    final produtos = [
      {'id': '1', 'nome': 'Arroz', 'preco': 25.00, 'unidade': 'kg', 'quantidadeEstoque': 50},
      {'id': '2', 'nome': 'Feijão', 'preco': 8.00, 'unidade': 'kg', 'quantidadeEstoque': 30},
      {'id': '3', 'nome': 'Óleo', 'preco': 12.00, 'unidade': 'L', 'quantidadeEstoque': 20},
      {'id': '4', 'nome': 'Açúcar', 'preco': 5.50, 'unidade': 'kg', 'quantidadeEstoque': 40},
      {'id': '5', 'nome': 'Café', 'preco': 15.00, 'unidade': 'kg', 'quantidadeEstoque': 25},
    ];

    for (var produto in produtos) {
      await db.insert('produtos', produto);
    }
    print('✅ Produtos inseridos');

    // Clientes de exemplo - COM TODAS AS COLUNAS
    final agora = DateTime.now().toIso8601String();
    
    final clientes = [
      {
        'id': '1',
        'nome': 'João Silva',
        'telefone': '11999999999',
        'endereco': 'Rua das Flores, 123',
        'dataCadastro': agora,
      },
      {
        'id': '2',
        'nome': 'Maria Santos',
        'telefone': '11888888888',
        'endereco': 'Av. Brasil, 456',
        'dataCadastro': agora,
      },
      {
        'id': '3',
        'nome': 'Pedro Costa',
        'telefone': '11777777777',
        'endereco': 'Rua da Paz, 789',
        'dataCadastro': agora,
      },
    ];

    for (var cliente in clientes) {
      try {
        await db.insert('clientes2', cliente);
        print('✅ Cliente inserido: ${cliente['nome']}');
      } catch (e) {
        print('❌ Erro ao inserir cliente ${cliente['nome']}: $e');
        rethrow;
      }
    }
    print('✅ Clientes inseridos');

    // Vendas de exemplo
    await db.insert('vendas', {
      'id': '1',
      'cliente_id': '1',
      'formaPagamento': 0,
      'dataVenda': DateTime.now().toIso8601String(),
      'total': 58.00,
    });

    // Itens da venda
    await db.insert('itens_venda', {
      'venda_id': '1',
      'produto_id': '1',
      'quantidade': 2,
      'precoUnitario': 25.00,
    });

    // Fiados de exemplo
    await db.insert('fiados', {
      'id': '1',
      'cliente_id': '1',
      'valorTotal': 150.00,
      'valorPago': 50.00,
      'dataFiado': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'dataVencimento': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'observacao': 'Compra de mantimentos',
    });

    print('✅ Todos os dados de exemplo inseridos com sucesso!');
  }

  // MÉTODO PARA TESTAR INSERÇÃO DE CLIENTE
  Future<void> testarInsercaoCliente() async {
    try {
      final cliente = Cliente(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nome: 'Cliente Teste',
        telefone: '11999999999',
        endereco: 'Rua de Teste, 123',
      );
      
      await inserirCliente(cliente);
      print('✅ Cliente teste inserido com sucesso!');
    } catch (e) {
      print('❌ Erro ao inserir cliente teste: $e');
      rethrow;
    }
  }

  // Métodos para Produtos
  Future<List<Produto>> getProdutos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('produtos');
    return List.generate(maps.length, (i) => Produto.fromMap(maps[i]));
  }

  Future<void> inserirProduto(Produto produto) async {
    final db = await database;
    await db.insert('produtos', produto.toMap());
  }

  Future<void> atualizarProduto(Produto produto) async {
    final db = await database;
    await db.update(
      'produtos',
      produto.toMap(),
      where: 'id = ?',
      whereArgs: [produto.id],
    );
  }

  Future<void> deletarProduto(String id) async {
    final db = await database;
    await db.delete('produtos', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para Clientes
  Future<List<Cliente>> getClientes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clientes2');
    return List.generate(maps.length, (i) => Cliente.fromMap(maps[i]));
  }

  Future<void> inserirCliente(Cliente cliente) async {
    final db = await database;
    
    // Debug: mostrar dados que serão inseridos
    final clienteMap = cliente.toMap();
    print('🔍 Inserindo cliente: $clienteMap');
    
    try {
      await db.insert('clientes2', clienteMap);
      print('✅ Cliente inserido com sucesso!');
    } catch (e) {
      print('❌ Erro ao inserir cliente: $e');
      
      // Debug: verificar estrutura da tabela
      final tableInfo = await db.rawQuery("PRAGMA table_info(clientes2)");
      print('🔍 Estrutura atual da tabela clientes2:');
      for (var column in tableInfo) {
        print('  - ${column['name']}: ${column['type']}');
      }
      
      rethrow;
    }
  }

  Future<void> atualizarCliente(Cliente cliente) async {
    final db = await database;
    await db.update(
      'clientes2',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  Future<void> deletarCliente(String id) async {
    final db = await database;
    await db.delete('clientes2', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para Vendas
  Future<List<Venda>> getVendas() async {
    final db = await database;
    final List<Map<String, dynamic>> vendasMaps = await db.query('vendas');

    List<Venda> vendas = [];
    for (var vendaMap in vendasMaps) {
      // Buscar cliente
      Cliente? cliente;
      if (vendaMap['cliente_id'] != null) {
        final clienteMaps = await db.query(
          'clientes2',
          where: 'id = ?',
          whereArgs: [vendaMap['cliente_id']],
        );
        if (clienteMaps.isNotEmpty) {
          cliente = Cliente.fromMap(clienteMaps.first);
        }
      }

      // Buscar itens da venda
      final itensMaps = await db.query(
        'itens_venda',
        where: 'venda_id = ?',
        whereArgs: [vendaMap['id']],
      );

      List<ItemVenda> itens = [];
      for (var itemMap in itensMaps) {
        final produtoMaps = await db.query(
          'produtos',
          where: 'id = ?',
          whereArgs: [itemMap['produto_id']],
        );
        if (produtoMaps.isNotEmpty) {
          final produto = Produto.fromMap(produtoMaps.first);
          itens.add(
            ItemVenda(
              produto: produto,
              quantidade: itemMap['quantidade'] as int,
              precoUnitario: (itemMap['precoUnitario'] as num).toDouble(),
            ),
          );
        }
      }

      // Buscar adicionais da venda
      final adicionaisMaps = await db.query(
        'adicionais',
        where: 'venda_id = ?',
        whereArgs: [vendaMap['id']],
      );

      List<Adicional> adicionais = [];
      for (var adicionalMap in adicionaisMaps) {
        adicionais.add(
          Adicional(
            id: adicionalMap['id'] as String,
            tipo: TipoAdicional.values[adicionalMap['tipo'] as int],
            descricao: adicionalMap['descricao'] as String,
            valor: (adicionalMap['valor'] as num).toDouble(),
            data: DateTime.parse(adicionalMap['data'] as String),
          ),
        );
      }

      vendas.add(
        Venda(
          id: vendaMap['id'],
          itens: itens,
          adicionais: adicionais,
          cliente: cliente,
          formaPagamento: FormaPagamento.values[vendaMap['formaPagamento']],
          dataVenda: DateTime.parse(vendaMap['dataVenda']),
        ),
      );
    }

    return vendas;
  }

  Future<void> inserirVenda(Venda venda) async {
    final db = await database;
    await db.transaction((txn) async {
      // Inserir venda
      await txn.insert('vendas', {
        'id': venda.id,
        'cliente_id': venda.cliente?.id,
        'formaPagamento': venda.formaPagamento.index,
        'dataVenda': venda.dataVenda.toIso8601String(),
        'total': venda.total,
      });

      // Inserir itens da venda com cálculo de lucro
      for (var item in venda.itens) {
        // ✅ CALCULAR LUCRO DO ITEM
        double custoUnitario = item.produto.custoUnitario ?? 0.0;
        double lucroUnitario = item.precoUnitario - custoUnitario;
        
        await txn.insert('itens_venda', {
          'venda_id': venda.id,
          'produto_id': item.produto.id,
          'quantidade': item.quantidade,
          'precoUnitario': item.precoUnitario,
          'custoUnitario': custoUnitario,
          'lucroUnitario': lucroUnitario,
        });

        // Atualizar estoque do produto
        await txn.rawUpdate(
          '''
          UPDATE produtos 
          SET quantidadeEstoque = quantidadeEstoque - ? 
          WHERE id = ?
        ''',
          [item.quantidade, item.produto.id],
        );
      }

      // Inserir adicionais da venda
      for (var adicional in venda.adicionais) {
        await txn.insert('adicionais', {
          'id': adicional.id,
          'venda_id': venda.id,
          'tipo': adicional.tipo.index,
          'descricao': adicional.descricao,
          'valor': adicional.valor,
          'data': adicional.data.toIso8601String(),
        });
      }
    });
  }

  // Métodos para Fiados
  Future<List<Fiado>> getFiados() async {
    final db = await database;
    final List<Map<String, dynamic>> fiadosMaps = await db.query('fiados');

    List<Fiado> fiados = [];
    for (var fiadoMap in fiadosMaps) {
      // Buscar cliente
      final clienteMaps = await db.query(
        'clientes2',
        where: 'id = ?',
        whereArgs: [fiadoMap['cliente_id']],
      );

      if (clienteMaps.isNotEmpty) {
        final cliente = Cliente.fromMap(clienteMaps.first);
        fiados.add(
          Fiado(
            id: fiadoMap['id'],
            cliente: cliente,
            valorTotal: fiadoMap['valorTotal'],
            valorPago: fiadoMap['valorPago'],
            dataFiado: DateTime.parse(fiadoMap['dataFiado']),
            dataVencimento: DateTime.parse(fiadoMap['dataVencimento']),
            observacao: fiadoMap['observacao'],
          ),
        );
      }
    }

    return fiados;
  }

  Future<void> inserirFiado(Fiado fiado) async {
    final db = await database;
    print('🔍 Salvando fiado: id=${fiado.id}, cliente=${fiado.cliente.nome}, valorTotal=${fiado.valorTotal}, valorPago=${fiado.valorPago}, dataFiado=${fiado.dataFiado}, dataVencimento=${fiado.dataVencimento}, observacao=${fiado.observacao}');
    await db.insert('fiados', {
      'id': fiado.id,
      'cliente_id': fiado.cliente.id,
      'valorTotal': fiado.valorTotal,
      'valorPago': fiado.valorPago,
      'dataFiado': (fiado.dataFiado ?? DateTime.now()).toIso8601String(),
      'dataVencimento':
          (fiado.dataVencimento ?? DateTime.now().add(const Duration(days: 7)))
              .toIso8601String(),
      'observacao': fiado.observacao,
    });
    
    // Agendar notificação para o fiado
    try {
      await NotificationService.instance.agendarNotificacaoFiado(fiado);
    } catch (e) {
      print('Erro ao agendar notificação: $e');
    }
  }

  Future<void> atualizarFiado(Fiado fiado) async {
    final db = await database;
    await db.update(
      'fiados',
      {'valorPago': fiado.valorPago, 'observacao': fiado.observacao},
      where: 'id = ?',
      whereArgs: [fiado.id],
    );
    
    // Reagendar notificação se o fiado ainda não foi pago completamente
    if (fiado.valorPago < fiado.valorTotal) {
      try {
        await NotificationService.instance.agendarNotificacaoFiado(fiado);
      } catch (e) {
        print('Erro ao reagendar notificação: $e');
      }
    } else {
      // Cancela notificação se o fiado foi pago
      try {
        await NotificationService.instance.cancelarNotificacaoFiado(fiado.id);
      } catch (e) {
        print('Erro ao cancelar notificação: $e');
      }
    }
  }

  Future<void> deletarFiado(String id) async {
    final db = await database;
    await db.delete('fiados', where: 'id = ?', whereArgs: [id]);
    
    // Cancela notificação do fiado
    try {
      await NotificationService.instance.cancelarNotificacaoFiado(id);
    } catch (e) {
      print('Erro ao cancelar notificação: $e');
    }
  }



  // Métodos utilitários
  Future<double> getVendasHoje() async {
    final db = await database;
    final hoje = DateTime.now();
    final dataInicio = DateTime(hoje.year, hoje.month, hoje.day);
    final dataFim = dataInicio.add(const Duration(days: 1));

    final result = await db.rawQuery(
      '''
      SELECT SUM(total) as total FROM vendas 
      WHERE dataVenda >= ? AND dataVenda < ?
    ''',
      [dataInicio.toIso8601String(), dataFim.toIso8601String()],
    );

    return result.first['total'] as double? ?? 0.0;
  }

  // ✅ NOVOS MÉTODOS PARA RELATÓRIOS DE LUCRO

  /// Calcula o lucro total de um período
  Future<double> getLucroTotal(DateTime inicio, DateTime fim) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(iv.quantidade * iv.lucroUnitario) as lucroTotal 
      FROM itens_venda iv
      INNER JOIN vendas v ON iv.venda_id = v.id
      WHERE v.dataVenda >= ? AND v.dataVenda <= ?
    ''',
      [inicio.toIso8601String(), fim.toIso8601String()],
    );
    return result.first['lucroTotal'] as double? ?? 0.0;
  }

  /// Calcula o lucro de hoje
  Future<double> getLucroHoje() async {
    final hoje = DateTime.now();
    final dataInicio = DateTime(hoje.year, hoje.month, hoje.day);
    final dataFim = dataInicio.add(const Duration(days: 1));
    return await getLucroTotal(dataInicio, dataFim);
  }

  /// Calcula o lucro do mês atual
  Future<double> getLucroMes() async {
    final agora = DateTime.now();
    final inicioMes = DateTime(agora.year, agora.month, 1);
    final fimMes = DateTime(agora.year, agora.month + 1, 1);
    return await getLucroTotal(inicioMes, fimMes);
  }

  /// Obtém relatório detalhado de lucro por produto
  Future<List<Map<String, dynamic>>> getRelatorioLucroPorProduto(
    DateTime inicio, 
    DateTime fim
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT 
        p.nome as produto,
        p.categoria,
        SUM(iv.quantidade) as quantidadeVendida,
        SUM(iv.quantidade * iv.precoUnitario) as totalVendas,
        SUM(iv.quantidade * iv.custoUnitario) as totalCustos,
        SUM(iv.quantidade * iv.lucroUnitario) as totalLucro,
        AVG(iv.precoUnitario) as precoMedio,
        AVG(iv.custoUnitario) as custoMedio,
        AVG(iv.lucroUnitario) as lucroMedio
      FROM itens_venda iv
      INNER JOIN vendas v ON iv.venda_id = v.id
      INNER JOIN produtos p ON iv.produto_id = p.id
      WHERE v.dataVenda >= ? AND v.dataVenda <= ?
      GROUP BY p.id, p.nome, p.categoria
      ORDER BY totalLucro DESC
    ''',
      [inicio.toIso8601String(), fim.toIso8601String()],
    );
    return result;
  }

  /// Obtém relatório de lucro por categoria
  Future<List<Map<String, dynamic>>> getRelatorioLucroPorCategoria(
    DateTime inicio, 
    DateTime fim
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT 
        COALESCE(p.categoria, 'Sem Categoria') as categoria,
        COUNT(DISTINCT p.id) as totalProdutos,
        SUM(iv.quantidade) as quantidadeVendida,
        SUM(iv.quantidade * iv.precoUnitario) as totalVendas,
        SUM(iv.quantidade * iv.custoUnitario) as totalCustos,
        SUM(iv.quantidade * iv.lucroUnitario) as totalLucro,
        AVG(iv.lucroUnitario) as lucroMedio
      FROM itens_venda iv
      INNER JOIN vendas v ON iv.venda_id = v.id
      INNER JOIN produtos p ON iv.produto_id = p.id
      WHERE v.dataVenda >= ? AND v.dataVenda <= ?
      GROUP BY p.categoria
      ORDER BY totalLucro DESC
    ''',
      [inicio.toIso8601String(), fim.toIso8601String()],
    );
    return result;
  }

  /// Calcula a margem de lucro média de um período
  Future<double> getMargemLucroMedia(DateTime inicio, DateTime fim) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT 
        SUM(iv.quantidade * iv.precoUnitario) as totalVendas,
        SUM(iv.quantidade * iv.lucroUnitario) as totalLucro
      FROM itens_venda iv
      INNER JOIN vendas v ON iv.venda_id = v.id
      WHERE v.dataVenda >= ? AND v.dataVenda <= ?
    ''',
      [inicio.toIso8601String(), fim.toIso8601String()],
    );
    
    final totalVendas = result.first['totalVendas'] as double? ?? 0.0;
    final totalLucro = result.first['totalLucro'] as double? ?? 0.0;
    
    if (totalVendas == 0) return 0.0;
    return (totalLucro / totalVendas) * 100;
  }

  /// Obtém produtos com maior lucro
  Future<List<Map<String, dynamic>>> getProdutosMaisLucrativos(
    DateTime inicio, 
    DateTime fim, 
    {int limit = 10}
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT 
        p.nome as produto,
        p.categoria,
        SUM(iv.quantidade * iv.lucroUnitario) as totalLucro,
        SUM(iv.quantidade) as quantidadeVendida,
        AVG(iv.lucroUnitario) as lucroMedio
      FROM itens_venda iv
      INNER JOIN vendas v ON iv.venda_id = v.id
      INNER JOIN produtos p ON iv.produto_id = p.id
      WHERE v.dataVenda >= ? AND v.dataVenda <= ?
      GROUP BY p.id, p.nome, p.categoria
      ORDER BY totalLucro DESC
      LIMIT ?
    ''',
      [inicio.toIso8601String(), fim.toIso8601String(), limit],
    );
    return result;
  }

  /// Obtém produtos com menor lucro (problemas)
  Future<List<Map<String, dynamic>>> getProdutosMenosLucrativos(
    DateTime inicio, 
    DateTime fim, 
    {int limit = 10}
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT 
        p.nome as produto,
        p.categoria,
        SUM(iv.quantidade * iv.lucroUnitario) as totalLucro,
        SUM(iv.quantidade) as quantidadeVendida,
        AVG(iv.lucroUnitario) as lucroMedio
      FROM itens_venda iv
      INNER JOIN vendas v ON iv.venda_id = v.id
      INNER JOIN produtos p ON iv.produto_id = p.id
      WHERE v.dataVenda >= ? AND v.dataVenda <= ?
      GROUP BY p.id, p.nome, p.categoria
      ORDER BY totalLucro ASC
      LIMIT ?
    ''',
      [inicio.toIso8601String(), fim.toIso8601String(), limit],
    );
    return result;
  }

  Future<double> getFiadosPendentes() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(valorTotal - valorPago) as total FROM fiados 
      WHERE valorPago < valorTotal
    ''');

    return result.first['total'] as double? ?? 0.0;
  }

  Future<int> getEstoqueBaixo([int minimo = 10]) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as total FROM produtos 
      WHERE quantidadeEstoque <= ?
    ''',
      [minimo],
    );

    return result.first['total'] as int? ?? 0;
  }

  // Backup e Restore
  Future<Map<String, dynamic>> exportarDados() async {
    final db = await database;
    final produtos = await db.query('produtos');
    final clientes = await db.query('clientes2');
    final vendas = await db.query('vendas');
    final itensVenda = await db.query('itens_venda');
    final fiados = await db.query('fiados');

    return {
      'produtos': produtos,
      'clientes': clientes,
      'vendas': vendas,
      'itens_venda': itensVenda,
      'fiados': fiados,
      'exportado_em': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importarDados(Map<String, dynamic> dados) async {
    final db = await database;
    await db.transaction((txn) async {
      // Limpar dados existentes
      await txn.delete('itens_venda');
      await txn.delete('vendas');
      await txn.delete('fiados');
      await txn.delete('produtos');
      await txn.delete('clientes2');

      // Inserir novos dados
      for (var produto in dados['produtos']) {
        await txn.insert('produtos', produto);
      }
      for (var cliente in dados['clientes']) {
        await txn.insert('clientes2', cliente);
      }
      for (var venda in dados['vendas']) {
        await txn.insert('vendas', venda);
      }
      for (var item in dados['itens_venda']) {
        await txn.insert('itens_venda', item);
      }
      for (var fiado in dados['fiados']) {
        await txn.insert('fiados', fiado);
      }
    });
  }

  /// Faz backup do banco de dados SQLite para a pasta Documents
  Future<String> backupDatabase() async {
    try {
      // Caminho do banco de dados atual
      final databasesPath = await getDatabasesPath();
      String dbPath = '$databasesPath/app_caderninho_definitivo.db';

      // Pasta Documents
      final Directory documentsDir = await getApplicationDocumentsDirectory();
      String backupPath = '${documentsDir.path}/backup_caderninho.db';

      // Copia o arquivo
      File originalDb = File(dbPath);
      if (await originalDb.exists()) {
        await originalDb.copy(backupPath);
        return backupPath;
      } else {
        throw Exception('Arquivo do banco de dados não encontrado!');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Método para resetar o banco completamente
  Future<void> resetarBanco() async {
    try {
      // Fecha o banco atual
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Apaga o arquivo do banco
      String path = join(await getDatabasesPath(), 'app_caderninho_definitivo.db');
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }

      // Força a recriação
      _database = await _initDatabase();
    } catch (e) {
      print('Erro ao resetar banco: $e');
      rethrow;
    }
  }

  // Método para limpar todos os dados do banco (usado na restauração)
  Future<void> limparBanco() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('adicionais');
      await txn.delete('itens_venda');
      await txn.delete('vendas');
      await txn.delete('fiados');
      await txn.delete('produtos');
      await txn.delete('clientes2');
      await txn.delete('compromissos');
      await txn.delete('casas_aposta');
      await txn.delete('depositos');
      await txn.delete('saques');
      await txn.delete('contas');
      await txn.delete('usuarios');
    });
  }

  // Singleton instance
  static DatabaseService get instance => _instancia;

  /// Inicializa o serviço de banco de dados
  Future<void> inicializar() async {
    await database; // Isso garante que o banco seja inicializado
  }

  // Métodos para Usuários
  Future<void> inserirUsuario(Usuario usuario) async {
    try {
      final db = await database;
      print('🔍 Inserindo usuário: ${usuario.toMap()}');
      
      final result = await db.insert('usuarios', usuario.toMap());
      print('✅ Usuário inserido com sucesso. ID: $result');
    } catch (e) {
      print('❌ Erro ao inserir usuário: $e');
      rethrow;
    }
  }

  Future<void> atualizarUsuario(Usuario usuario) async {
    final db = await database;
    await db.update(
      'usuarios',
      {
        'nome': usuario.nome,
        'email': usuario.email,
        'cargo': usuario.cargo,
        'ativo': usuario.ativo ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [usuario.id],
    );
  }

  Future<bool> alterarSenha(String usuarioId, String senhaAtual, String novaSenha) async {
    final db = await database;
    
    // Verificar senha atual
    final result = await db.query(
      'usuarios',
      where: 'id = ? AND senha = ?',
      whereArgs: [usuarioId, senhaAtual],
    );
    
    if (result.isEmpty) return false;
    
    // Atualizar senha
    await db.update(
      'usuarios',
      {'senha': novaSenha},
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
    
    return true;
  }

  Future<Usuario?> verificarCredenciais(String email, String senha) async {
    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'email = ? AND senha = ? AND ativo = 1',
      whereArgs: [email, senha],
    );
    
    if (result.isEmpty) return null;
    
    return Usuario.fromMap(result.first);
  }

  Future<Usuario?> getUsuarioPorId(String id) async {
    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    
    return Usuario.fromMap(result.first);
  }

  Future<List<Usuario>> getUsuarios() async {
    final db = await database;
    final result = await db.query('usuarios');
    
    return result.map((map) => Usuario.fromMap(map)).toList();
  }

  Future<bool> alterarStatusUsuario(String usuarioId, bool ativo) async {
    final db = await database;
    final count = await db.update(
      'usuarios',
      {'ativo': ativo ? 1 : 0},
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
    
    return count > 0;
  }

  // ===== MÉTODOS PARA CASAS DE APOSTA =====
  
  Future<List<CasaAposta>> getCasasAposta() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('casas_aposta');
    return List.generate(maps.length, (i) => CasaAposta.fromMap(maps[i]));
  }

  Future<void> inserirCasaAposta(CasaAposta casaAposta) async {
    final db = await database;
    await db.insert('casas_aposta', casaAposta.toMap());
  }

  Future<void> atualizarCasaAposta(CasaAposta casaAposta) async {
    final db = await database;
    await db.update(
      'casas_aposta',
      casaAposta.toMap(),
      where: 'id = ?',
      whereArgs: [casaAposta.id],
    );
  }

  Future<void> deletarCasaAposta(String id) async {
    final db = await database;
    await db.delete(
      'casas_aposta',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== MÉTODOS PARA DEPÓSITOS =====
  
  Future<List<Deposito>> getDepositos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('depositos');
    
    List<Deposito> depositos = [];
    for (var map in maps) {
      final casaAposta = await getCasaApostaPorId(map['casaApostaId'] as String);
      if (casaAposta != null) {
        depositos.add(Deposito.fromMap(map, casaAposta));
      }
    }
    
    return depositos;
  }

  Future<void> inserirDeposito(Deposito deposito) async {
    final db = await database;
    await db.insert('depositos', deposito.toMap());
  }

  Future<void> atualizarDeposito(Deposito deposito) async {
    final db = await database;
    await db.update(
      'depositos',
      deposito.toMap(),
      where: 'id = ?',
      whereArgs: [deposito.id],
    );
  }

  Future<void> deletarDeposito(String id) async {
    final db = await database;
    await db.delete(
      'depositos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== MÉTODOS PARA SAQUES =====
  
  Future<List<Saque>> getSaques() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('saques');
    
    List<Saque> saques = [];
    for (var map in maps) {
      final casaAposta = await getCasaApostaPorId(map['casaApostaId'] as String);
      if (casaAposta != null) {
        saques.add(Saque.fromMap(map, casaAposta));
      }
    }
    
    return saques;
  }

  Future<void> inserirSaque(Saque saque) async {
    final db = await database;
    await db.insert('saques', saque.toMap());
  }

  Future<void> atualizarSaque(Saque saque) async {
    final db = await database;
    await db.update(
      'saques',
      saque.toMap(),
      where: 'id = ?',
      whereArgs: [saque.id],
    );
  }

  Future<void> deletarSaque(String id) async {
    final db = await database;
    await db.delete(
      'saques',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== MÉTODOS AUXILIARES =====
  
  Future<CasaAposta?> getCasaApostaPorId(String id) async {
    final db = await database;
    final result = await db.query(
      'casas_aposta',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    return CasaAposta.fromMap(result.first);
  }

  // ===== MÉTODOS PARA RELATÓRIOS =====
  
  Future<Map<String, dynamic>> getRelatorioCassino({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? casaApostaId,
  }) async {
    final db = await database;
    
    // Buscar depósitos
    String whereDepositos = '1=1';
    List<dynamic> argsDepositos = [];
    
    if (dataInicio != null) {
      whereDepositos += ' AND data >= ?';
      argsDepositos.add(dataInicio.toIso8601String());
    }
    if (dataFim != null) {
      whereDepositos += ' AND data <= ?';
      argsDepositos.add(dataFim.toIso8601String());
    }
    if (casaApostaId != null) {
      whereDepositos += ' AND casaApostaId = ?';
      argsDepositos.add(casaApostaId);
    }
    
    final depositos = await db.query('depositos', where: whereDepositos, whereArgs: argsDepositos);
    
    // Buscar saques
    String whereSaques = '1=1';
    List<dynamic> argsSaques = [];
    
    if (dataInicio != null) {
      whereSaques += ' AND data >= ?';
      argsSaques.add(dataInicio.toIso8601String());
    }
    if (dataFim != null) {
      whereSaques += ' AND data <= ?';
      argsSaques.add(dataFim.toIso8601String());
    }
    if (casaApostaId != null) {
      whereSaques += ' AND casaApostaId = ?';
      argsSaques.add(casaApostaId);
    }
    
    final saques = await db.query('saques', where: whereSaques, whereArgs: argsSaques);
    
    // Calcular totais
    double totalDepositos = 0;
    double totalSaques = 0;
    
    for (var deposito in depositos) {
      totalDepositos += (deposito['valor'] as num).toDouble();
    }
    
    for (var saque in saques) {
      totalSaques += (saque['valor'] as num).toDouble();
    }
    
    return {
      'totalDepositos': totalDepositos,
      'totalSaques': totalSaques,
      'saldo': totalSaques - totalDepositos,
      'depositos': depositos,
      'saques': saques,
    };
  }
}