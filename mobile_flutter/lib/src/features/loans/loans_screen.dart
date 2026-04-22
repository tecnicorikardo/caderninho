import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';
import '../../core/subscription_middleware.dart';
import '../shared/gradient_card.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final _subscriptionMiddleware = SubscriptionMiddleware();

  String _errorText(Object error) {
    if (error is FirebaseException) {
      return error.message ?? 'Falha ao salvar no Firebase.';
    }
    return error.toString();
  }

  Future<void> _newLoan(AppStore store) async {
    final canAccess = await _subscriptionMiddleware.checkAccess(context, 'addLoan');
    if (!canAccess) return;

    final customerController = TextEditingController();
    final amountController = TextEditingController();
    final dueDateController = TextEditingController(
      text: AppFormatters.date(DateTime.now().add(const Duration(days: 30))),
    );
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
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Informe o cliente'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor emprestado',
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
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: dueDateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Vencimento'),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                        initialDate: DateTime.now().add(
                          const Duration(days: 30),
                        ),
                      );
                      if (selected == null) return;
                      dueDateController.text = AppFormatters.date(selected);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: interestController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Juros (%)'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<LoanInterestUnit>(
                    value: interestUnit,
                    decoration: const InputDecoration(
                      labelText: 'Periodicidade dos juros',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: LoanInterestUnit.day,
                        child: Text('Ao dia'),
                      ),
                      DropdownMenuItem(
                        value: LoanInterestUnit.month,
                        child: Text('Ao mes'),
                      ),
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

    final parts = dueDateController.text.split('/');
    final dueDate = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );

    try {
      await store.addLoan(
        customerName: customerController.text.trim(),
        principal: double.parse(amountController.text.replaceAll(',', '.')),
        dueDate: dueDate,
        interestRate:
            double.tryParse(interestController.text.replaceAll(',', '.')) ?? 0,
        interestUnit: interestUnit,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Emprestimo salvo.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  Future<void> _payLoan(AppStore store, LoanRecord loan) async {
    final canAccess = await _subscriptionMiddleware.checkAccess(context, 'addPayment');
    if (!canAccess) return;

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
              helperText:
                  'Saldo atual: ${AppFormatters.currency(store.getLoanOpenAmount(loan))}',
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

    final error = await store.payLoan(
      loanId: loan.id,
      amount: double.parse(amountController.text.replaceAll(',', '.')),
    );
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emprestimos'),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Configurar alerta de vencimento',
            icon: const Icon(Icons.notifications_active_outlined),
            initialValue: store.loanAlertDays,
            onSelected: (days) async {
              final messenger = ScaffoldMessenger.of(context);
              await store.setLoanAlertDays(days);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Alerta configurado para $days dia(s) antes do vencimento.',
                  ),
                ),
              );
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 3, child: Text('Alertar 3 dias antes')),
              PopupMenuItem(value: 5, child: Text('Alertar 5 dias antes')),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final loans = store.loans;
          final upcoming = store.upcomingLoanAlerts();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              GradientCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alerta de vencimento configurado: ${store.loanAlertDays} dia(s) antes',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Emprestimos com vencimento proximo: ${upcoming.length}',
                      ),
                    ],
                  ),
                ),
              ),
              GradientCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total em aberto (emprestimos)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(AppFormatters.currency(store.totalOpenLoans)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (loans.isEmpty)
                const GradientCard(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Nenhum emprestimo registrado.'),
                  ),
                ),
              ...loans.map((loan) {
                final open = store.getLoanOpenAmount(loan);
                return GradientCard(
                  child: ListTile(
                    title: Text(loan.customerName),
                    subtitle: Text(
                      'Principal: ${AppFormatters.currency(loan.principal)} | Vencimento: ${AppFormatters.date(loan.dueDate)}',
                    ),
                    trailing: SizedBox(
                      width: 160,
                      child: Column(
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
                  ),
                );
              }),
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
