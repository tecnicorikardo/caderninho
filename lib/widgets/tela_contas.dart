import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/conta.dart';
import '../services/contas_service.dart';
import '../core/app_colors.dart';

class TelaContas extends StatefulWidget {
  const TelaContas({super.key});

  @override
  State<TelaContas> createState() => _TelaContasState();
}

class _TelaContasState extends State<TelaContas> {
  final ContasService _contasService = ContasService.instance;
  
  List<Conta> _contas = [];
  bool _carregando = true;
  double _totalPendente = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    
    try {
      final contas = await _contasService.getContas();
      
      double totalPendente = 0.0;
      for (var conta in contas) {
        if (conta.status == StatusConta.pendente) {
          totalPendente += conta.valor;
        }
      }
      
      setState(() {
        _contas = contas;
        _totalPendente = totalPendente;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('💳 Minhas Contas'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textOnPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _executarTestes,
            tooltip: 'Executar testes de debug',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResumo(),
                  const SizedBox(height: 20),
                  _buildContas(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioConta,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildResumo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Resumo do Mês',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Contas Pendentes:'),
                Text(
                  'R\$ ${_totalPendente.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'R\$ ${_totalPendente.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📋 Todas as Contas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_contas.isNotEmpty)
              TextButton(
                onPressed: () => _mostrarFormularioConta(),
                child: const Text('+ Nova'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_contas.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_outlined, size: 50, color: AppColors.grey400),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma conta cadastrada',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _mostrarFormularioConta(),
                      child: const Text('Adicionar Conta'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...(_contas.map((conta) => _buildCardConta(conta))),
      ],
    );
  }

  Widget _buildCardConta(Conta conta) {
    final cor = conta.status == StatusConta.pago 
        ? AppColors.success 
        : conta.isVencida 
            ? AppColors.error 
            : AppColors.warning;

    final icone = conta.status == StatusConta.pago 
        ? Icons.check_circle 
        : conta.isVencida 
            ? Icons.error 
            : Icons.schedule;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icone, color: cor),
        title: Text(
          conta.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Vencimento: ${_formatarData(conta.vencimento)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'R\$ ${conta.valor.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            Text(
              conta.statusFormatado,
              style: TextStyle(fontSize: 12, color: cor),
            ),
          ],
        ),
        onTap: () => _mostrarOpcoesConta(conta),
      ),
    );
  }

  void _mostrarFormularioConta([Conta? conta]) {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: conta?.nome ?? '');
    final valorController = TextEditingController(text: conta?.valor.toString() ?? '');
    final observacoesController = TextEditingController(text: conta?.observacoes ?? '');
    DateTime dataVencimento = conta?.vencimento ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: Text(conta == null ? 'Nova Conta' : 'Editar Conta'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Conta',
                      prefixIcon: Icon(Icons.receipt),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: valorController,
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      hintText: 'Ex: 150,00 ou 150.00',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}'))],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Valor é obrigatório';
                      }
                      final valorLimpo = value.replaceAll(',', '.');
                      final numero = double.tryParse(valorLimpo);
                      if (numero == null || numero <= 0) {
                        return 'Valor deve ser maior que zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final data = await showDatePicker(
                        context: context,
                        initialDate: dataVencimento,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (data != null) {
                        setDialogState(() {
                          dataVencimento = data;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 16),
                          Text('Vencimento: ${_formatarData(dataVencimento)}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: observacoesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  print('🔍 Debug: Iniciando salvamento de conta...');
                  final valorTexto = valorController.text.replaceAll(',', '.');
                  final valorNumerico = double.parse(valorTexto);
                  
                  print('🔍 Debug: Valor convertido: $valorNumerico');
                  print('🔍 Debug: Data vencimento: $dataVencimento');
                  
                  final novaConta = Conta(
                    id: conta?.id,
                    nome: nomeController.text.trim(),
                    valor: valorNumerico,
                    vencimento: dataVencimento,
                    observacoes: observacoesController.text.trim().isEmpty ? null : observacoesController.text.trim(),
                  );

                  print('🔍 Debug: Conta criada: ${novaConta.toMap()}');

                  if (conta == null) {
                    print('🔍 Debug: Inserindo nova conta...');
                    await _contasService.inserirConta(novaConta);
                    print('🔍 Debug: Conta inserida com sucesso!');
                  } else {
                    print('🔍 Debug: Atualizando conta existente...');
                    await _contasService.atualizarConta(novaConta);
                    print('🔍 Debug: Conta atualizada com sucesso!');
                  }
                  
                  Navigator.pop(context);
                  await _carregarDados();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(conta == null ? '✅ Conta adicionada!' : '✅ Conta atualizada!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Erro ao salvar conta: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao salvar conta: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(conta == null ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
        ),
      );
  }

  void _mostrarOpcoesConta(Conta conta) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              conta.nome,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (conta.status == StatusConta.pendente)
              ListTile(
                leading: const Icon(Icons.check, color: AppColors.success),
                title: const Text('Marcar como Paga'),
                onTap: () => _marcarComoPaga(conta),
              ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _mostrarFormularioConta(conta);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Excluir'),
              onTap: () => _excluirConta(conta),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _marcarComoPaga(Conta conta) async {
    Navigator.pop(context);
    try {
      await _contasService.marcarContaComoPaga(conta.id);
      _carregarDados();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Conta marcada como paga!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _excluirConta(Conta conta) async {
    Navigator.pop(context);
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja excluir a conta "${conta.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _contasService.deletarConta(conta.id);
        _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conta excluída!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
  }

  void _executarTestes() async {
    try {
      print('🧪 Iniciando testes de debug...');
      
      // Verificar estrutura do banco
      await _contasService.verificarEstruturaBanco();
      
      // Testar inserção de conta
      await _contasService.testarInsercaoConta();
      
      // Recarregar dados
      await _carregarDados();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧪 Testes executados! Verifique os logs no console.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
    } catch (e) {
      print('❌ Erro nos testes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro nos testes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 