/// Configurações da aplicação
class AppConfig {
  // 🎯 CONFIGURAÇÃO PARA VERSÃO VITALÍCIA
  
  /// Tipo de licença do app
  /// true = Trial com limite de dias
  /// false = Vitalício (sem limite)
  static const bool isTrial = true;
  
  /// Duração do trial em dias (usado apenas se isTrial = true)
  /// 365 = 1 ano
  /// 30 = 1 mês
  /// 7 = 1 semana
  static const int trialDurationDays = 365;
  
  /// Mostrar botão de resetar trial (apenas se isTrial = true)
  /// true = Cliente pode resetar trial
  /// false = Cliente NÃO pode resetar trial
  static const bool allowTrialReset = true;
  
  /// Nome da versão (para identificação)
  static const String versionName = isTrial ? 'Trial' : 'Vitalício';
  
  /// Descrição da versão
  static const String versionDescription = isTrial 
    ? 'Versão de experiência com $trialDurationDays dias'
    : 'Versão vitalícia sem limitações';
  
  /// Mensagens personalizadas baseadas no tipo
  static const String expirationMessage = isTrial
    ? 'Seu período de experiência expirou. Renove para continuar usando o app.'
    : 'Acesso vitalício ativo. Sem limitações!';
  
  static const String renewalMessage = isTrial
    ? 'Trial renovado com sucesso! Mais tempo de experiência.'
    : 'Acesso vitalício confirmado!';
  
  static const String resetMessage = isTrial
    ? 'Trial resetado! Agora você tem $trialDurationDays dias completos.'
    : 'Configurações resetadas. Acesso vitalício mantido.';
  
  /// Duração efetiva (999999 dias = praticamente vitalício)
  static int get effectiveDurationDays => isTrial ? trialDurationDays : 999999;
  
  /// Verificar se deve mostrar funcionalidades de trial
  static bool get shouldShowTrialFeatures => isTrial;
  
  /// Verificar se deve pular verificação de expiração
  static bool get shouldSkipExpiration => !isTrial;
  
  /// Verificar se deve mostrar botão de resetar trial
  static bool get shouldShowTrialReset => isTrial && allowTrialReset;
} 
