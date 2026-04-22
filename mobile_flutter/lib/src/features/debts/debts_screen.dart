import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';
import '../shared/gradient_card.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  String _errorText(Object error) {
    if (error is FirebaseException) {
      return error.message ?? 'Falha ao salvar no Firebase.';
    }
    if (error is StateError) {
      return error.message;
    }
    return error.toString();
  }

  Future<void> _newDebt(AppStore store) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final dueDateController = TextEditingController(
      text: AppFormatters.date(DateTime.now().add(const Duration(days: 7))),
    );
    final formKey = GlobalKey<FormState>();
    var hasDueDate = true;
    var reminderEnabled = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nova divida'),
          content: SizedBox(
            width: 430,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Titulo'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Informe o nome da divida'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Valor'),
                    validator: (value) {
                      final parsed = double.tryParse(
                        (value ?? '').replaceAll(',', '.'),
                      );
                      if (parsed == null || parsed <= 0) {
                        return 'Informe um valor valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Definir data de pagamento'),
                    value: hasDueDate,
                    onChanged: (value) {
                      setStateDialog(() {
                        hasDueDate = value;
                      });
                    },
                  ),
                  if (hasDueDate) ...[
                    TextFormField(
                      controller: dueDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data de pagamento',
                      ),
                      onTap: () async {
                        final now = DateTime.now();
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: now.add(const Duration(days: 7)),
                          firstDate: now.subtract(const Duration(days: 3650)),
                          lastDate: now.add(const Duration(days: 3650)),
                        );
                        if (selected == null) return;
                        dueDateController.text = AppFormatters.date(selected);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ativar lembrete'),
                    subtitle: Text(
                      'Mostra alerta ate ${store.personalDebtReminderDays} dia(s) antes do vencimento.',
                    ),
                    value: reminderEnabled,
                    onChanged: (value) {
                      setStateDialog(() {
                        reminderEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Observacao (opcional)',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(context).pop(true);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    try {
      DateTime? dueDate;
      if (hasDueDate) {
        final parts = dueDateController.text.split('/');
        dueDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
      await store.addPersonalDebt(
        title: titleController.text.trim(),
        amount: double.parse(amountController.text.replaceAll(',', '.')),
        dueDate: dueDate,
        note: noteController.text.trim(),
        reminderEnabled: reminderEnabled,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Divida registrada.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  Future<void> _payDebt(AppStore store, PersonalDebtRecord debt) async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Pagamento - ${debt.title}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Valor pago',
              helperText:
                  'Saldo atual: ${AppFormatters.currency(debt.openAmount)}',
            ),
            validator: (value) {
              final parsed = double.tryParse(
                (value ?? '').replaceAll(',', '.'),
              );
              if (parsed == null || parsed <= 0) {
                return 'Informe um valor valido';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(context).pop(true);
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final error = await store.payPersonalDebt(
      debtId: debt.id,
      amount: double.parse(amountController.text.replaceAll(',', '.')),
    );
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _settleDebt(AppStore store, PersonalDebtRecord debt) async {
    final error = await store.payPersonalDebt(
      debtId: debt.id,
      amount: debt.openAmount,
    );
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Divida "${debt.title}" quitada.')));
  }

  Future<void> _deleteDebt(AppStore store, PersonalDebtRecord debt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir divida'),
        content: Text('Deseja excluir "${debt.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await store.deletePersonalDebt(debtId: debt.id);
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  String _dueLabel(PersonalDebtRecord debt) {
    if (debt.dueDate == null) return 'Sem data de pagamento';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      debt.dueDate!.year,
      debt.dueDate!.month,
      debt.dueDate!.day,
    );
    final daysUntil = due.difference(today).inDays;
    if (daysUntil < 0) {
      return 'Atrasada ha ${-daysUntil} dia(s) - venc. ${AppFormatters.date(due)}';
    }
    if (daysUntil == 0) return 'Vence hoje';
    return 'Vence em $daysUntil dia(s) - ${AppFormatters.date(due)}';
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dividas'),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Configurar lembrete',
            icon: const Icon(Icons.notifications_active_outlined),
            initialValue: store.personalDebtReminderDays,
            onSelected: (days) async {
              final messenger = ScaffoldMessenger.of(context);
              await store.setPersonalDebtReminderDays(days);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Lembrete ajustado para $days dia(s) antes do vencimento.',
                  ),
                ),
              );
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1, child: Text('Alertar 1 dia antes')),
              PopupMenuItem(value: 3, child: Text('Alertar 3 dias antes')),
              PopupMenuItem(value: 7, child: Text('Alertar 7 dias antes')),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final openDebts =
              store.personalDebts.where((debt) => debt.openAmount > 0).toList()
                ..sort((a, b) {
                  final aDue = a.dueDate;
                  final bDue = b.dueDate;
                  if (aDue == null && bDue == null) {
                    return b.createdAt.compareTo(a.createdAt);
                  }
                  if (aDue == null) return 1;
                  if (bDue == null) return -1;
                  return aDue.compareTo(bDue);
                });
          final alerts = store.upcomingPersonalDebtAlerts();
          final insights = store.personalDebtInsights();

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final overdueCount = openDebts.where((debt) {
            final dueDate = debt.dueDate;
            if (dueDate == null) return false;
            final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
            return due.isBefore(today);
          }).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              GradientCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo de dividas',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Em aberto: ${AppFormatters.currency(store.totalOpenPersonalDebts)}',
                      ),
                      Text('Qtd em aberto: ${openDebts.length}'),
                      Text('Atrasadas: $overdueCount'),
                    ],
                  ),
                ),
              ),
              if (alerts.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lembretes ativos (${alerts.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...alerts.take(5).map((item) {
                        final debt = item.debt;
                        final label = item.daysUntilDue < 0
                            ? 'Atrasada ha ${-item.daysUntilDue} dia(s)'
                            : item.daysUntilDue == 0
                            ? 'Vence hoje'
                            : 'Vence em ${item.daysUntilDue} dia(s)';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '- ${debt.title}: $label (${AppFormatters.currency(debt.openAmount)})',
                            style: const TextStyle(color: Color(0xFF78350F)),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              GradientCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dicas offline (prioridade de pagamento)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      if (insights.isEmpty)
                        const Text('Sem dividas em aberto para priorizar.')
                      else
                        ...insights.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('- ${item.debt.title}: ${item.reason}'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (openDebts.isEmpty)
                const GradientCard(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Nenhuma divida pessoal em aberto.'),
                  ),
                ),
              ...openDebts.map(
                (debt) => GradientCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                debt.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              AppFormatters.currency(debt.openAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dueLabel(debt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (debt.note.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            debt.note,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            TextButton(
                              onPressed: () => _payDebt(store, debt),
                              child: const Text('Pagar parcial'),
                            ),
                            TextButton(
                              onPressed: () => _settleDebt(store, debt),
                              child: const Text('Quitar'),
                            ),
                            TextButton(
                              onPressed: () => _deleteDebt(store, debt),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newDebt(store),
        icon: const Icon(Icons.request_quote_outlined),
        label: const Text('Nova divida'),
      ),
    );
  }
}
