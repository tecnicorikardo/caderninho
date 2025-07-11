import 'package:flutter/material.dart';
import '../services/trial_service.dart';
import '../config/app_config.dart';

class TelaTrialExperiencia extends StatefulWidget {
  const TelaTrialExperiencia({super.key});

  @override
  State<TelaTrialExperiencia> createState() => _TelaTrialExperienciaState();
}

class _TelaTrialExperienciaState extends State<TelaTrialExperiencia> {
  final TrialService _trialService = TrialService.instance;
  Map<String, dynamic> _trialInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarInformacoes();
  }

  Future<void> _carregarInformacoes() async {
    setState(() {
      _trialInfo = _trialService.infoTrial;
    });
  }

  Future<void> _renovarTrial() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _trialService.renovarTrial();
      await _carregarInformacoes();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppConfig.renewalMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao renovar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpirado = _trialInfo['isExpirado'] == true;
    final isVitalicio = _trialInfo['isVitalicio'] == true;
    final diasRestantes = _trialInfo['diasRestantes'] ?? 0;
    final tipoAviso = _trialInfo['tipoAviso'] ?? 'normal';
    
    Color corTema = Colors.blue;
    if (isVitalicio) {
      corTema = Colors.green;
    } else if (isExpirado) {
      corTema = Colors.red;
    } else if (tipoAviso == 'critico') {
      corTema = Colors.red;
    } else if (tipoAviso == 'urgente') {
      corTema = Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isVitalicio ? 'Licença Vitalícia' : 'Trial - Experiência'),
        backgroundColor: corTema,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              corTema.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone principal
                Icon(
                  isVitalicio ? Icons.verified : (isExpirado ? Icons.error : Icons.timer),
                  size: 80,
                  color: corTema,
                ),
                const SizedBox(height: 24),
                
                // Título
                Text(
                  isVitalicio ? 'Acesso Vitalício' : (isExpirado ? 'Trial Expirado' : 'Trial Ativo'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: corTema,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Subtítulo
                Text(
                  isVitalicio 
                    ? 'Você tem acesso completo a todas as funcionalidades'
                    : (isExpirado 
                        ? 'Seu período de experiência expirou'
                        : 'Aproveite o período de experiência'),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Card com informações
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (isVitalicio) ...[
                          const Icon(Icons.all_inclusive, size: 48, color: Colors.green),
                          const SizedBox(height: 16),
                          const Text('Acesso Vitalício Ativo', 
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Sem limitações de tempo'),
                          const SizedBox(height: 16),
                          Text('Versão: ${AppConfig.versionName}'),
                          Text('Instalado em: ${_trialInfo['dataInstalacao'] ?? 'N/A'}'),
                        ] else ...[
                          // Contador de dias
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: corTema.withValues(alpha: 0.1),
                              border: Border.all(color: corTema, width: 3),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    diasRestantes.toString(),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: corTema,
                                    ),
                                  ),
                                  Text(
                                    diasRestantes == 1 ? 'dia' : 'dias',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: corTema,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Text(
                            isExpirado ? 'Período Expirado' : 'Restantes',
                            style: TextStyle(
                              fontSize: 18,
                              color: corTema,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Informações detalhadas
                          _buildInfoItem('Instalado em', _trialInfo['dataInstalacao'] ?? 'N/A'),
                          _buildInfoItem('Expira em', _trialInfo['dataExpiracao'] ?? 'N/A'),
                          _buildInfoItem('Status', isExpirado ? 'Expirado' : 'Ativo'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Mensagem de aviso
                if (_trialInfo['mensagemAviso'] != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: corTema.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: corTema.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isVitalicio ? Icons.check_circle : (isExpirado ? Icons.error : Icons.info),
                          color: corTema,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _trialInfo['mensagemAviso'],
                            style: TextStyle(
                              color: corTema,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                
                // Botões de ação
                if (!isVitalicio) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _renovarTrial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corTema,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isExpirado ? 'Renovar Agora' : 'Renovar Trial',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Botão voltar
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: corTema),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isVitalicio ? 'Voltar' : (isExpirado ? 'Voltar' : 'Continuar Usando'),
                      style: TextStyle(
                        fontSize: 16,
                        color: corTema,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Informações adicionais
                if (AppConfig.shouldShowTrialFeatures) ...[
                  Text(
                    'Versão: ${AppConfig.versionName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    AppConfig.versionDescription,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Aproveite todas as funcionalidades sem limitações!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 