import 'package:sqflite/sqflite.dart';
import '../models/conta.dart';
import 'database_service.dart';
import 'notification_service.dart';

class ContasService {
  static final ContasService _instance = ContasService._internal();
  factory ContasService() => _instance;
  ContasService._internal();
  
  static ContasService get instance => _instance;

  Future<Database> get _db async => await DatabaseService().database;

  // ==================== CONTAS ====================

  Future<List<Conta>> getContas() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('contas');
    return List.generate(maps.length, (i) => Conta.fromMap(maps[i]));
  }

  Future<List<Conta>> getContasPendentes() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'contas',
      where: 'status = ?',
      whereArgs: [StatusConta.pendente.index],
      orderBy: 'vencimento ASC',
    );
    return List.generate(maps.length, (i) => Conta.fromMap(maps[i]));
  }

  Future<List<Conta>> getContasVencidas() async {
    final agora = DateTime.now().millisecondsSinceEpoch;
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'contas',
      where: 'status = ? AND vencimento < ?',
      whereArgs: [StatusConta.pendente.index, agora],
      orderBy: 'vencimento ASC',
    );
    return List.generate(maps.length, (i) => Conta.fromMap(maps[i]));
  }

  Future<List<Conta>> getContasDoMes([DateTime? mes]) async {
    final mesConsulta = mes ?? DateTime.now();
    final inicioMes = DateTime(mesConsulta.year, mesConsulta.month, 1);
    final fimMes = DateTime(mesConsulta.year, mesConsulta.month + 1, 0);
    
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'contas',
      where: 'vencimento >= ? AND vencimento <= ?',
      whereArgs: [
        inicioMes.millisecondsSinceEpoch,
        fimMes.millisecondsSinceEpoch
      ],
      orderBy: 'vencimento ASC',
    );
    return List.generate(maps.length, (i) => Conta.fromMap(maps[i]));
  }

  Future<void> inserirConta(Conta conta) async {
    try {
      print('🔍 Debug ContasService: Iniciando inserção de conta...');
      print('🔍 Debug ContasService: Dados da conta: ${conta.toMap()}');
      
      final db = await _db;
      print('🔍 Debug ContasService: Banco de dados obtido');
      
      // Verificar se a tabela existe
      final tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'contas']);
      print('🔍 Debug ContasService: Tabelas encontradas: ${tables.length}');
      
      if (tables.isEmpty) {
        throw Exception('Tabela contas não existe!');
      }
      
      // Verificar estrutura da tabela
      final columns = await db.rawQuery("PRAGMA table_info(contas)");
      print('🔍 Debug ContasService: Colunas da tabela contas:');
      for (var column in columns) {
        print('  - ${column['name']}: ${column['type']}');
      }
      
      final result = await db.insert('contas', conta.toMap());
      print('🔍 Debug ContasService: Conta inserida com sucesso! ID: $result');
      
      // Agendar notificações de vencimento
      if (conta.status == StatusConta.pendente) {
        await NotificationService.instance.agendarNotificacaoConta(conta);
      }
      
    } catch (e) {
      print('❌ Erro ContasService ao inserir conta: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> atualizarConta(Conta conta) async {
    final db = await _db;
    
    // Cancela notificações antigas
    await NotificationService.instance.cancelarNotificacaoConta(conta.id);
    
    await db.update(
      'contas',
      conta.toMap(),
      where: 'id = ?',
      whereArgs: [conta.id],
    );
    
    // Reagenda notificações se conta ainda estiver pendente
    if (conta.status == StatusConta.pendente) {
      await NotificationService.instance.agendarNotificacaoConta(conta);
    }
  }

  Future<void> marcarContaComoPaga(String contaId) async {
    final db = await _db;
    
    // Cancela notificações da conta
    await NotificationService.instance.cancelarNotificacaoConta(contaId);
    
    await db.update(
      'contas',
      {
        'status': StatusConta.pago.index,
        'dataPagamento': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [contaId],
    );
  }

  Future<void> deletarConta(String contaId) async {
    final db = await _db;
    
    // Cancela notificações da conta
    await NotificationService.instance.cancelarNotificacaoConta(contaId);
    
    await db.delete('contas', where: 'id = ?', whereArgs: [contaId]);
  }



  // ==================== RESUMOS E ESTATÍSTICAS ====================

  Future<double> getTotalContasPendentes() async {
    final contas = await getContasPendentes();
    double total = 0.0;
    for (var conta in contas) {
      total += conta.valor;
    }
    return total;
  }

  Future<double> getTotalContasVencidas() async {
    final contas = await getContasVencidas();
    double total = 0.0;
    for (var conta in contas) {
      total += conta.valor;
    }
    return total;
  }

  Future<Map<String, dynamic>> getResumoFinanceiro() async {
    final totalPendentes = await getTotalContasPendentes();
    final totalVencidas = await getTotalContasVencidas();
    
    final contasPendentes = await getContasPendentes();
    final contasVencidas = await getContasVencidas();
    
    return {
      'totalContasPendentes': totalPendentes,
      'totalContasVencidas': totalVencidas,
      'quantidadeContasPendentes': contasPendentes.length,
      'quantidadeContasVencidas': contasVencidas.length,
      'totalGeral': totalPendentes + totalVencidas,
    };
  }

  // ==================== TESTES E DEBUG ====================

  Future<void> testarInsercaoConta() async {
    try {
      print('🧪 Teste: Iniciando teste de inserção de conta...');
      
      // Criar uma conta de teste
      final contaTeste = Conta(
        nome: 'Conta Teste',
        valor: 100.0,
        vencimento: DateTime.now().add(const Duration(days: 30)),
        observacoes: 'Teste de funcionalidade',
      );
      
      print('🧪 Teste: Conta de teste criada: ${contaTeste.toMap()}');
      
      // Tentar inserir
      await inserirConta(contaTeste);
      
      print('🧪 Teste: Conta inserida com sucesso!');
      
      // Verificar se foi inserida
      final contas = await getContas();
      print('🧪 Teste: Total de contas no banco: ${contas.length}');
      
      final contaEncontrada = contas.where((c) => c.nome == 'Conta Teste').firstOrNull;
      if (contaEncontrada != null) {
        print('🧪 Teste: Conta encontrada no banco: ${contaEncontrada.toMap()}');
      } else {
        print('❌ Teste: Conta não foi encontrada no banco!');
      }
      
    } catch (e) {
      print('❌ Teste: Erro no teste de inserção: $e');
      rethrow;
    }
  }

  Future<void> verificarEstruturaBanco() async {
    try {
      print('🔍 Verificando estrutura do banco...');
      
      final db = await _db;
      
      // Verificar tabelas existentes
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      print('🔍 Tabelas encontradas:');
      for (var table in tables) {
        print('  - ${table['name']}');
      }
      
      // Verificar estrutura da tabela contas
      if (tables.any((t) => t['name'] == 'contas')) {
        final columns = await db.rawQuery("PRAGMA table_info(contas)");
        print('🔍 Estrutura da tabela contas:');
        for (var column in columns) {
          print('  - ${column['name']}: ${column['type']}');
        }
      } else {
        print('❌ Tabela contas não encontrada!');
      }
      
    } catch (e) {
      print('❌ Erro ao verificar estrutura: $e');
      rethrow;
    }
  }



} 