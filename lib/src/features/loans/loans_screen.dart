import 'package:flutter/material.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  Future<void> _newLoan(AppStore store) async {
    final customerController = TextEditingController();
    final amountController = TextEditingController();
    final dueDateController = TextEditingController(text: AppFormatters.date(DateTime.now().add(const Duration(days: 30))));
    final interestController = TextEditingController(text: '2');
    LoanInterestUnit interestUnit = LoanInterestUnit.month;
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Novo emprestimo'),
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
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Valor emprestado'),
                    validator: (value) {
                      final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) return 'Informe um valor valido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: dueDateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Vencimento'),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (selected == null) return;
                      dueDateController.text = AppFormatters.date(selected);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: interestController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Juros (%)'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<LoanInterestUnit>(
                    value: interestUnit,
                    decoration: const InputDecoration(labelText: 'Periodicidade dos juros'),
                    items: const [
                      DropdownMenuItem(value: LoanInterestUnit.day, child: Text('Ao dia')),
                      DropdownMenuItem(value: LoanInterestUnit.month, child: Text('Ao mes')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() {
                        interestUnit = value;
                      });
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
      ),
    );

    if (ok != true) return;

    final dueParts = dueDateController.text.split('/');
    final dueDate = DateTime(
      int.parse(dueParts[2]),
      int.parse(dueParts[1]),
      int.parse(dueParts[0]),
    );

    store.addLoan(
      customerName: customerController.text.trim(),
      principal: double.parse(amountController.text.replaceAll(',', '.')),
      dueDate: dueDate,
      interestRate: double.tryParse(interestController.text.replaceAll(',', '.')) ?? 0,
      interestUnit: interestUnit,
    );
  }

  Future<void> _payLoan(AppStore store, LoanRecord loan) async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Pagamento de ${loan.customerName}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Valor pago',
              helperText: 'Saldo atual: ${AppFormatters.currency(store.getLoanOpenAmount(loan))}',
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

    final error = store.payLoan(
      loanId: loan.id,
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
      appBar: AppBar(title: const Text('Emprestimos')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final loans = store.loans;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total em aberto (emprestimos)', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(AppFormatters.currency(store.totalOpenLoans)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (loans.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Nenhum emprestimo registrado.'),
                  ),
                ),
              ...loans.map(
                (loan) {
                  final open = store.getLoanOpenAmount(loan);
                  return Card(
                    child: ListTile(
                      title: Text(loan.customerName),
                      subtitle: Text(
                        'Principal: ${AppFormatters.currency(loan.principal)} | Vencimento: ${AppFormatters.date(loan.dueDate)}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(AppFormatters.currency(open)),
                          TextButton(
                            onPressed: () => _payLoan(store, loan),
                            child: const Text('Pagar'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newLoan(store),
        icon: const Icon(Icons.account_balance_outlined),
        label: const Text('Novo emprestimo'),
      ),
    );
  }
}
