import 'package:flutter/material.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';
import '../shared/gradient_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  FinancialPeriod _period = FinancialPeriod.day;

  String _periodLabel(FinancialPeriod period) {
    switch (period) {
      case FinancialPeriod.day:
        return 'Dia';
      case FinancialPeriod.week:
        return 'Semana';
      case FinancialPeriod.month:
        return 'Mes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatorios')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final report = store.getReportForPeriod(_period);
          final agingReport = store.getProductAgingReport();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              SegmentedButton<FinancialPeriod>(
                segments: FinancialPeriod.values
                    .map(
                      (period) => ButtonSegment<FinancialPeriod>(
                        value: period,
                        label: Text(_periodLabel(period)),
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
              const SizedBox(height: 16),
              GradientCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Faturamento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMetricRow(
                        'Receita Total',
                        AppFormatters.currency(report['revenue']),
                        Colors.green,
                      ),
                      const Divider(height: 20),
                      _buildMetricRow(
                        'Despesas Operacionais',
                        AppFormatters.currency(report['operationalExpenses']),
                        Colors.red,
                      ),
                      _buildMetricRow(
                        'Custo dos Produtos Vendidos (CPV)',
                        AppFormatters.currency(report['cpv']),
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GradientCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estoque Parado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMetricRow(
                        'Produtos parados',
                        '${agingReport['stagnantProductsCount']} produtos',
                        const Color(0xFFD97706),
                      ),
                      _buildMetricRow(
                        'Estoque antigo',
                        '${agingReport['oldStockCount']} produtos',
                        const Color(0xFFB91C1C),
                      ),
                      _buildMetricRow(
                        'Produtos sem saida',
                        '${agingReport['noSalesCount']} produtos',
                        Colors.blueGrey,
                      ),
                      const Divider(height: 20),
                      _buildMetricRow(
                        'Valor parado',
                        AppFormatters.currency(agingReport['pausedValue']),
                        const Color(0xFF7C3AED),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GradientCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lucro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMetricRow(
                        'Lucro Bruto',
                        AppFormatters.currency(report['grossProfit']),
                        report['grossProfit'] >= 0 ? Colors.green : Colors.red,
                      ),
                      _buildMetricRow(
                        'Lucro Liquido',
                        AppFormatters.currency(report['netProfit']),
                        report['netProfit'] >= 0 ? Colors.green : Colors.red,
                      ),
                      const Divider(height: 20),
                      _buildMetricRow(
                        'Margem de Lucro',
                        '${report['margin'].toStringAsFixed(1)}%',
                        report['margin'] >= 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GradientCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Metricas Inteligentes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMetricRow(
                        'Ticket Medio',
                        AppFormatters.currency(report['avgTicket']),
                        Colors.blue,
                      ),
                      _buildMetricRow(
                        'Quantidade de Vendas',
                        '${report['salesCount']} vendas',
                        Colors.blue,
                      ),
                      if (report['topProduct'] != null) ...[
                        const Divider(height: 20),
                        _buildMetricRow(
                          'Produto Mais Vendido',
                          '${report['topProduct']} (${report['topProductCount']}x)',
                          Colors.purple,
                        ),
                      ],
                      if (report['topExpense'] != null) ...[
                        const Divider(height: 20),
                        _buildMetricRow(
                          'Maior Despesa',
                          '${report['topExpense']}\n${AppFormatters.currency(report['topExpenseAmount'])}',
                          Colors.red,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GradientCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Marcas e Comissoes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMetricRow(
                        'Marcas com vendas',
                        '${report['totalBrandsSold']} marcas',
                        Colors.blue,
                      ),
                      _buildMetricRow(
                        'Comissao Total',
                        AppFormatters.currency(report['totalCommission']),
                        const Color(0xFF7C3AED),
                      ),
                      if (report['topBrand'] != null) ...[
                        const Divider(height: 20),
                        _buildMetricRow(
                          'Marca Lider',
                          '${report['topBrand']}',
                          const Color(0xFF2563EB),
                        ),
                        _buildMetricRow(
                          'Faturamento da Marca Lider',
                          AppFormatters.currency(report['topBrandRevenue']),
                          Colors.green,
                        ),
                        _buildMetricRow(
                          'Comissao da Marca Lider',
                          AppFormatters.currency(report['topBrandCommission']),
                          const Color(0xFF7C3AED),
                        ),
                      ] else ...[
                        const Divider(height: 20),
                        _buildMetricRow(
                          'Marca Lider',
                          'Sem vendas por marca no periodo',
                          Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GradientCard(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Sobre os Calculos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Lucro Bruto = Receita - CPV\n'
                        '• Lucro Liquido = Lucro Bruto - Despesas Operacionais\n'
                        '• Margem = (Lucro Liquido / Receita) x 100\n'
                        '• Comissao total considera as vendas vinculadas a marcas\n'
                        '• CPV = Custo dos produtos efetivamente vendidos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
