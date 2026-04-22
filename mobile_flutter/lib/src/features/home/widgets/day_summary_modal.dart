import 'package:flutter/material.dart';

import '../../../core/app_formatters.dart';
import '../../../core/app_store.dart';
import '../dashboard_screen.dart';

class DaySummaryModal extends StatelessWidget {
  const DaySummaryModal({
    super.key,
    required this.salesCount,
    required this.salesTotal,
    required this.fiadosCount,
    required this.fiadosOpenTotal,
    required this.revenue,
    required this.expense,
    required this.balance,
    required this.onActionSelected,
  });

  final int salesCount;
  final double salesTotal;
  final int fiadosCount;
  final double fiadosOpenTotal;
  final double revenue;
  final double expense;
  final double balance;
  final ValueChanged<DashboardModule> onActionSelected;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final now = DateTime.now();

    final todaysSales = store.sales
        .where((sale) => _isSameDay(sale.createdAt, now))
        .toList();
    final todaysDebts = store.debts
        .where((debt) => _isSameDay(debt.createdAt, now))
        .toList();
    final todaysEntries = store.financialEntries
        .where((entry) => _isSameDay(entry.createdAt, now))
        .toList();
    final lowStockProducts = store.products.where((p) => p.stock <= 5).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    final averageTicket = salesCount == 0 ? 0 : (salesTotal / salesCount);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Resumo Detalhado do Dia',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  _MetricCard(
                    title: 'Vendas do dia',
                    subtitle:
                        'Qtd: $salesCount | Total: ${AppFormatters.currency(salesTotal)} | Ticket medio: ${AppFormatters.currency(averageTicket)}',
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    title: 'Fiados do dia',
                    subtitle:
                        'Qtd: $fiadosCount | Em aberto: ${AppFormatters.currency(fiadosOpenTotal)}',
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    title: 'Financeiro do dia',
                    subtitle:
                        'Receitas: ${AppFormatters.currency(revenue)} | Despesas: ${AppFormatters.currency(expense)} | Saldo: ${AppFormatters.currency(balance)}',
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Estoque baixo (<= 5 unidades)',
                    child: lowStockProducts.isEmpty
                        ? const Text(
                            'Nenhum produto com estoque baixo no momento.',
                          )
                        : Column(
                            children: lowStockProducts.take(12).map((product) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 22,
                                  color: Color(0xFFB45309),
                                ),
                                title: Text(product.name),
                                subtitle: Text(
                                  'Categoria: ${product.category}',
                                ),
                                trailing: Text(
                                  '${product.stock.toStringAsFixed(2)} ${product.unit}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    title: 'Ultimas vendas do dia',
                    child: todaysSales.isEmpty
                        ? const Text('Nenhuma venda hoje.')
                        : Column(
                            children: todaysSales.take(8).map((sale) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(sale.description),
                                subtitle: Text(
                                  '${sale.paymentMethod} | ${AppFormatters.time(sale.createdAt)}',
                                ),
                                trailing: Text(
                                  AppFormatters.currency(sale.total),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    title: 'Fiados criados hoje',
                    child: todaysDebts.isEmpty
                        ? const Text('Nenhum registro hoje.')
                        : Column(
                            children: [
                              ...todaysDebts
                                  .take(6)
                                  .map(
                                    (debt) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        'Fiado - ${debt.customerName}',
                                      ),
                                      subtitle: Text(
                                        '${debt.description} | ${AppFormatters.time(debt.createdAt)}',
                                      ),
                                      trailing: Text(
                                        AppFormatters.currency(debt.openAmount),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 10),
                  _SectionCard(
                    title: 'Lancamentos financeiros de hoje',
                    child: todaysEntries.isEmpty
                        ? const Text('Nenhum lancamento financeiro hoje.')
                        : Column(
                            children: todaysEntries.take(10).map((entry) {
                              final positive =
                                  entry.type == FinancialEntryType.revenue;
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  positive
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: positive ? Colors.green : Colors.red,
                                  size: 22,
                                ),
                                title: Text(entry.description),
                                subtitle: Text(
                                  '${entry.origin} | ${AppFormatters.time(entry.createdAt)}',
                                ),
                                trailing: Text(
                                  AppFormatters.currency(entry.amount),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Atalhos rapidos'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickActionChip(
                        label: 'Nova venda',
                        onTap: () => onActionSelected(DashboardModule.vendas),
                      ),
                      _QuickActionChip(
                        label: 'Novo fiado',
                        onTap: () => onActionSelected(DashboardModule.fiados),
                      ),
                      _QuickActionChip(
                        label: 'Novo cliente',
                        onTap: () => onActionSelected(DashboardModule.clientes),
                      ),
                      _QuickActionChip(
                        label: 'Novo produto',
                        onTap: () => onActionSelected(DashboardModule.produtos),
                      ),
                      _QuickActionChip(
                        label: 'Ir para financeiro',
                        onTap: () =>
                            onActionSelected(DashboardModule.financeiro),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF1F5F9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(subtitle),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: const Icon(Icons.add, size: 16),
    );
  }
}
