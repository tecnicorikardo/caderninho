import 'package:flutter/material.dart';

import '../features/subscription/services/subscription_service.dart';
import '../features/subscription/subscription_screen.dart';

class SubscriptionMiddleware {
  SubscriptionMiddleware({SubscriptionService? subscriptionService})
      : _subscriptionService =
            subscriptionService ?? SubscriptionService();

  final SubscriptionService _subscriptionService;

  /// Verifica se pode executar uma ação
  Future<bool> checkAccess(
    BuildContext context,
    String action,
  ) async {
    final isExpired = await _subscriptionService.isExpired();

    if (isExpired && _isWriteAction(action)) {
      if (context.mounted) {
        await _showExpiredDialog(context);
      }
      return false;
    }

    return true;
  }

  /// Identifica se é uma ação de escrita
  bool _isWriteAction(String action) {
    const writeActions = [
      'addCustomer',
      'updateCustomer',
      'addProduct',
      'updateProduct',
      'removeProduct',
      'registerSale',
      'removeSale',
      'addDebt',
      'addPayment',
      'removeDebt',
      'addLoan',
      'removeLoan',
      'addExpense',
      'addIncome',
      'removeEntry',
    ];

    return writeActions.contains(action);
  }

  /// Mostra modal de assinatura expirada
  Future<void> _showExpiredDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Assinatura Expirada'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sua assinatura expirou e você não pode mais adicionar ou editar dados.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Você ainda pode:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Visualizar todos os seus dados'),
            Text('• Exportar clientes para Excel'),
            Text('• Exportar produtos para Excel'),
            Text('• Exportar relatórios para Excel'),
            SizedBox(height: 16),
            Text(
              'Renove sua assinatura para continuar usando todas as funcionalidades.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.credit_card),
            label: const Text('Renovar Agora'),
          ),
        ],
      ),
    );
  }
}
