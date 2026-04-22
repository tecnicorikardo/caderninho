import 'package:flutter/material.dart';

import '../../../core/app_formatters.dart';
import '../../../theme/app_theme.dart';
import '../models/personal_category.dart';
import '../models/personal_transaction.dart';

class CategoryChart extends StatelessWidget {
  const CategoryChart({
    super.key,
    required this.transactions,
    required this.categories,
  });

  final List<PersonalTransaction> transactions;
  final List<PersonalCategory> categories;

  Map<String, double> _getCategoryTotals(TipoTransacao tipo) {
    final totals = <String, double>{};
    
    for (final transaction in transactions) {
      if (transaction.tipo == tipo && transaction.status == StatusTransacao.pago) {
        totals[transaction.categoriaId] = 
            (totals[transaction.categoriaId] ?? 0) + transaction.valor;
      }
    }
    
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final receitasTotals = _getCategoryTotals(TipoTransacao.receita);
    final despesasTotals = _getCategoryTotals(TipoTransacao.despesa);
    
    // Pegar top 5 categorias de cada tipo
    final topReceitas = receitasTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDespesas = despesasTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final maxReceita = topReceitas.isEmpty ? 0.0 : topReceitas.first.value;
    final maxDespesa = topDespesas.isEmpty ? 0.0 : topDespesas.first.value;
    final maxValue = maxReceita > maxDespesa ? maxReceita : maxDespesa;
    
    if (maxValue == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Nenhuma transação paga para exibir',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Receitas vs Despesas por Categoria',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Receitas
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Receitas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: topReceitas.take(5).map((entry) {
                          final category = categories.firstWhere(
                            (c) => c.id == entry.key,
                            orElse: () => categories.first,
                          );
                          final height = (entry.value / maxValue) * 120;
                          
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                children: [
                                  Text(
                                    AppFormatters.currency(entry.value),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: height.clamp(20, 120),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade400,
                                          Colors.green.shade600,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(
                                    category.icone,
                                    size: 16,
                                    color: category.cor,
                                  ),
                                  Text(
                                    category.nome,
                                    style: const TextStyle(fontSize: 9),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Despesas
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Despesas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: topDespesas.take(5).map((entry) {
                          final category = categories.firstWhere(
                            (c) => c.id == entry.key,
                            orElse: () => categories.first,
                          );
                          final height = (entry.value / maxValue) * 120;
                          
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                children: [
                                  Text(
                                    AppFormatters.currency(entry.value),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: height.clamp(20, 120),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.shade400,
                                          Colors.red.shade600,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(
                                    category.icone,
                                    size: 16,
                                    color: category.cor,
                                  ),
                                  Text(
                                    category.nome,
                                    style: const TextStyle(fontSize: 9),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
