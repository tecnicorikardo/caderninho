import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/deposito.dart';
import '../models/casa_aposta.dart';
import '../core/app_colors.dart';
import 'dart:math';

class TelaDepositos extends StatefulWidget {
  const TelaDepositos({super.key});

  @override
  State<TelaDepositos> createState() => _TelaDepositosState();
}

class _TelaDepositosState extends State<TelaDepositos> {
  final DatabaseService _db = DatabaseService.instance;
  List<Deposito> _depositos = [];
  List<CasaAposta> _casas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final depositos = await _db.getDepositos();
      final casas = await _db.getCasasAposta();

      setState(() {
        _depositos = depositos;
        _casas = casas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Depósitos'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _depositos.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _depositos.length,
                  itemBuilder: (context, index) {
                    final deposito = _depositos[index];
                    return _buildDepositoCard(deposito);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarDeposito,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_downward_outlined,
            size: 64,
            color: context.adaptiveTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum depósito registrado',
            style: TextStyle(
              fontSize: 18,
              color: context.adaptiveTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para adicionar um depósito',
            style: TextStyle(
              fontSize: 14,
              color: context.adaptiveTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositoCard(Deposito deposito) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.adaptiveCardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryWithOpacity,
          child: Icon(
            Icons.arrow_downward,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          deposito.casaAposta.nome,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: context.adaptiveTextPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'R\$ ${deposito.valor.toStringAsFixed(2)}',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Método: ${deposito.metodoPagamentoText}',
              style: TextStyle(
                color: context.adaptiveTextSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Data: ${_formatarData(deposito.data)}',
              style: TextStyle(
                color: context.adaptiveTextSecondary,
                fontSize: 12,
              ),
            ),
            if (deposito.observacoes != null) ...[
              const SizedBox(height: 4),
              Text(
                'Obs: ${deposito.observacoes}',
                style: TextStyle(
                  color: context.adaptiveTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  deposito.confirmado ? Icons.check_circle : Icons.pending,
                  color: deposito.confirmado ? AppColors.success : AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  deposito.confirmado ? 'Confirmado' : 'Pendente',
                  style: TextStyle(
                    color: deposito.confirmado ? AppColors.success : AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, deposito),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: deposito.confirmado ? 'unconfirm' : 'confirm',
              child: Row(
                children: [
                  Icon(
                    deposito.confirmado ? Icons.pending : Icons.check_circle,
                    color: deposito.confirmado ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(deposito.confirmado ? 'Desconfirmar' : 'Confirmar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _gerarIdUnico() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999);
    return 'dep_${timestamp}_$randomNum';
  }

  void _handleMenuAction(String action, Deposito deposito) {
    switch (action) {
      case 'edit':
        _editarDeposito(deposito);
        break;
      case 'confirm':
      case 'unconfirm':
        _alterarConfirmacao(deposito);
        break;
      case 'delete':
        _excluirDeposito(deposito);
        break;
    }
  }

  void _adicionarDeposito() {
    if (_casas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primeiro cadastre uma casa de aposta!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    _mostrarDialogoDeposito();
  }

  void _editarDeposito(Deposito deposito) {
    _mostrarDialogoDeposito(deposito: deposito);
  }

  void _mostrarDialogoDeposito({Deposito? deposito}) {
    CasaAposta? casaSelecionada = deposito?.casaAposta ?? (_casas.isNotEmpty ? _casas.first : null);
    final valorController = TextEditingController(text: deposito?.valor.toString() ?? '');
    final observacoesController = TextEditingController(text: deposito?.observacoes ?? '');
    MetodoPagamento metodoSelecionado = deposito?.metodoPagamento ?? MetodoPagamento.pix;
    DateTime dataSelecionada = deposito?.data ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            deposito == null ? 'Novo Depósito' : 'Editar Depósito',
            style: TextStyle(color: context.adaptiveTextPrimary),
          ),
          backgroundColor: context.adaptiveCardColor,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seletor de casa
                DropdownButtonFormField<CasaAposta>(
                  value: casaSelecionada,
                  decoration: InputDecoration(
                    labelText: 'Casa de Aposta',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: context.adaptiveTextSecondary),
                  ),
                  items: _casas.map((casa) {
                    return DropdownMenuItem<CasaAposta>(
                      value: casa,
                      child: Text(
                        casa.nome,
                        style: TextStyle(color: context.adaptiveTextPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (CasaAposta? casa) {
                    setState(() {
                      casaSelecionada = casa;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Valor
                TextField(
                  controller: valorController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor (R\$)',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: context.adaptiveTextSecondary),
                  ),
                  style: TextStyle(color: context.adaptiveTextPrimary),
                ),
                const SizedBox(height: 16),
                
                // Método de pagamento
                DropdownButtonFormField<MetodoPagamento>(
                  value: metodoSelecionado,
                  decoration: InputDecoration(
                    labelText: 'Método de Pagamento',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: context.adaptiveTextSecondary),
                  ),
                  items: MetodoPagamento.values.map((metodo) {
                    return DropdownMenuItem<MetodoPagamento>(
                      value: metodo,
                      child: Text(
                        _getMetodoPagamentoText(metodo),
                        style: TextStyle(color: context.adaptiveTextPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (MetodoPagamento? metodo) {
                    if (metodo != null) {
                      setState(() {
                        metodoSelecionado = metodo;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Data
                ListTile(
                  title: Text(
                    'Data',
                    style: TextStyle(color: context.adaptiveTextPrimary),
                  ),
                  subtitle: Text(
                    _formatarData(dataSelecionada),
                    style: TextStyle(color: context.adaptiveTextSecondary),
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: context.adaptiveTextSecondary,
                  ),
                  onTap: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: dataSelecionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (data != null) {
                      setState(() {
                        dataSelecionada = data;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Observações
                TextField(
                  controller: observacoesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Observações (opcional)',
                    border: const OutlineInputBorder(),
                    labelStyle: TextStyle(color: context.adaptiveTextSecondary),
                  ),
                  style: TextStyle(color: context.adaptiveTextPrimary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                valorController.dispose();
                observacoesController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (casaSelecionada == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecione uma casa de aposta!')),
                  );
                  return;
                }

                final valor = double.tryParse(valorController.text.replaceAll(',', '.'));
                if (valor == null || valor <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Digite um valor válido!')),
                  );
                  return;
                }

                if (valor > 1000000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Valor muito alto! Digite um valor menor.')),
                  );
                  return;
                }

                try {
                  final novoDeposito = Deposito(
                    id: deposito?.id ?? _gerarIdUnico(),
                    casaAposta: casaSelecionada!,
                    valor: valor,
                    metodoPagamento: metodoSelecionado,
                    data: dataSelecionada,
                    observacoes: observacoesController.text.trim().isEmpty 
                        ? null 
                        : observacoesController.text.trim(),
                    confirmado: deposito?.confirmado ?? true,
                  );

                  if (deposito == null) {
                    await _db.inserirDeposito(novoDeposito);
                  } else {
                    await _db.atualizarDeposito(novoDeposito);
                  }

                  valorController.dispose();
                  observacoesController.dispose();
                  Navigator.pop(context);
                  _carregarDados();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(deposito == null ? 'Depósito adicionado!' : 'Depósito atualizado!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  valorController.dispose();
                  observacoesController.dispose();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(deposito == null ? 'Adicionar' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMetodoPagamentoText(MetodoPagamento metodo) {
    switch (metodo) {
      case MetodoPagamento.pix:
        return 'PIX';
      case MetodoPagamento.cartao_credito:
        return 'Cartão de Crédito';
      case MetodoPagamento.cartao_debito:
        return 'Cartão de Débito';
      case MetodoPagamento.transferencia:
        return 'Transferência';
      case MetodoPagamento.dinheiro:
        return 'Dinheiro';
      default:
        return 'Desconhecido';
    }
  }

  void _alterarConfirmacao(Deposito deposito) async {
    try {
      final novoDeposito = deposito.copyWith(confirmado: !deposito.confirmado);
      await _db.atualizarDeposito(novoDeposito);
      _carregarDados();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deposito.confirmado ? 'Depósito desconfirmado!' : 'Depósito confirmado!'),
          backgroundColor: AppColors.warning,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  void _excluirDeposito(Deposito deposito) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o depósito de R\$ ${deposito.valor.toStringAsFixed(2)}?'),
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
        await _db.deletarDeposito(deposito.id);
        _carregarDados();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Depósito excluído!'),
            backgroundColor: AppColors.error,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
} 