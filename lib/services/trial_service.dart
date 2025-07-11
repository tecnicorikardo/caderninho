import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class TrialService {
  static final TrialService _instance = TrialService._internal();
  factory TrialService() => _instance;
  TrialService._internal();

  static TrialService get instance => _instance;

  // Duração do trial baseada na configuração
  static int get _trialDurationDays => AppConfig.effectiveDurationDays;
  
  // Chaves para SharedPreferences
  static const String _keyDataInstalacao = 'data_instalacao';
  static const String _keyTrialRenovado = 'trial_renovado';
  static const String _keyAvisoMostrado = 'aviso_mostrado';

  DateTime? _dataInstalacao;
  bool _trialRenovado = false;

  /// Inicializa o serviço de trial
  Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Recupera data de instalação
    final dataInstalacaoMillis = prefs.getInt(_keyDataInstalacao);
    if (dataInstalacaoMillis != null) {
      _dataInstalacao = DateTime.fromMillisecondsSinceEpoch(dataInstalacaoMillis);
    } else {
      // Primeira vez - salva data atual como data de instalação
      _dataInstalacao = DateTime.now();
      await _salvarDataInstalacao();
    }

    // Recupera se trial foi renovado
    _trialRenovado = prefs.getBool(_keyTrialRenovado) ?? false;
  }

  /// Salva a data de instalação
  Future<void> _salvarDataInstalacao() async {
    if (_dataInstalacao == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDataInstalacao, _dataInstalacao!.millisecondsSinceEpoch);
  }

  /// Verifica se o trial está expirado
  bool get isTrialExpirado {
    // Se é vitalício, nunca expira
    if (AppConfig.shouldSkipExpiration) return false;
    
    if (_dataInstalacao == null) return false;
    
    final agora = DateTime.now();
    final diferenca = agora.difference(_dataInstalacao!);
    
    return diferenca.inDays >= _trialDurationDays;
  }

  /// Calcula quantos dias restam do trial
  int get diasRestantes {
    // Se é vitalício, sempre retorna um valor alto
    if (AppConfig.shouldSkipExpiration) return 999999;
    
    if (_dataInstalacao == null) return _trialDurationDays;
    
    final agora = DateTime.now();
    final diferenca = agora.difference(_dataInstalacao!);
    final diasRestantes = _trialDurationDays - diferenca.inDays;
    
    return diasRestantes > 0 ? diasRestantes : 0;
  }

  /// Verifica se deve mostrar aviso de expiração
  bool get deveExibirAviso {
    // Se é vitalício, nunca mostra aviso
    if (AppConfig.shouldSkipExpiration) return false;
    
    if (isTrialExpirado) return true;
    
    final diasRestantes = this.diasRestantes;
    
    // Mostrar aviso nos últimos 30 dias
    return diasRestantes <= 30;
  }

  /// Retorna o tipo de aviso baseado nos dias restantes
  String get tipoAviso {
    if (!AppConfig.shouldShowTrialFeatures) return 'vitalicio';
    
    if (isTrialExpirado) return 'expirado';
    
    final diasRestantes = this.diasRestantes;
    
    if (diasRestantes <= 1) return 'critico';  // Último dia
    if (diasRestantes <= 7) return 'urgente';  // Última semana
    if (diasRestantes <= 30) return 'aviso';   // Último mês
    
    return 'normal';
  }

  /// Retorna mensagem de aviso personalizada
  String get mensagemAviso {
    // Se é vitalício, retorna mensagem personalizada
    if (AppConfig.shouldSkipExpiration) {
      return 'Acesso vitalício ativo. Aproveite todas as funcionalidades!';
    }
    
    final diasRestantes = this.diasRestantes;
    
    if (isTrialExpirado) {
      return AppConfig.expirationMessage;
    }
    
    if (diasRestantes == 1) {
      return 'Seu período de experiência expira amanhã! Renove agora.';
    }
    
    if (diasRestantes <= 7) {
      return 'Seu período de experiência expira em $diasRestantes dias. Renove em breve.';
    }
    
    return 'Seu período de experiência expira em $diasRestantes dias.';
  }

  /// Data de instalação formatada
  String get dataInstalacaoFormatada {
    if (_dataInstalacao == null) return 'Não definida';
    
    return '${_dataInstalacao!.day.toString().padLeft(2, '0')}/'
           '${_dataInstalacao!.month.toString().padLeft(2, '0')}/'
           '${_dataInstalacao!.year}';
  }

  /// Data de expiração formatada
  String get dataExpiracaoFormatada {
    if (_dataInstalacao == null) return 'Não definida';
    
    // Se é vitalício, retorna mensagem especial
    if (AppConfig.shouldSkipExpiration) {
      return 'Nunca (Vitalício)';
    }
    
    final dataExpiracao = _dataInstalacao!.add(Duration(days: _trialDurationDays));
    
    return '${dataExpiracao.day.toString().padLeft(2, '0')}/'
           '${dataExpiracao.month.toString().padLeft(2, '0')}/'
           '${dataExpiracao.year}';
  }

  /// Renova o trial (adiciona mais tempo ou confirma vitalício)
  Future<void> renovarTrial() async {
    _dataInstalacao = DateTime.now();
    _trialRenovado = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDataInstalacao, _dataInstalacao!.millisecondsSinceEpoch);
    await prefs.setBool(_keyTrialRenovado, true);
    
    // Limpa avisos mostrados
    await prefs.remove(_keyAvisoMostrado);
  }

  /// Marca que o aviso foi mostrado hoje
  Future<void> marcarAvisoMostrado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvisoMostrado, DateTime.now().toIso8601String());
  }

  /// Verifica se já mostrou aviso hoje
  Future<bool> jaExibiuAvisoHoje() async {
    final prefs = await SharedPreferences.getInstance();
    final avisoMostrado = prefs.getString(_keyAvisoMostrado);
    
    if (avisoMostrado == null) return false;
    
    final dataAviso = DateTime.tryParse(avisoMostrado);
    if (dataAviso == null) return false;
    
    final agora = DateTime.now();
    final isMesmaData = dataAviso.year == agora.year &&
                        dataAviso.month == agora.month &&
                        dataAviso.day == agora.day;
    
    return isMesmaData;
  }

  /// Reseta o trial (apenas para desenvolvimento/teste)
  Future<void> resetarTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDataInstalacao);
    await prefs.remove(_keyTrialRenovado);
    await prefs.remove(_keyAvisoMostrado);
    
    _dataInstalacao = null;
    _trialRenovado = false;
    
    // Reinicializa
    await inicializar();
  }

  /// Informações completas do trial
  Map<String, dynamic> get infoTrial {
    return {
      'dataInstalacao': dataInstalacaoFormatada,
      'dataExpiracao': dataExpiracaoFormatada,
      'diasRestantes': diasRestantes,
      'isExpirado': isTrialExpirado,
      'tipoAviso': tipoAviso,
      'mensagemAviso': mensagemAviso,
      'trialRenovado': _trialRenovado,
      'tipoLicenca': AppConfig.versionName,
      'isVitalicio': AppConfig.shouldSkipExpiration,
    };
  }
} 
