import 'package:flutter/material.dart';

import '../../shared/app_formatters.dart';

class DaySummaryModal extends StatelessWidget {
  const DaySummaryModal({super.key, required this.salesCount, required this.salesTotal});

  final int salesCount;
  final double salesTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Resumo do Dia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            ],
          ),
          _MetricCard(
            title: 'Vendas do dia',
            subtitle: 'Quantidade: $salesCount | Total: ${AppFormatters.currency(salesTotal)}',
          ),
          const SizedBox(height: 10),
          const _MetricCard(
            title: 'Fiados do dia',
            subtitle: 'Quantidade: 0 | Em aberto: R\$ 0,00',
          ),
          const SizedBox(height: 10),
          _MetricCard(
            title: 'Financeiro do dia',
            subtitle: 'Receitas: ${AppFormatters.currency(salesTotal)} | Despesas: R\$ 0,00',
          ),
          const SizedBox(height: 14),
          const Text('Atalhos rapidos'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _QuickActionChip(label: 'Nova venda'),
              _QuickActionChip(label: 'Novo fiado'),
              _QuickActionChip(label: 'Novo cliente'),
              _QuickActionChip(label: 'Novo produto'),
              _QuickActionChip(label: 'Novo emprestimo'),
              _QuickActionChip(label: 'Registrar pagamento'),
            ],
          ),
          const SizedBox(height: 18),
        ],
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: () {}, avatar: const Icon(Icons.add, size: 16));
  }
}
