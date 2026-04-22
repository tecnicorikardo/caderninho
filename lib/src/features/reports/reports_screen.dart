import 'package:flutter/material.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';

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
        return 'Mês';
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final report = store.getReportForPeriod(_period);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
              const SizedBox(height: 16),
              
              // Card de Faturamento
              Card(
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
              
              // Card de Lucro
              Card(
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
                        'Lucro Líquido',
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
              
              // Card de Métricas Inteligentes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Métricas Inteligentes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMetricRow(
                        'Ticket Médio',
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
              
              // Card de Informações
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Sobre os Cálculos',
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
                        '• Lucro Líquido = Lucro Bruto - Despesas Operacionais\n'
                        '• Margem = (Lucro Líquido / Receita) × 100\n'
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
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
