import 'package:flutter/material.dart';

import '../../../core/app_formatters.dart';
import '../../../core/app_store.dart';
import '../../subscription/services/export_service.dart';
import '../product_pricing_analysis.dart';

class ProductPricingModal extends StatefulWidget {
  const ProductPricingModal({
    super.key,
    required this.products,
  });

  final List<ProductRecord> products;

  @override
  State<ProductPricingModal> createState() => _ProductPricingModalState();
}

class _ProductPricingModalState extends State<ProductPricingModal> {
  final TextEditingController _targetMarginController =
      TextEditingController(text: '30');
  final TextEditingController _searchController = TextEditingController();
  final ExportService _exportService = ExportService();

  double _targetMarginPercent = 30;
  String _search = '';
  bool _isExporting = false;

  @override
  void dispose() {
    _targetMarginController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ProductRecord> get _filteredProducts {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return widget.products;

    return widget.products.where((product) {
      final name = product.name.toLowerCase();
      final category = product.category.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();
  }

  List<ProductPricingAnalysis> get _analyses {
    final analyses = _filteredProducts
        .map(
          (product) => ProductPricingCalculator.analyze(
            product,
            targetMarginPercent: _targetMarginPercent,
          ),
        )
        .toList();

    analyses.sort((a, b) {
      if (a.isBelowTarget != b.isBelowTarget) {
        return a.isBelowTarget ? -1 : 1;
      }
      final deltaComparison = b.adjustmentValue.compareTo(a.adjustmentValue);
      if (deltaComparison != 0) return deltaComparison;
      return a.product.name.toLowerCase().compareTo(
            b.product.name.toLowerCase(),
          );
    });
    return analyses;
  }

  ProductPricingSummary get _summary => ProductPricingCalculator.summarize(
        _filteredProducts,
        targetMarginPercent: _targetMarginPercent,
      );

  String _percent(double value) => '${value.toStringAsFixed(1)}%';

  void _applyQuickTarget(double value) {
    final normalized = ProductPricingCalculator.normalizeTargetMargin(value);
    setState(() {
      _targetMarginPercent = normalized;
      _targetMarginController.text = normalized.toStringAsFixed(0);
    });
  }

  void _handleTargetMarginChanged(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return;
    final normalized = ProductPricingCalculator.normalizeTargetMargin(parsed);
    setState(() {
      _targetMarginPercent = normalized;
    });
    final normalizedText = normalized.toStringAsFixed(
      normalized.truncateToDouble() == normalized ? 0 : 1,
    );
    if (value != normalizedText && (parsed < 0 || parsed > 95)) {
      _targetMarginController.value = TextEditingValue(
        text: normalizedText,
        selection: TextSelection.collapsed(offset: normalizedText.length),
      );
    }
  }

  Future<void> _exportPricing() async {
    if (_isExporting) return;

    final products = _filteredProducts;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum produto para exportar.')),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final filePath = await _exportService.exportProductPricing(
        products,
        targetMarginPercent: _targetMarginPercent,
      );
      if (!mounted) return;
      final message = filePath == null
          ? 'Download da planilha iniciado.'
          : 'Planilha de precificacao salva em: $filePath';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar precificacao: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Color _statusColor(ProductPricingAnalysis analysis) {
    if (!analysis.hasCost) return const Color(0xFF475569);
    return analysis.isBelowTarget
        ? const Color(0xFFB45309)
        : const Color(0xFF166534);
  }

  @override
  Widget build(BuildContext context) {
    final analyses = _analyses;
    final summary = _summary;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Precificacao de Produtos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Analise custos, margem atual e preco sugerido com base na margem alvo sobre o preco de venda.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryCard(
                  label: 'Produtos',
                  value: '${summary.totalProducts}',
                ),
                _SummaryCard(
                  label: 'Abaixo da meta',
                  value: '${summary.productsBelowTarget}',
                  tone: summary.productsBelowTarget > 0
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF22C55E),
                ),
                _SummaryCard(
                  label: 'Margem media',
                  value: _percent(summary.averageMarginPercent),
                ),
                _SummaryCard(
                  label: 'Lucro potencial',
                  value: AppFormatters.currency(summary.currentPotentialProfit),
                ),
                _SummaryCard(
                  label: 'Impacto potencial',
                  value: AppFormatters.currency(summary.suggestedRevenueDelta),
                  tone: summary.suggestedRevenueDelta >= 0
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFB91C1C),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Margem alvo (%)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _targetMarginController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ex.: 30',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    onChanged: _handleTargetMarginChanged,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [20, 30, 40, 50].map((target) {
                      final selected = _targetMarginPercent.round() == target;
                      return ChoiceChip(
                        label: Text('$target%'),
                        selected: selected,
                        onSelected: (_) => _applyQuickTarget(target.toDouble()),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar no modal',
                hintText: 'Nome ou categoria',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          setState(() {
                            _search = '';
                            _searchController.clear();
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _exportPricing,
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined),
                label: Text(
                  _isExporting
                      ? 'Exportando...'
                      : 'Exportar precificacao para Excel',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: analyses.isEmpty
                  ? const Center(
                      child: Text('Nenhum produto encontrado para analise.'),
                    )
                  : ListView.separated(
                      itemCount: analyses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final analysis = analyses[index];
                        final statusColor = _statusColor(analysis);
                        final adjustmentText = analysis.hasCost
                            ? '${analysis.adjustmentValue >= 0 ? '+' : ''}${AppFormatters.currency(analysis.adjustmentValue)}'
                            : 'Sem calculo';

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          analysis.product.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${analysis.product.category} | Estoque: ${analysis.product.stock.toStringAsFixed(2)} ${analysis.product.unit}',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      analysis.statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _MetricChip(
                                    label: 'Custo',
                                    value: AppFormatters.currency(
                                      analysis.product.cost,
                                    ),
                                  ),
                                  _MetricChip(
                                    label: 'Venda atual',
                                    value: AppFormatters.currency(
                                      analysis.product.salePrice,
                                    ),
                                  ),
                                  _MetricChip(
                                    label: 'Lucro/un',
                                    value: AppFormatters.currency(
                                      analysis.profitPerUnit,
                                    ),
                                  ),
                                  _MetricChip(
                                    label: 'Markup',
                                    value: _percent(analysis.markupPercent),
                                  ),
                                  _MetricChip(
                                    label: 'Margem',
                                    value: _percent(analysis.marginPercent),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Preco sugerido: ${AppFormatters.currency(analysis.suggestedPrice)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ajuste necessario: $adjustmentText (${_percent(analysis.adjustmentPercent)})',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Receita potencial no estoque atual: ${AppFormatters.currency(analysis.potentialRevenue)}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    this.tone = const Color(0xFF0F172A),
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: tone),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
