import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_formatters.dart';
import '../controllers/personal_finance_controller.dart';
import '../models/personal_category.dart';
import '../models/personal_transaction.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.transaction});

  final PersonalTransaction? transaction;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataController = TextEditingController();
  final _observacaoController = TextEditingController();

  bool _saving = false;
  TipoTransacao _tipo = TipoTransacao.despesa;
  StatusTransacao _status = StatusTransacao.pago; // Padrão: pago
  String? _categoriaId;
  String? _contaId;
  DateTime _dataPrevista = DateTime.now();
  bool _recorrente = false;
  FrequenciaRecorrencia? _frequencia;
  bool _parcelado = false;
  int _numeroParcelas = 2;
  bool _notificar = false;
  int _diasAntesNotificacao = 1;

  @override
  void initState() {
    super.initState();
    _dataController.text = AppFormatters.date(_dataPrevista);

    if (widget.transaction != null) {
      final t = widget.transaction!;
      _nomeController.text = t.nome;
      _valorController.text = t.valor.toStringAsFixed(2);
      _tipo = t.tipo;
      _status = t.status;
      _categoriaId = t.categoriaId;
      _contaId = t.contaId;
      _dataPrevista = t.dataPrevista;
      _dataController.text = AppFormatters.date(t.dataPrevista);
      _recorrente = t.recorrente;
      _frequencia = t.frequencia;
      _parcelado = t.parcelado;
      _numeroParcelas = t.numeroParcelas ?? 2;
      _notificar = t.notificar;
      _diasAntesNotificacao = t.diasAntesNotificacao ?? 1;
      _observacaoController.text = t.observacao ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    _dataController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataPrevista,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _dataPrevista = picked;
        _dataController.text = AppFormatters.date(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria')),
      );
      return;
    }

    if (_contaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma conta')),
      );
      return;
    }

    if (_recorrente && _frequencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a frequência da recorrência')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final controller = context.read<PersonalFinanceController>();
      final valor = double.parse(_valorController.text.replaceAll(',', '.'));

      if (widget.transaction == null) {
        await controller.createTransaction(
          tipo: _tipo,
          nome: _nomeController.text.trim(),
          categoriaId: _categoriaId!,
          contaId: _contaId!,
          valor: valor,
          dataPrevista: _dataPrevista,
          status: _status,
          recorrente: _recorrente,
          frequencia: _frequencia,
          parcelado: _parcelado,
          numeroParcelas: _parcelado ? _numeroParcelas : null,
          notificar: _notificar,
          diasAntesNotificacao: _notificar ? _diasAntesNotificacao : null,
          observacao: _observacaoController.text.trim().isEmpty
              ? null
              : _observacaoController.text.trim(),
        );
      } else {
        await controller.updateTransaction(
          transactionId: widget.transaction!.id,
          nome: _nomeController.text.trim(),
          categoriaId: _categoriaId!,
          valor: valor,
          dataPrevista: _dataPrevista,
          status: _status,
          notificar: _notificar,
          diasAntesNotificacao: _notificar ? _diasAntesNotificacao : null,
          observacao: _observacaoController.text.trim().isEmpty
              ? null
              : _observacaoController.text.trim(),
        );
      }

      if (mounted) {
        final msg = widget.transaction == null
            ? 'Transação criada com sucesso'
            : 'Transação atualizada com sucesso';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _showQuickAccountDialog(PersonalFinanceController controller) async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0.00');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova Conta'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da conta',
                  hintText: 'Ex: Carteira, Banco',
                ),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: balanceController,
                decoration: const InputDecoration(
                  labelText: 'Saldo inicial',
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o saldo';
                  }
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      final nome = nameController.text.trim();
      final saldoInicial = double.parse(balanceController.text.replaceAll(',', '.'));

      await controller.createAccount(nome: nome, saldoInicial: saldoInicial);

      // Selecionar automaticamente a conta criada
      if (controller.accounts.isNotEmpty) {
        setState(() {
          _contaId = controller.accounts.last.id;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta criada com sucesso')),
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

  Future<void> _showQuickCategoryDialog(PersonalFinanceController controller) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Nova Categoria (${_tipo == TipoTransacao.receita ? "Receita" : "Despesa"})'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da categoria',
              hintText: 'Ex: Alimentação, Salário',
            ),
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o nome';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      final nome = nameController.text.trim();

      await controller.createCategory(
        nome: nome,
        tipo: _tipo,
        iconeCodePoint: Icons.attach_money.codePoint,
        corValue: _tipo == TipoTransacao.receita ? 0xFF10B981 : 0xFFEF4444,
      );

      // Selecionar automaticamente a categoria criada
      final categories = controller.getCategoriesByType(_tipo);
      if (categories.isNotEmpty) {
        setState(() {
          _categoriaId = categories.last.id;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoria criada com sucesso')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction == null
              ? 'Nova Transação'
              : 'Editar Transação',
        ),
      ),
      body: Consumer<PersonalFinanceController>(
        builder: (context, controller, _) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tipo
                if (widget.transaction == null)
                  SegmentedButton<TipoTransacao>(
                    segments: const [
                      ButtonSegment(
                        value: TipoTransacao.receita,
                        label: Text('Receita'),
                        icon: Icon(Icons.arrow_upward, color: Colors.green),
                      ),
                      ButtonSegment(
                        value: TipoTransacao.despesa,
                        label: Text('Despesa'),
                        icon: Icon(Icons.arrow_downward, color: Colors.red),
                      ),
                    ],
                    selected: {_tipo},
                    onSelectionChanged: (value) {
                      setState(() {
                        _tipo = value.first;
                        _categoriaId = null; // Reset categoria
                      });
                    },
                  ),
                const SizedBox(height: 16),

                // Nome
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex: Almoço, Salário, Conta de luz',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe a descrição';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Valor
                TextFormField(
                  controller: _valorController,
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o valor';
                    }
                    final parsed = double.tryParse(value.replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) {
                      return 'Valor inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Categoria
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _categoriaId,
                        decoration: const InputDecoration(labelText: 'Categoria'),
                        items: controller
                            .getCategoriesByType(_tipo)
                            .map((cat) => DropdownMenuItem(
                                  value: cat.id,
                                  child: Row(
                                    children: [
                                      Icon(cat.icone, color: cat.cor, size: 20),
                                      const SizedBox(width: 8),
                                      Text(cat.nome),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _categoriaId = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Nova categoria',
                      onPressed: () => _showQuickCategoryDialog(controller),
                    ),
                  ],
                ),
                if (controller.getCategoriesByType(_tipo).isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      'Nenhuma categoria de ${_tipo == TipoTransacao.receita ? "receita" : "despesa"}. Toque no + para criar.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Conta
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _contaId,
                        decoration: const InputDecoration(labelText: 'Conta'),
                        items: controller.accounts
                            .map((acc) => DropdownMenuItem(
                                  value: acc.id,
                                  child: Text(acc.nome),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _contaId = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Nova conta',
                      onPressed: () => _showQuickAccountDialog(controller),
                    ),
                  ],
                ),
                if (controller.accounts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      'Nenhuma conta cadastrada. Toque no + para criar.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Data
                TextFormField(
                  controller: _dataController,
                  decoration: const InputDecoration(
                    labelText: 'Data prevista',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                ),
                const SizedBox(height: 16),

                // Status
                DropdownButtonFormField<StatusTransacao>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.check_circle_outline),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: StatusTransacao.pago,
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Pago'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: StatusTransacao.pendente,
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Pendente'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Opções avançadas (apenas para nova transação)
                if (widget.transaction == null) ...[
                  const Text(
                    'Opções Avançadas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Recorrente
                  SwitchListTile(
                    title: const Text('Transação recorrente'),
                    subtitle: const Text('Repetir automaticamente'),
                    value: _recorrente,
                    onChanged: (value) {
                      setState(() {
                        _recorrente = value;
                        if (!value) _frequencia = null;
                        if (value) _parcelado = false;
                      });
                    },
                  ),

                  if (_recorrente)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<FrequenciaRecorrencia>(
                        value: _frequencia,
                        decoration: const InputDecoration(
                          labelText: 'Frequência',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: FrequenciaRecorrencia.semanal,
                            child: Text('Semanal'),
                          ),
                          DropdownMenuItem(
                            value: FrequenciaRecorrencia.mensal,
                            child: Text('Mensal'),
                          ),
                          DropdownMenuItem(
                            value: FrequenciaRecorrencia.anual,
                            child: Text('Anual'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _frequencia = value;
                          });
                        },
                      ),
                    ),

                  // Parcelado
                  SwitchListTile(
                    title: const Text('Parcelar'),
                    subtitle: const Text('Dividir em várias parcelas'),
                    value: _parcelado,
                    onChanged: (value) {
                      setState(() {
                        _parcelado = value;
                        if (value) _recorrente = false;
                      });
                    },
                  ),

                  if (_parcelado)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text('Número de parcelas:'),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _numeroParcelas > 2
                                ? () {
                                    setState(() {
                                      _numeroParcelas--;
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            '$_numeroParcelas',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _numeroParcelas < 60
                                ? () {
                                    setState(() {
                                      _numeroParcelas++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],

                // Notificação
                SwitchListTile(
                  title: const Text('Notificar'),
                  subtitle: const Text('Receber lembrete antes do vencimento'),
                  value: _notificar,
                  onChanged: (value) {
                    setState(() {
                      _notificar = value;
                    });
                  },
                ),

                if (_notificar)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<int>(
                      value: _diasAntesNotificacao,
                      decoration: const InputDecoration(
                        labelText: 'Notificar com antecedência',
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('No dia')),
                        DropdownMenuItem(value: 1, child: Text('1 dia antes')),
                        DropdownMenuItem(value: 3, child: Text('3 dias antes')),
                        DropdownMenuItem(value: 7, child: Text('7 dias antes')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _diasAntesNotificacao = value!;
                        });
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                // Observação
                TextFormField(
                  controller: _observacaoController,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Botão salvar
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Salvando...' : 'Salvar Transação'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
