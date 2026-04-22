import 'package:flutter/material.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';

class FiadosScreen extends StatefulWidget {
  const FiadosScreen({super.key});

  @override
  State<FiadosScreen> createState() => _FiadosScreenState();
}

class _FiadosScreenState extends State<FiadosScreen> {
  Future<void> _newDebt(AppStore store) async {
    final customerController = TextEditingController();
    final descriptionController = TextEditingController(text: 'Fiado');
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo fiado'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: customerController,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe o cliente' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Valor do fiado'),
                  validator: (value) {
                    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) return 'Informe um valor valido';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(context).pop(true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    store.addDebt(
      customerName: customerController.text.trim(),
      description: descriptionController.text.trim().isEmpty ? 'Fiado' : descriptionController.text.trim(),
      amount: double.parse(amountController.text.replaceAll(',', '.')),
    );
  }

  Future<void> _payDebt(AppStore store, DebtRecord debt) async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Pagamento de ${debt.customerName}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Valor pago',
              helperText: 'Saldo atual: ${AppFormatters.currency(debt.openAmount)}',
            ),
            validator: (value) {
              final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
              if (parsed == null || parsed <= 0) return 'Informe um valor valido';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
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

    final error = store.payDebt(
      debtId: debt.id,
      amount: double.parse(amountController.text.replaceAll(',', '.')),
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Fiados (Devedores)')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final debts = store.debts;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total em aberto', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(AppFormatters.currency(store.totalOpenDebts + store.totalOpenLoans)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (debts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Nenhum fiado registrado.'),
                  ),
                ),
              ...debts.map(
                (debt) => Card(
                  child: ListTile(
                    title: Text(debt.customerName),
                    subtitle: Text('${debt.description} | ${AppFormatters.date(debt.createdAt)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(AppFormatters.currency(debt.openAmount)),
                        TextButton(
                          onPressed: () => _payDebt(store, debt),
                          child: const Text('Pagar parcial'),
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
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Novo fiado'),
      ),
    );
  }
}
