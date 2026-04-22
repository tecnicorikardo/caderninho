import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_formatters.dart';
import '../../../theme/app_theme.dart';
import '../controllers/personal_finance_controller.dart';
import '../models/personal_category.dart';
import '../models/personal_transaction.dart';
import 'transaction_form_screen.dart';

class TransactionsListScreen extends StatelessWidget {
  const TransactionsListScreen({super.key});

  Future<void> _toggleStatus(
    BuildContext context,
    PersonalFinanceController controller,
    PersonalTransaction transaction,
  ) async {
    try {
      if (transaction.status == StatusTransacao.pendente) {
        await controller.markAsPaid(transactionId: transaction.id);
      } else {
        await controller.markAsPending(transaction.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    PersonalFinanceController controller,
    PersonalTransaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Transação'),
        content: Text(
          'Deseja realmente excluir "${transaction.nome}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await controller.deleteTransaction(transaction.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação excluída')),
        );
      }
    } catch (e) {
      if (context.mounted) {
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
        title: const Text('Todas as Transações'),
      ),
      body: Consumer<PersonalFinanceController>(
        builder: (context, controller, _) {
          if (controller.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma transação encontrada',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie sua primeira transação',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Agrupar por data
          final groupedTransactions = <String, List<PersonalTransaction>>{};
          for (final transaction in controller.transactions) {
            final dateKey = AppFormatters.date(transaction.dataPrevista);
            groupedTransactions.putIfAbsent(dateKey, () => []);
            groupedTransactions[dateKey]!.add(transaction);
          }

          final sortedDates = groupedTransactions.keys.toList()
            ..sort((a, b) {
              final dateA = _parseDate(a);
              final dateB = _parseDate(b);
              return dateB.compareTo(dateA);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final dateKey = sortedDates[index];
              final transactions = groupedTransactions[dateKey]!;
              final totalDia = transactions.fold<double>(
                0,
                (sum, t) {
                  if (t.tipo == TipoTransacao.receita) {
                    return sum + t.valor;
                  } else {
                    return sum - t.valor;
                  }
                },
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateKey,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppFormatters.currency(totalDia),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: totalDia >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...transactions.map((transaction) {
                    final category = controller.getCategoryById(
                      transaction.categoriaId,
                    );
                    final account = controller.accounts.firstWhere(
                      (a) => a.id == transaction.contaId,
                      orElse: () => controller.accounts.first,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (category?.cor ?? AppTheme.primary)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            category?.icone ?? Icons.attach_money,
                            color: category?.cor ?? AppTheme.primary,
                          ),
                        ),
                        title: Text(
                          transaction.nome,
                          style: TextStyle(
                            decoration: transaction.status == StatusTransacao.pago
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${category?.nome ?? 'Sem categoria'} • ${account.nome}',
                            ),
                            if (transaction.parcelado)
                              Text(
                                'Parcela ${transaction.parcelaAtual}/${transaction.numeroParcelas}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            if (transaction.recorrente)
                              Text(
                                'Recorrente (${transaction.frequencia?.name})',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.currency(transaction.valor),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: transaction.tipo == TipoTransacao.receita
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: transaction.status == StatusTransacao.pago
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                transaction.status == StatusTransacao.pago
                                    ? 'Pago'
                                    : 'Pendente',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: transaction.status == StatusTransacao.pago
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          _showTransactionOptions(
                            context,
                            controller,
                            transaction,
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  void _showTransactionOptions(
    BuildContext context,
    PersonalFinanceController controller,
    PersonalTransaction transaction,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                transaction.status == StatusTransacao.pago
                    ? Icons.undo
                    : Icons.check_circle,
              ),
              title: Text(
                transaction.status == StatusTransacao.pago
                    ? 'Marcar como pendente'
                    : 'Marcar como pago',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleStatus(context, controller, transaction);
              },
            ),
            if (!transaction.parcelado && !transaction.recorrente)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: controller,
                        child: TransactionFormScreen(
                          transaction: transaction,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Excluir',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteTransaction(context, controller, transaction);
              },
            ),
          ],
        ),
      ),
    );
  }
}
