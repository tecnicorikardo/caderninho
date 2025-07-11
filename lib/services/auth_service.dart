import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  Usuario? _usuarioAtual;
  bool _isLoggedIn = false;

  // Getters
  Usuario? get usuarioAtual => _usuarioAtual;
  bool get isLoggedIn => _isLoggedIn;

  /// Inicializa o serviço de autenticação
  Future<void> inicializar() async {
    await _carregarSessao();
  }

  /// Carrega a sessão salva
  Future<void> _carregarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getString('usuario_id');
    
    if (usuarioId != null) {
      try {
        final db = DatabaseService.instance;
        final usuario = await db.getUsuarioPorId(usuarioId);
        if (usuario != null && usuario.ativo) {
          _usuarioAtual = usuario;
          _isLoggedIn = true;
        }
      } catch (e) {
        print('Erro ao carregar sessão: $e');
      }
    }
  }

  /// Salva as credenciais lembradas
  Future<void> salvarCredenciaisLembradas(String email, String senha, bool lembrarDados) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (lembrarDados) {
      await prefs.setString('lembrar_email', email);
      await prefs.setString('lembrar_senha', senha);
      await prefs.setBool('lembrar_dados', true);
    } else {
      await prefs.remove('lembrar_email');
      await prefs.remove('lembrar_senha');
      await prefs.setBool('lembrar_dados', false);
    }
  }

  /// Recupera as credenciais lembradas
  Future<Map<String, dynamic>> getCredenciaisLembradas() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('lembrar_email') ?? '',
      'senha': prefs.getString('lembrar_senha') ?? '',
      'lembrarDados': prefs.getBool('lembrar_dados') ?? false,
    };
  }

  /// Limpa as credenciais lembradas
  Future<void> limparCredenciaisLembradas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lembrar_email');
    await prefs.remove('lembrar_senha');
    await prefs.setBool('lembrar_dados', false);
  }

  /// Faz login do usuário
  Future<bool> fazerLogin(String email, String senha, bool lembrarDados) async {
    try {
      final db = DatabaseService.instance;
      final usuario = await db.verificarCredenciais(email, senha);
      
      if (usuario != null && usuario.ativo) {
        _usuarioAtual = usuario;
        _isLoggedIn = true;
        
        // Salvar sessão
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario_id', usuario.id);
        await prefs.setString('usuario_nome', usuario.nome);
        
        // Salvar ou limpar credenciais lembradas
        await salvarCredenciaisLembradas(email, senha, lembrarDados);
        
        return true;
      }
      return false;
    } catch (e) {
      print('Erro no login: $e');
      return false;
    }
  }

  /// Faz logout do usuário
  Future<void> fazerLogout() async {
    _usuarioAtual = null;
    _isLoggedIn = false;
    
    // Limpar sessão (mas manter credenciais lembradas se o usuário escolheu)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuario_id');
    await prefs.remove('usuario_nome');
  }

  /// Cria um novo usuário
  Future<bool> criarUsuario(Usuario usuario) async {
    try {
      final db = DatabaseService.instance;
      await db.inserirUsuario(usuario);
      return true;
    } catch (e) {
      print('Erro ao criar usuário: $e');
      return false;
    }
  }

  /// Atualiza dados do usuário
  Future<bool> atualizarUsuario(Usuario usuario) async {
    try {
      final db = DatabaseService.instance;
      await db.atualizarUsuario(usuario);
      
      // Se for o usuário atual, atualizar na sessão
      if (_usuarioAtual?.id == usuario.id) {
        _usuarioAtual = usuario;
      }
      
      return true;
    } catch (e) {
      print('Erro ao atualizar usuário: $e');
      return false;
    }
  }

  /// Altera senha do usuário
  Future<bool> alterarSenha(String senhaAtual, String novaSenha) async {
    if (_usuarioAtual == null) return false;
    
    try {
      final db = DatabaseService.instance;
      final sucesso = await db.alterarSenha(_usuarioAtual!.id, senhaAtual, novaSenha);
      
      if (sucesso) {
        _usuarioAtual = _usuarioAtual!.copyWith(senha: novaSenha);
      }
      
      return sucesso;
    } catch (e) {
      print('Erro ao alterar senha: $e');
      return false;
    }
  }

  /// Verifica se o usuário tem permissão
  bool temPermissao(String permissao) {
    if (_usuarioAtual == null) return false;
    
    // Sistema simples de permissões baseado no cargo
    switch (_usuarioAtual!.cargo.toLowerCase()) {
      case 'admin':
        return true; // Admin tem todas as permissões
      case 'gerente':
        return permissao != 'admin'; // Gerente tem todas exceto admin
      case 'vendedor':
        return ['vendas', 'clientes', 'produtos'].contains(permissao);
      default:
        return false;
    }
  }

  /// Lista todos os usuários (apenas admin)
  Future<List<Usuario>> listarUsuarios() async {
    try {
      print('🔍 Listando usuários...');
      final db = DatabaseService.instance;
      final usuarios = await db.getUsuarios();
      print('✅ Usuários encontrados: ${usuarios.length}');
      return usuarios;
    } catch (e) {
      print('❌ Erro ao listar usuários: $e');
      return [];
    }
  }

  /// Desativa/ativa um usuário
  Future<bool> alterarStatusUsuario(String usuarioId, bool ativo) async {
    if (!temPermissao('admin')) {
      throw Exception('Permissão negada');
    }
    
    try {
      final db = DatabaseService.instance;
      return await db.alterarStatusUsuario(usuarioId, ativo);
    } catch (e) {
      print('Erro ao alterar status do usuário: $e');
      return false;
    }
  }
} 