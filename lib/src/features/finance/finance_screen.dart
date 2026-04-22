import 'package:flutter/material.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';
import '../reports/reports_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  FinancialPeriod _period = FinancialPeriod.day;

  String _periodLabel(FinancialPeriod period) {
    switch (period) {
      case FinancialPeriod.day:
        return 'Dia';
      case FinancialPeriod.week:
        return 'Semana';
      case FinancialPeriod.month:
        return 'Mês';
    }
  }

  String _entryTypeLabel(FinancialEntryType type) {
    switch (type) {
      case FinancialEntryType.revenue:
        return 'Receita';
      case FinancialEntryType.expense:
        return 'Despesa';
      case FinancialEntryType.stock:
        return 'Compra de Estoque';
    }
  }

  IconData _entryTypeIcon(FinancialEntryType type) {
    switch (type) {
      case FinancialEntryType.revenue:
        return Icons.trending_up;
      case FinancialEntryType.expense:
        return Icons.trending_down;
      case FinancialEntryType.stock:
        return Icons.inventory_2;
    }
  }

  Color _entryTypeColor(FinancialEntryType type) {
    switch (type) {
      case FinancialEntryType.revenue:
        return Colors.green;
      case FinancialEntryType.expense:
        return Colors.red;
      case FinancialEntryType.stock:
        return Colors.orange;
    }
  }

  Future<void> _addExpense(AppStore store) async {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    bool isStock = false;
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova Despesa'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe a descrição';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Valor'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o valor';
                      }
                      final amount = double.tryParse(value.replaceAll(',', '.'));
                      if (amount == null || amount <= 0) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: isStock,
                    onChanged: (value) {
                      setDialogState(() {
                        isStock = value ?? false;
                      });
                    },
                    title: const Text('É compra de estoque?'),
                    subtitle: const Text('Marque se for compra de mercadoria'),
                    contentPadding: EdgeInsets.zero,
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

    if (shouldSave != true) return;

    store.addExpense(
      description: descController.text.trim(),
      amount: double.parse(amountController.text.replaceAll(',', '.')),
      isStock: isStock,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final entries = store.financialEntriesForPeriod(_period);
          final revenue = entries
              .where((e) => e.type == FinancialEntryType.revenue)
              .fold<double>(0, (sum, e) => sum + e.amount);
          final expense = entries
              .where((e) => e.type == FinancialEntryType.expense || e.type == FinancialEntryType.stock)
              .fold<double>(0, (sum, e) => sum + e.amount);
          final balance = revenue - expense;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              SegmentedButton<FinancialPeriod>(
                segments: FinancialPeriod.values
                    .map(
                      (p) => ButtonSegment<FinancialPeriod>(
                        value: p,
                        label: Text(_periodLabel(p)),
                      ),
                    )
                    .toList(),
                selected: {_period},
                onSelectionChanged: (value) {
                  setState(() {
                    _period = value.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Receita',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            AppFormatters.currency(revenue),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Despesas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            AppFormatters.currency(expense),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            balance >= 0 ? 'Saldo' : 'Prejuízo',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            AppFormatters.currency(balance.abs()),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReportsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Ver Relatório Detalhado'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Movimentações',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Nenhuma movimentação no período selecionado.'),
                  ),
                ),
              ...entries.map(
                (entry) => Card(
                  child: ListTile(
                    leading: Icon(
                      _entryTypeIcon(entry.type),
                      color: _entryTypeColor(entry.type),
                    ),
                    title: Text(entry.description),
                    subtitle: Text(
                      '${_entryTypeLabel(entry.type)} | ${AppFormatters.date(entry.createdAt)} ${AppFormatters.time(entry.createdAt)}',
                    ),
                    trailing: Text(
                      AppFormatters.currency(entry.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _entryTypeColor(entry.type),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExpense(store),
        icon: const Icon(Icons.add),
        label: const Text('Nova Despesa'),
      ),
    );
  }
}
