import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_service.dart';
import '../models/cliente.dart';
import '../models/produto.dart';
import '../models/venda.dart';
import '../models/fiado.dart';
import '../models/compromisso.dart';
import '../models/casa_aposta.dart';
import '../models/deposito.dart';
import '../models/saque.dart';
import '../models/conta.dart';
import '../models/usuario.dart';
import 'agenda_service.dart';
import 'contas_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static BackupService get instance => _instance;

  /// Solicita permissões para acessar o armazenamento
  Future<bool> _solicitarPermissoes() async {
    if (Platform.isAndroid) {
      // Para Android 11+ (API 30+)
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      
      // Tentar permissão de gerenciamento de armazenamento externo
      if (await Permission.manageExternalStorage.isDenied) {
        final result = await Permission.manageExternalStorage.request();
        if (result.isGranted) {
          return true;
        }
      }
      
      // Fallback para permissões antigas
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      
      return storageStatus.isGranted;
    }
    return true; // iOS não precisa de permissões específicas
  }

  /// Faz backup de todos os dados do banco
  Future<String> fazerBackup() async {
    try {
      final db = DatabaseService.instance;
      
      // Buscar todos os dados
      final clientes = await db.getClientes();
      final produtos = await db.getProdutos();
      final vendas = await db.getVendas();
      final fiados = await db.getFiados();
      final compromissos = await AgendaService().buscarCompromissos();
      
      // Dados que estavam faltando
      final casasAposta = await db.getCasasAposta();
      final depositos = await db.getDepositos();
      final saques = await db.getSaques();
      final usuarios = await db.getUsuarios();
      
      // Buscar contas
      final contasService = ContasService.instance;
      final contas = await contasService.getContas();

      // Criar estrutura de backup
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'versao': '1.0.0',
        'clientes': clientes.map((c) => c.toMap()).toList(),
        'produtos': produtos.map((p) => p.toMap()).toList(),
        'vendas': vendas.map((v) => v.toMap()).toList(),
        'fiados': fiados.map((f) => f.toMap()).toList(),
        'compromissos': compromissos.map((c) => c.toMap()).toList(),
        'casasAposta': casasAposta.map((c) => c.toMap()).toList(),
        'depositos': depositos.map((d) => d.toMap()).toList(),
        'saques': saques.map((s) => s.toMap()).toList(),
        'contas': contas.map((c) => c.toMap()).toList(),
        'usuarios': usuarios.map((u) => u.toMap()).toList(),
      };

      // Converter para JSON
      final jsonData = jsonEncode(backupData);

      // Tentar salvar no diretório público primeiro
      try {
        final temPermissao = await _solicitarPermissoes();
        if (temPermissao) {
          final directory = await _getPublicBackupDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'backup_caderninho_$timestamp.json';
          final file = File(path.join(directory.path, fileName));
          
          await file.writeAsString(jsonData);
          return file.path;
        }
      } catch (e) {
        print('Erro ao salvar no diretório público: $e');
      }
      
      // Fallback: salvar no diretório privado mas acessível
      final directory = await _getPrivateBackupDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'backup_caderninho_$timestamp.json';
      final file = File(path.join(directory.path, fileName));
      
      await file.writeAsString(jsonData);
      return file.path;
    } catch (e) {
      throw Exception('Erro ao fazer backup: $e');
    }
  }

  /// Restaura backup de um arquivo
  Future<void> restaurarBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Arquivo de backup não encontrado');
      }

      // Ler arquivo
      final jsonData = await file.readAsString();
      final backupData = jsonDecode(jsonData) as Map<String, dynamic>;

      // Validar versão
      final versao = backupData['versao'] as String;
      if (versao != '1.0.0') {
        throw Exception('Versão de backup não suportada: $versao');
      }

      final db = DatabaseService.instance;
      final contasService = ContasService.instance;

      // Limpar banco atual
      await db.limparBanco();

      // Restaurar clientes
      final clientesData = (backupData['clientes'] ?? []) as List;
      for (final clienteData in clientesData) {
        final cliente = Cliente.fromMap(clienteData);
        await db.inserirCliente(cliente);
      }

      // Restaurar produtos
      final produtosData = (backupData['produtos'] ?? []) as List;
      for (final produtoData in produtosData) {
        final produto = Produto.fromMap(produtoData);
        await db.inserirProduto(produto);
      }

      // Restaurar vendas
      final vendasData = (backupData['vendas'] ?? []) as List;
      for (final vendaData in vendasData) {
        final venda = Venda.fromMap(vendaData);
        await db.inserirVenda(venda);
      }

      // Restaurar fiados
      final fiadosData = (backupData['fiados'] ?? []) as List;
      for (final fiadoData in fiadosData) {
        final fiado = Fiado.fromMap(fiadoData);
        await db.inserirFiado(fiado);
      }

      // Restaurar compromissos
      final compromissosData = (backupData['compromissos'] ?? []) as List;
      for (final compromissoData in compromissosData) {
        final compromisso = Compromisso.fromMap(compromissoData);
        await AgendaService().adicionarCompromisso(compromisso);
      }

      // Restaurar casas de aposta
      final casasApostaData = (backupData['casasAposta'] ?? []) as List;
      for (final casaData in casasApostaData) {
        final casa = CasaAposta.fromMap(casaData);
        await db.inserirCasaAposta(casa);
      }

      // Restaurar depósitos
      final depositosData = (backupData['depositos'] ?? []) as List;
      for (final depositoData in depositosData) {
        try {
          // Buscar a casa de aposta correspondente
          final casaApostaId = depositoData['casaApostaId'] as String;
          final casaAposta = await db.getCasaApostaPorId(casaApostaId);
          
          if (casaAposta != null) {
            final deposito = Deposito.fromMap(depositoData, casaAposta);
            await db.inserirDeposito(deposito);
          } else {
            print('Casa de aposta não encontrada para depósito: $casaApostaId');
          }
        } catch (e) {
          print('Erro ao restaurar depósito: $e');
        }
      }

      // Restaurar saques
      final saquesData = (backupData['saques'] ?? []) as List;
      for (final saqueData in saquesData) {
        try {
          // Buscar a casa de aposta correspondente
          final casaApostaId = saqueData['casaApostaId'] as String;
          final casaAposta = await db.getCasaApostaPorId(casaApostaId);
          
          if (casaAposta != null) {
            final saque = Saque.fromMap(saqueData, casaAposta);
            await db.inserirSaque(saque);
          } else {
            print('Casa de aposta não encontrada para saque: $casaApostaId');
          }
        } catch (e) {
          print('Erro ao restaurar saque: $e');
        }
      }

      // Restaurar contas
      final contasData = (backupData['contas'] ?? []) as List;
      for (final contaData in contasData) {
        final conta = Conta.fromMap(contaData);
        await contasService.inserirConta(conta);
      }

      // Restaurar usuários
      final usuariosData = (backupData['usuarios'] ?? []) as List;
      for (final usuarioData in usuariosData) {
        final usuario = Usuario.fromMap(usuarioData);
        await db.inserirUsuario(usuario);
      }
    } catch (e) {
      throw Exception('Erro ao restaurar backup: $e');
    }
  }

  /// Lista todos os backups disponíveis
  Future<List<BackupInfo>> listarBackups() async {
    try {
      final backups = <BackupInfo>[];
      
      // Verificar diretório público primeiro
      try {
        final publicDirectory = await _getPublicBackupDirectory();
        if (await publicDirectory.exists()) {
          final publicBackups = await _getBackupsFromDirectory(publicDirectory);
          backups.addAll(publicBackups);
        }
      } catch (e) {
        print('Erro ao listar backups públicos: $e');
      }
      
      // Verificar diretório privado
      try {
        final privateDirectory = await _getPrivateBackupDirectory();
        if (await privateDirectory.exists()) {
          final privateBackups = await _getBackupsFromDirectory(privateDirectory);
          backups.addAll(privateBackups);
        }
      } catch (e) {
        print('Erro ao listar backups privados: $e');
      }

      // Remover duplicatas e ordenar por data
      final backupMap = <String, BackupInfo>{};
      for (final backup in backups) {
        backupMap[backup.nomeArquivo] = backup;
      }
      
      final uniqueBackups = backupMap.values.toList();
      uniqueBackups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return uniqueBackups;
    } catch (e) {
      throw Exception('Erro ao listar backups: $e');
    }
  }

  /// Obtém backups de um diretório específico
  Future<List<BackupInfo>> _getBackupsFromDirectory(Directory directory) async {
    final files = directory.listSync()
        .whereType<File>()
        .where((file) => path.basename(file.path).startsWith('backup_caderninho_'))
        .toList();

    final backups = <BackupInfo>[];
    for (final file in files) {
      try {
        final jsonData = await file.readAsString();
        final backupData = jsonDecode(jsonData) as Map<String, dynamic>;
        
        backups.add(BackupInfo(
          path: file.path,
          timestamp: DateTime.parse(backupData['timestamp']),
          tamanho: await file.length(),
          clientes: (backupData['clientes'] as List).length,
          produtos: (backupData['produtos'] as List).length,
          vendas: (backupData['vendas'] as List).length,
          fiados: (backupData['fiados'] as List).length,
          compromissos: (backupData['compromissos'] as List).length,
          casasAposta: (backupData['casasAposta'] as List).length,
          depositos: (backupData['depositos'] as List).length,
          saques: (backupData['saques'] as List).length,
          contas: (backupData['contas'] as List).length,
          usuarios: (backupData['usuarios'] as List).length,
        ));
      } catch (e) {
        // Ignorar arquivos corrompidos
        print('Arquivo de backup corrompido: ${file.path}');
      }
    }
    
    return backups;
  }

  /// Deleta um backup específico
  Future<void> deletarBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Erro ao deletar backup: $e');
    }
  }

  /// Obtém o diretório público de backup (Downloads)
  Future<Directory> _getPublicBackupDirectory() async {
    Directory? downloadsDir;
    
    if (Platform.isAndroid) {
      // Para Android, tenta usar a pasta Downloads
      downloadsDir = Directory('/storage/emulated/0/Download');
      
      // Se não existir, tenta a pasta externa
      if (!await downloadsDir.exists()) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          downloadsDir = Directory(path.join(externalDir.path, 'Download'));
        }
      }
    } else {
      // Para iOS, usa Documents (que é acessível via iTunes)
      downloadsDir = await getApplicationDocumentsDirectory();
    }
    
    // Fallback se Downloads não funcionar
    downloadsDir ??= await getApplicationDocumentsDirectory();
    
    // Criar subpasta CaderninhoBackups
    final backupDir = Directory(path.join(downloadsDir.path, 'CaderninhoBackups'));
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }

  /// Obtém o diretório privado de backup (acessível via file picker)
  Future<Directory> _getPrivateBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(appDir.path, 'CaderninhoBackups'));
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }
}

/// Informações sobre um backup
class BackupInfo {
  final String path;
  final DateTime timestamp;
  final int tamanho;
  final int clientes;
  final int produtos;
  final int vendas;
  final int fiados;
  final int compromissos;
  final int casasAposta;
  final int depositos;
  final int saques;
  final int contas;
  final int usuarios;

  BackupInfo({
    required this.path,
    required this.timestamp,
    required this.tamanho,
    required this.clientes,
    required this.produtos,
    required this.vendas,
    required this.fiados,
    required this.compromissos,
    required this.casasAposta,
    required this.depositos,
    required this.saques,
    required this.contas,
    required this.usuarios,
  });

  String get nomeArquivo => path.split('/').last;
  
  String get dataFormatada {
    return '${timestamp.day.toString().padLeft(2, '0')}/'
           '${timestamp.month.toString().padLeft(2, '0')}/'
           '${timestamp.year} às '
           '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get tamanhoFormatado {
    if (tamanho < 1024) return '$tamanho B';
    if (tamanho < 1024 * 1024) return '${(tamanho / 1024).toStringAsFixed(1)} KB';
    return '${(tamanho / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
} 