import 'package:flutter/material.dart';
import '../services/trial_service.dart';
import '../core/app_colors.dart';
import 'tela_trial.dart';

class AvisoTrialWidget extends StatefulWidget {
  const AvisoTrialWidget({super.key});

  @override
  State<AvisoTrialWidget> createState() => _AvisoTrialWidgetState();
}

class _AvisoTrialWidgetState extends State<AvisoTrialWidget> {
  final TrialService _trialService = TrialService.instance;
  bool _mostrarAviso = false;
  bool _avisoDispensado = false;

  @override
  void initState() {
    super.initState();
    _verificarAviso();
  }

  Future<void> _verificarAviso() async {
    if (_trialService.deveExibirAviso && !await _trialService.jaExibiuAvisoHoje()) {
      setState(() {
        _mostrarAviso = true;
      });
    }
  }

  void _dispensarAviso() {
    setState(() {
      _avisoDispensado = true;
    });
    _trialService.marcarAvisoMostrado();
  }

  void _abrirTelaTrial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TelaTrialExperiencia(),
      ),
    );
  }

  Color _getCorAviso() {
    final tipoAviso = _trialService.tipoAviso;
    
    switch (tipoAviso) {
      case 'expirado':
        return Colors.red;
      case 'critico':
        return Colors.red.shade700;
      case 'urgente':
        return Colors.orange;
      case 'aviso':
        return Colors.amber;
      default:
        return AppColors.primary;
    }
  }

  IconData _getIconeAviso() {
    final tipoAviso = _trialService.tipoAviso;
    
    switch (tipoAviso) {
      case 'expirado':
        return Icons.error;
      case 'critico':
        return Icons.warning;
      case 'urgente':
        return Icons.schedule;
      case 'aviso':
        return Icons.info;
      default:
        return Icons.verified;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Não mostra se foi dispensado ou se não deve exibir
    if (_avisoDispensado || !_mostrarAviso) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.primary.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: _getCorAviso().withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCorAviso().withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconeAviso(),
                    color: _getCorAviso(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Conteúdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Período de Experiência',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getCorAviso(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _trialService.mensagemAviso,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Botões
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _abrirTelaTrial,
                      icon: const Icon(Icons.arrow_forward_ios),
                      color: _getCorAviso(),
                      tooltip: 'Ver detalhes',
                    ),
                    IconButton(
                      onPressed: _dispensarAviso,
                      icon: const Icon(Icons.close),
                      color: AppColors.textHint,
                      tooltip: 'Dispensar hoje',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget compacto para mostrar informações do trial
class InfoTrialWidget extends StatelessWidget {
  const InfoTrialWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final trialService = TrialService.instance;
    
    if (!trialService.deveExibirAviso) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TelaTrialExperiencia(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: trialService.isTrialExpirado ? Colors.red : Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              trialService.isTrialExpirado ? Icons.error : Icons.schedule,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              trialService.isTrialExpirado 
                  ? 'Trial Expirado'
                  : '${trialService.diasRestantes} dias',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 