import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_formatters.dart';
import '../../../theme/app_theme.dart';
import '../../shared/gradient_card.dart';
import '../controllers/personal_finance_controller.dart';
import '../models/personal_category.dart';
import '../models/personal_transaction.dart';
import 'transaction_form_screen.dart';

class PersonalReportsScreen extends StatelessWidget {
  const PersonalReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonalFinanceController>(
      builder: (context, controller, _) {
        final transactions = controller.transactions;

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma transação encontrada',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final totalReceitas = controller.totalReceitas;
        final totalDespesas = controller.totalDespesas;
        final totalReceitasPagas = controller.totalReceitasPagas;
        final totalDespesasPagas = controller.totalDespesasPagas;
        final saldo = totalReceitasPagas - totalDespesasPagas;

        // Agrupar por data
        final grouped = <String, List<PersonalTransaction>>{};
        for (final t in transactions) {
          final key = AppFormatters.date(t.dataPrevista);
          grouped.putIfAbsent(key, () => []).add(t);
        }

        final sortedDates = grouped.keys.toList()
          ..sort((a, b) => _parseDate(b).compareTo(_parseDate(a)));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Resumo geral
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo do Período',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppFormatters.currency(saldo),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Saldo (pagas)',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryCol(
                        'Receitas',
                        AppFormatters.currency(totalReceitas),
                        '${AppFormatters.currency(totalReceitasPagas)} pagas',
                      ),
                      _summaryCol(
                        'Despesas',
                        AppFormatters.currency(totalDespesas),
                        '${AppFormatters.currency(totalDespesasPagas)} pagas',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contadores
            Row(
              children: [
                Expanded(
                  child: GradientCard(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long, color: AppTheme.primary, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              '${transactions.length}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const Text('Total', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GradientCard(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              '${transactions.where((t) => t.status == StatusTransacao.pago).length}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const Text('Pagas', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GradientCard(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Icon(Icons.schedule, color: Colors.orange, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              '${transactions.where((t) => t.status == StatusTransacao.pendente).length}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const Text('Pendentes', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Todas as Transações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Lista agrupada por data
            ...sortedDates.map((dateKey) {
              final dayTransactions = grouped[dateKey]!;
              final totalDia = dayTransactions.fold<double>(
                0,
                (sum, t) => t.tipo == TipoTransacao.receita
                    ? sum + t.valor
                    : sum - t.valor,
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppFormatters.currency(totalDia),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: totalDia >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...dayTransactions.map((t) => _buildTransactionTile(context, controller, t)),
                  const SizedBox(height: 4),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _summaryCol(String label, String total, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(
          total,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    PersonalFinanceController controller,
    PersonalTransaction t,
  ) {
    final category = controller.getCategoryById(t.categoriaId);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (category?.cor ?? AppTheme.primary).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            category?.icone ?? Icons.attach_money,
            color: category?.cor ?? AppTheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          t.nome,
          style: TextStyle(
            decoration: t.status == StatusTransacao.pago ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${category?.nome ?? 'Sem categoria'} • ${t.status == StatusTransacao.pago ? 'Pago' : 'Pendente'}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          AppFormatters.currency(t.valor),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: t.tipo == TipoTransacao.receita ? Colors.green : Colors.red,
          ),
        ),
        onTap: () {
          if (!t.parcelado && !t.recorrente) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: controller,
                  child: TransactionFormScreen(transaction: t),
                ),
              ),
            );
          }
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
}
