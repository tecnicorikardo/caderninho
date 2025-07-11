import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';
import '../services/backup_service.dart';
import '../services/trial_service.dart';
import '../services/config_service.dart';
import '../services/notification_service.dart';
import '../config/app_config.dart';

class TelaConfiguracoes extends StatefulWidget {
  const TelaConfiguracoes({super.key});

  @override
  State<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends State<TelaConfiguracoes> {
  final DatabaseService _db = DatabaseService.instance;
  final BackupService _backupService = BackupService.instance;
  final TrialService _trialService = TrialService.instance;
  final ConfigService _configService = ConfigService.instance;
  
  // Variáveis para controlar o estado
  bool _isLoadingLimparDados = false;
  bool _isLoadingBackup = false;
  bool _isLoadingRestore = false;
  
  int _totalClientes = 0;
  int _totalProdutos = 0;
  int _totalVendas = 0;
  int _totalFiados = 0;
  
  Map<String, dynamic> _trialInfo = {};
  String _temaAtual = 'system';

  int _intervaloNotificacaoHoras = 3;
  final List<int> _opcoesIntervalo = [1, 3, 6, 12, 24];

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _carregarTema();
    _carregarIntervaloNotificacao();
  }

  Future<void> _carregarDados() async {
      final clientes = await _db.getClientes();
      final produtos = await _db.getProdutos();
      final vendas = await _db.getVendas();
      final fiados = await _db.getFiados();
      
      setState(() {
      _totalClientes = clientes.length;
      _totalProdutos = produtos.length;
      _totalVendas = vendas.length;
      _totalFiados = fiados.length;
      _trialInfo = _trialService.infoTrial;
    });
  }

  Future<void> _carregarTema() async {
    await _configService.carregarConfiguracoes();
    setState(() {
      _temaAtual = _configService.tema;
    });
  }

  Future<void> _alterarTema(String novoTema) async {
    await _configService.salvarTema(novoTema);
    setState(() {
      _temaAtual = novoTema;
    });
  }

  Future<void> _fazerBackup() async {
    try {
      final backupService = BackupService.instance;
      final filePath = await backupService.fazerBackup();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup criado com sucesso!\nArquivo: ${filePath.split('/').last}'),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Verificar se foi salvo no diretório público ou privado
        final isPublic = filePath.contains('/Download/') || filePath.contains('/storage/emulated/0/Download/');
        
        // Mostrar diálogo com informações detalhadas
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Backup Criado!'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Arquivo salvo em:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(filePath, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  const SizedBox(height: 16),
                  
                  if (isPublic) ...[
                    const Text('📁 Para encontrar o arquivo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('1. Abra o Explorador de Arquivos'),
                    const Text('2. Vá para a pasta Downloads'),
                    const Text('3. Procure pela pasta "CaderninhoBackups"'),
                    const Text('4. O arquivo estará lá dentro'),
                  ] else ...[
                    const Text('📁 Localização do arquivo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('O arquivo foi salvo no diretório interno do app.'),
                    const Text('Para acessá-lo:'),
                    const Text('1. Use a função "Restaurar backup" neste app'),
                    const Text('2. Ou use um aplicativo de gerenciamento de arquivos com acesso root'),
                    const SizedBox(height: 8),
                    const Text('💡 Dica: Para backups mais acessíveis, permita o acesso ao armazenamento quando solicitado.'),
                  ],
                  
                  const SizedBox(height: 16),
                  const Text('💾 O arquivo contém todos os seus dados (clientes, produtos, vendas, fiados) em formato JSON e pode ser usado para restaurar em outro dispositivo.'),
                  const SizedBox(height: 8),
                  const Text('🔒 Mantenha seus backups em local seguro!', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restaurarBackup() async {
    try {
      final backupService = BackupService.instance;
      final backups = await backupService.listarBackups();
      
      // Mostrar opções de restauração
      if (context.mounted) {
        final opcao = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restaurar Backup'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (backups.isNotEmpty) ...[
                  const Text('Escolha uma opção:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.list, color: Colors.blue),
                    title: const Text('Backups do App'),
                    subtitle: Text('${backups.length} backup(s) encontrado(s)'),
                    onTap: () => Navigator.pop(context, 'app'),
                  ),
                  const Divider(),
                ],
                ListTile(
                  leading: const Icon(Icons.folder_open, color: Colors.green),
                  title: const Text('Selecionar Arquivo'),
                  subtitle: const Text('Escolher arquivo de backup manualmente'),
                  onTap: () => Navigator.pop(context, 'manual'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );

        if (opcao == null) return;

        BackupInfo? backupEscolhido;

        if (opcao == 'app') {
          if (backups.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nenhum backup encontrado no app.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          // Mostrar lista de backups do app
          backupEscolhido = await showDialog<BackupInfo>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Escolher Backup'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: backups.length,
                  itemBuilder: (context, index) {
                    final backup = backups[index];
                    return ListTile(
                      title: Text(backup.dataFormatada),
                      subtitle: Text(
                        '${backup.clientes} clientes, ${backup.produtos} produtos, '
                        '${backup.vendas} vendas, ${backup.fiados} fiados\n'
                        'Tamanho: ${backup.tamanhoFormatado}',
                      ),
                      onTap: () => Navigator.pop(context, backup),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          );
        } else if (opcao == 'manual') {
          // Selecionar arquivo manualmente
          try {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['json'],
              dialogTitle: 'Selecionar arquivo de backup',
            );

            if (result != null && result.files.isNotEmpty) {
              final file = result.files.first;
              final filePath = file.path!;
              
              // Criar BackupInfo temporário para o arquivo selecionado
              backupEscolhido = BackupInfo(
                path: filePath,
                timestamp: DateTime.now(),
                tamanho: file.size,
                clientes: 0, // Será carregado do arquivo
                produtos: 0,
                vendas: 0,
                fiados: 0,
                compromissos: 0,
                casasAposta: 0,
                depositos: 0,
                saques: 0,
                contas: 0,
                usuarios: 0,
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao selecionar arquivo: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        if (backupEscolhido != null) {
          // Confirmação final
          final confirmar = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirmar Restauração'),
              content: Text(
                'Tem certeza que deseja restaurar o backup?\n\n'
                'ATENÇÃO: Todos os dados atuais serão substituídos pelos dados do backup!\n\n'
                'Arquivo: ${backupEscolhido?.path.split('/').last ?? 'N/A'}\n'
                'Tamanho: ${backupEscolhido?.tamanhoFormatado ?? 'N/A'}\n'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Restaurar'),
                ),
              ],
            ),
          );

          if (confirmar == true) {
            setState(() {
              _isLoadingRestore = true;
            });

            try {
              await backupService.restaurarBackup(backupEscolhido.path);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Backup restaurado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Recarregar dados
                await _carregarDados();
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao restaurar backup: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } finally {
              setState(() {
                _isLoadingRestore = false;
              });
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao restaurar backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _limparDados() async {
    // Confirmação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Limpeza'),
        content: const Text(
          'Tem certeza que deseja limpar TODOS os dados?\n\n'
          'Esta ação não pode ser desfeita!\n\n'
          'Recomendamos fazer um backup antes!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Limpar Tudo'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        _isLoadingLimparDados = true;
      });

      try {
        await _db.limparBanco();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todos os dados foram limpos com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Recarregar dados
          await _carregarDados();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao limpar dados: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoadingLimparDados = false;
        });
      }
    }
  }

  Future<void> _abrirWhatsApp() async {
    final url = Uri.parse('https://wa.me/5511999999999');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Não foi possível abrir o WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _abrirEmail() async {
    final url = Uri.parse('mailto:suporte@exemplo.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Não foi possível abrir o cliente de email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Função para abrir tela de trial
  Future<void> _abrirTelaTrial() async {
    Navigator.pushNamed(context, '/trial');
  }

  /// Função para simular trial vencendo (5 dias)
  Future<void> _simularTrialVencimento() async {
    // Só permite na versão trial
    if (!AppConfig.shouldShowTrialFeatures) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidade não disponível na versão vitalícia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      // Simula instalação há 360 dias (restam 5 dias)
      final dataSimulada = DateTime.now().subtract(const Duration(days: 360));
      
      // Salva data simulada
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('data_instalacao', dataSimulada.millisecondsSinceEpoch);
      
      // Reinicializa o trial service
      await _trialService.inicializar();
      
      // Atualiza os dados
      await _carregarDados();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trial simulado! Restam 5 dias para expirar.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao simular trial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Função para resetar trial
  Future<void> _resetarTrial() async {
    try {
      await _trialService.resetarTrial();
      await _carregarDados();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppConfig.resetMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao resetar trial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _carregarIntervaloNotificacao() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _intervaloNotificacaoHoras = prefs.getInt('intervalo_notificacao_agenda') ?? 3;
    });
  }

  Future<void> _salvarIntervaloNotificacao(int valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('intervalo_notificacao_agenda', valor);
    setState(() {
      _intervaloNotificacaoHoras = valor;
    });
    // Chamar o serviço de notificação para reagendar
    await NotificationService().agendarNotificacaoRecorrenteAgenda(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Informações do app
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informações do App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Versão: ${AppConfig.versionName}'),
                  Text('Tipo: ${AppConfig.versionDescription}'),
                  const Text('Desenvolvido para pequenos comerciantes'),
                  const SizedBox(height: 16),
                  const Text('🔐 Segurança e Privacidade', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'O aplicativo armazena dados localmente usando SQLite com criptografia básica. Recomendamos fazer backups regulares.\n'
                    '\n'
                    'Nenhum dado é enviado para servidores externos. Todos os dados ficam no seu dispositivo.',
                  ),
                  const SizedBox(height: 16),
                  const Text('📝 Principais Funcionalidades', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    '• Gestão de clientes e produtos\n'
                    '• Controle de vendas e fiados\n'
                    '• Relatórios detalhados\n'
                    '• Backup completo\n'
                    '• Notificações de lembrete\n'
                    '• Integração com WhatsApp',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Estatísticas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estatísticas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
                  Text('Clientes cadastrados: $_totalClientes'),
                  Text('Produtos cadastrados: $_totalProdutos'),
                  Text('Vendas realizadas: $_totalVendas'),
                  Text('Contas em aberto: $_totalFiados'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Configurações de Aparência
          const Text('Aparência', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Modo de Tema', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: const Text('Automático'),
                    subtitle: const Text('Segue a configuração do sistema'),
                    value: 'system',
                    groupValue: _temaAtual,
                    onChanged: (value) => _alterarTema(value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Claro'),
                    subtitle: const Text('Sempre usar tema claro'),
                    value: 'light',
                    groupValue: _temaAtual,
                    onChanged: (value) => _alterarTema(value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Escuro'),
                    subtitle: const Text('Sempre usar tema escuro'),
                    value: 'dark',
                    groupValue: _temaAtual,
                    onChanged: (value) => _alterarTema(value!),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notificações
          const Text('Notificações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Intervalo de Notificações da Agenda', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    value: _intervaloNotificacaoHoras,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('A cada 1 hora')),
                      DropdownMenuItem(value: 3, child: Text('A cada 3 horas')),
                      DropdownMenuItem(value: 6, child: Text('A cada 6 horas')),
                      DropdownMenuItem(value: 12, child: Text('A cada 12 horas')),
                      DropdownMenuItem(value: 24, child: Text('Uma vez por dia')),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        _salvarIntervaloNotificacao(valor);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.notifications),
                    label: const Text('Testar Notificações'),
                    onPressed: () async {
                      try {
                        await NotificationService().mostrarNotificacaoTeste();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notificação de teste enviada! Verifique sua barra de notificações.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao enviar notificação: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reagendar Todas as Notificações'),
                    onPressed: () async {
                      try {
                        await NotificationService().reagendarTodasNotificacoes();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Todas as notificações foram reagendadas com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao reagendar notificações: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'As notificações são usadas para:\n'
                    '• Lembrar de compromissos na agenda\n'
                    '• Avisar sobre contas a vencer (3 dias, 1 dia e no vencimento)\n'
                    '• Avisar sobre fiados vencidos\n'
                    '• Alertas importantes do sistema\n\n'
                    'Use "Reagendar" se as notificações pararam de funcionar.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Backup e dados
          const Text('Backup e Dados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.backup),
            label: const Text('Fazer backup dos dados'),
            onPressed: () => _fazerBackup(),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('Restaurar backup'),
            onPressed: () => _restaurarBackup(),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text('Limpar todos os dados'),
            onPressed: _isLoadingLimparDados ? null : _limparDados,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Seção de trial/licença (apenas se for trial)
          if (AppConfig.shouldShowTrialFeatures) ...[
            const Text('Trial e Licença', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildInfoTrial(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.timer),
              label: const Text('Ver tela de Trial'),
              onPressed: _abrirTelaTrial,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.warning),
              label: const Text('Simular trial vencendo (5 dias)'),
              onPressed: _simularTrialVencimento,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (AppConfig.shouldShowTrialReset) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text('Resetar trial (${AppConfig.trialDurationDays} dias)'),
                onPressed: _resetarTrial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ] else ...[
            // Seção vitalícia
            const Text('Licença Vitalícia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 8),
                    const Text('Acesso Vitalício Ativo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Você tem acesso completo a todas as funcionalidades do aplicativo sem limitações de tempo.'),
                    const SizedBox(height: 8),
                    Text('Versão: ${AppConfig.versionName}'),
                    Text('Instalado em: ${_trialInfo['dataInstalacao'] ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Informações da versão
          const Text('Versão do App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Versão: 1.0.0 (${AppConfig.versionName})'),
          Text('Build: ${DateTime.now().millisecondsSinceEpoch}'),
          const Text('Desenvolvido em Flutter'),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoTrial() {
    return Card(
      color: _trialInfo['isExpirado'] == true ? Colors.red[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações do Trial',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Data de instalação: ${_trialInfo['dataInstalacao'] ?? 'N/A'}'),
            Text('Data de expiração: ${_trialInfo['dataExpiracao'] ?? 'N/A'}'),
            Text('Dias restantes: ${_trialInfo['diasRestantes'] ?? 0}'),
            Text('Status: ${_trialInfo['isExpirado'] == true ? 'Expirado' : 'Ativo'}'),
            const SizedBox(height: 8),
            if (_trialInfo['mensagemAviso'] != null)
              Text(
                _trialInfo['mensagemAviso'],
                style: TextStyle(
                  color: _trialInfo['isExpirado'] == true ? Colors.red : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 