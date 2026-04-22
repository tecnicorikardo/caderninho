import 'package:flutter/material.dart';

import '../../../core/app_formatters.dart';
import '../../../core/app_store.dart';
import '../../shared/gradient_card.dart';
import '../../subscription/services/export_service.dart';
import '../recipe_pricing_models.dart';
import '../recipe_pricing_storage.dart';
import 'recipe_pricing_editor_modal.dart';

class RecipePricingHubModal extends StatefulWidget {
  const RecipePricingHubModal({super.key});

  @override
  State<RecipePricingHubModal> createState() => _RecipePricingHubModalState();
}

class _RecipePricingHubModalState extends State<RecipePricingHubModal> {
  late RecipePricingStorage _storage;
  final ExportService _exportService = ExportService();

  List<RecipeTechnicalSheet> _recipes = const [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // initState não tem context ainda — usamos didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_storageInitialized) {
      final store = AppStoreScope.of(context);
      _storage = RecipePricingStorage(uid: store.uid);
      _storageInitialized = true;
      _loadRecipes();
    }
  }

  bool _storageInitialized = false;

  Future<void> _loadRecipes() async {
    final recipes = await _storage.loadRecipes();
    if (!mounted) return;
    setState(() {
      _recipes = recipes;
      _isLoading = false;
    });
  }

  Future<void> _persistRecipes(List<RecipeTechnicalSheet> recipes) async {
    final ordered = recipes.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    // Salva apenas a receita que mudou (a última da lista ordenada por updatedAt)
    if (ordered.isNotEmpty) {
      await _storage.saveRecipe(ordered.first);
    }
    if (!mounted) return;
    setState(() {
      _recipes = ordered;
    });
  }

  Future<void> _openEditor({RecipeTechnicalSheet? recipe}) async {
    final savedRecipe = await showModalBottomSheet<RecipeTechnicalSheet>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RecipeTechnicalSheetEditorModal(initialRecipe: recipe),
    );
    if (savedRecipe == null) return;

    final updated = _recipes.where((item) => item.id != savedRecipe.id).toList()
      ..add(savedRecipe);
    await _persistRecipes(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          recipe == null
              ? 'Ficha tecnica salva com sucesso.'
              : 'Ficha tecnica atualizada com sucesso.',
        ),
      ),
    );
  }

  Future<void> _duplicateRecipe(RecipeTechnicalSheet recipe) async {
    final now = DateTime.now();
    final duplicate = recipe.copyWith(
      id: now.microsecondsSinceEpoch.toString(),
      name: '${recipe.name} - copia',
      createdAt: now,
      updatedAt: now,
    );
    final updated = _recipes.toList()..add(duplicate);
    await _persistRecipes(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ficha tecnica duplicada.')),
    );
  }

  Future<void> _deleteRecipe(RecipeTechnicalSheet recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir ficha tecnica'),
        content: Text('Deseja excluir "${recipe.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _storage.deleteRecipe(recipe.id);
    if (!mounted) return;
    setState(() {
      _recipes = _recipes.where((item) => item.id != recipe.id).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ficha tecnica excluida.')),
    );
  }

  Future<void> _exportRecipes() async {
    if (_isExporting || _recipes.isEmpty) return;

    setState(() => _isExporting = true);
    try {
      final filePath = await _exportService.exportRecipeTechnicalSheets(_recipes);
      if (!mounted) return;
      final message = filePath == null
          ? 'Download da planilha iniciado.'
          : 'Planilha salva em: $filePath';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar fichas tecnicas: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalIngredients = _recipes.fold<int>(
      0,
      (sum, item) => sum + item.ingredients.length,
    );

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.94,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ficha Tecnica para Acai e Comidas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
              'Recurso separado do cadastro de produtos. Monte receitas com insumos, quantidades e custo automatico.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HubSummaryCard(label: 'Fichas salvas', value: '${_recipes.length}'),
                _HubSummaryCard(label: 'Ingredientes', value: '$totalIngredients'),
                const _HubSummaryCard(label: 'Armazenamento', value: 'Nuvem'),
              ],
            ),
            const SizedBox(height: 12),
            GradientCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exemplos de uso',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Acai 500ml, marmita, lanche, prato feito, sobremesa ou qualquer receita com ingredientes e medidas.',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _openEditor(),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Nova ficha tecnica'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _recipes.isEmpty || _isExporting
                              ? null
                              : _exportRecipes,
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.file_download_outlined),
                          label: Text(
                            _isExporting
                                ? 'Exportando...'
                                : 'Exportar para Excel',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _recipes.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma ficha tecnica salva ainda.\nCrie a primeira para calcular o custo de uma receita.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          itemCount: _recipes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final recipe = _recipes[index];
                            final analysis =
                                RecipePricingCalculator.analyzeSheet(recipe);
                            return _RecipeTechnicalSheetCard(
                              recipe: recipe,
                              analysis: analysis,
                              onEdit: () => _openEditor(recipe: recipe),
                              onDuplicate: () => _duplicateRecipe(recipe),
                              onDelete: () => _deleteRecipe(recipe),
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

class _RecipeTechnicalSheetCard extends StatelessWidget {
  const _RecipeTechnicalSheetCard({
    required this.recipe,
    required this.analysis,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final RecipeTechnicalSheet recipe;
  final RecipeTechnicalSheetResult analysis;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rendimento: ${recipe.yieldQuantity.toStringAsFixed(2)} ${recipe.yieldUnit.label} | Ingredientes: ${recipe.ingredients.length}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'duplicate') onDuplicate();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'duplicate', child: Text('Duplicar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(
                label: 'Custo total',
                value: AppFormatters.currency(analysis.totalCost),
              ),
              _MetricPill(
                label: 'Preco sugerido',
                value: analysis.canSuggestPrice
                    ? AppFormatters.currency(analysis.suggestedPrice)
                    : 'Revisar',
              ),
              _MetricPill(
                label: 'Margem alvo',
                value:
                    '${RecipePricingCalculator.normalizeMargin(recipe.targetMarginPercent).toStringAsFixed(0)}%',
              ),
              _MetricPill(
                label: 'Status',
                value: analysis.statusLabel,
              ),
            ],
          ),
          if (recipe.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              recipe.notes,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Principais insumos',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...analysis.ingredients.take(4).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text(item.ingredient.name)),
                  Text(
                    item.valid
                        ? AppFormatters.currency(item.totalCost)
                        : 'Revisar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: item.valid
                          ? const Color(0xFF166534)
                          : const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar ficha'),
              ),
              TextButton.icon(
                onPressed: onDuplicate,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Duplicar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HubSummaryCard extends StatelessWidget {
  const _HubSummaryCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
