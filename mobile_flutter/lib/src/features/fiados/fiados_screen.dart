import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';
import '../../core/subscription_middleware.dart';
import '../../core/utils/whatsapp.dart';
import 'widgets/cobranca_whatsapp_sheet.dart';
import '../shared/gradient_card.dart';

class FiadosScreen extends StatefulWidget {
  const FiadosScreen({super.key});

  @override
  State<FiadosScreen> createState() => _FiadosScreenState();
}

class _FiadosScreenState extends State<FiadosScreen> {
  final _subscriptionMiddleware = SubscriptionMiddleware();
  
  String _normalizeName(String value) => value.trim().toLowerCase();

  CustomerRecord? _customerByName(AppStore store, String customerName) {
    final normalized = _normalizeName(customerName);
    for (final customer in store.customers) {
      if (_normalizeName(customer.name) == normalized) {
        return customer;
      }
    }
    return null;
  }

  List<DebtRecord> _customerDebts(AppStore store, String customerName) {
    final normalized = _normalizeName(customerName);
    return store.debts
        .where((debt) => _normalizeName(debt.customerName) == normalized)
        .toList();
  }

  bool _isDebtPaymentForCustomer(
    FinancialEntry entry,
    String normalizedCustomerName,
  ) {
    if (entry.origin != 'fiado_payment') return false;
    final description = entry.description.trim().toLowerCase();
    if (!description.startsWith('pagamento de fiado:')) return false;
    final customerPart = description.split(':').last.trim();
    return customerPart == normalizedCustomerName;
  }

  List<Lancamento> _customerLancamentos(AppStore store, String customerName) {
    final normalized = _normalizeName(customerName);
    final customerDebts = _customerDebts(store, customerName);
    final paymentEntries = store.financialEntries
        .where((entry) => _isDebtPaymentForCustomer(entry, normalized))
        .toList();

    final fiados = customerDebts
        .map(
          (debt) => Lancamento(
            data: debt.createdAt,
            valor: debt.originalAmount,
            tipo: LancamentoTipo.fiado,
            observacao: debt.description,
          ),
        )
        .toList();
    final pagamentos = paymentEntries
        .map(
          (entry) => Lancamento(
            data: entry.createdAt,
            valor: entry.amount,
            tipo: LancamentoTipo.pagamento,
            observacao: entry.description,
          ),
        )
        .toList();

    return [...fiados, ...pagamentos];
  }

  double _customerTotalFiado(AppStore store, String customerName) {
    return _customerDebts(
      store,
      customerName,
    ).fold<double>(0, (acc, debt) => acc + debt.originalAmount);
  }

  double _customerTotalPago(AppStore store, String customerName) {
    return _customerDebts(
      store,
      customerName,
    ).fold<double>(0, (acc, debt) => acc + (debt.originalAmount - debt.openAmount));
  }

  double _customerSaldo(AppStore store, String customerName) {
    return _customerDebts(
      store,
      customerName,
    ).fold<double>(0, (acc, debt) => acc + debt.openAmount);
  }

  String _errorText(Object error) {
    if (error is FirebaseException) {
      return error.message ?? 'Falha ao salvar no Firebase.';
    }
    return error.toString();
  }

  Future<void> _newDebt(AppStore store) async {
    // Verificar acesso antes de permitir adicionar
    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'addDebt',
    );
    if (!canAccess) return;

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
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Informe o cliente'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor do fiado',
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
    );

    if (ok != true) return;

    try {
      await store.addDebt(
        customerName: customerController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? 'Fiado'
            : descriptionController.text.trim(),
        amount: double.parse(amountController.text.replaceAll(',', '.')),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fiado salvo.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  Future<void> _payDebt(AppStore store, DebtRecord debt) async {
    final canAccess = await _subscriptionMiddleware.checkAccess(context, 'addPayment');
    if (!canAccess) return;

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

    final error = await store.payDebt(
      debtId: debt.id,
      amount: double.parse(amountController.text.replaceAll(',', '.')),
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _cobrarCliente(AppStore store, DebtRecord debt) async {
    final customer = _customerByName(store, debt.customerName);
    final totalFiado = _customerTotalFiado(store, debt.customerName);
    final totalPago = _customerTotalPago(store, debt.customerName);
    final saldo = _customerSaldo(store, debt.customerName);
    final lancamentos = _customerLancamentos(store, debt.customerName);

    // Criterio: historico de cobranca = fiados em debts + pagamentos em
    // financial_entries com origin fiado_payment e cliente no texto.
    await showCobrancaWhatsappSheet(
      context: context,
      nomeCliente: debt.customerName,
      saldo: saldo,
      totalFiado: totalFiado,
      totalPago: totalPago,
      lancamentos: lancamentos,
      telefoneInicial: customer?.phone,
      pixKey: store.shopProfile.pixKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Fiados (Devedores)')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final debts = store.debts.where((debt) => debt.openAmount > 0).toList();
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
                        'Total em aberto',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppFormatters.currency(
                          store.totalOpenDebts + store.totalOpenLoans,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (debts.isEmpty)
                const GradientCard(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Nenhum fiado em aberto.'),
                  ),
                ),
              ...debts.map(
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
                                debt.customerName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(AppFormatters.currency(debt.openAmount)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${debt.description} | ${AppFormatters.date(debt.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _cobrarCliente(store, debt),
                              icon: const Icon(Icons.chat_outlined, size: 18),
                              label: const Text('Cobrar'),
                            ),
                            TextButton(
                              onPressed: () => _payDebt(store, debt),
                              child: const Text('Pagar parcial'),
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
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Novo fiado'),
      ),
    );
  }
}
