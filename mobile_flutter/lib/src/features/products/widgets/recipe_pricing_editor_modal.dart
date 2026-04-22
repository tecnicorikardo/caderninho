import 'package:flutter/material.dart';

import '../../../core/app_formatters.dart';
import '../recipe_pricing_models.dart';

class RecipeTechnicalSheetEditorModal extends StatefulWidget {
  const RecipeTechnicalSheetEditorModal({
    super.key,
    this.initialRecipe,
  });

  final RecipeTechnicalSheet? initialRecipe;

  @override
  State<RecipeTechnicalSheetEditorModal> createState() =>
      _RecipeTechnicalSheetEditorModalState();
}

class _RecipeTechnicalSheetEditorModalState
    extends State<RecipeTechnicalSheetEditorModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _yieldQuantityController;
  late final TextEditingController _targetMarginController;
  late final TextEditingController _additionalCostController;
  late final TextEditingController _notesController;
  late RecipeMeasureUnit _yieldUnit;
  late List<RecipeIngredientItem> _ingredients;

  @override
  void initState() {
    super.initState();
    final recipe = widget.initialRecipe;
    _nameController = TextEditingController(text: recipe?.name ?? '');
    _yieldQuantityController = TextEditingController(
      text: recipe == null ? '1' : _formatInputNumber(recipe.yieldQuantity),
    );
    _targetMarginController = TextEditingController(
      text: recipe == null
          ? '30'
          : RecipePricingCalculator.normalizeMargin(
              recipe.targetMarginPercent,
            ).toStringAsFixed(0),
    );
    _additionalCostController = TextEditingController(
      text: recipe == null || recipe.additionalCost == 0
          ? ''
          : recipe.additionalCost.toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: recipe?.notes ?? '');
    _yieldUnit = recipe?.yieldUnit ?? RecipeMeasureUnit.unit;
    _ingredients = recipe?.ingredients.toList() ?? <RecipeIngredientItem>[];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yieldQuantityController.dispose();
    _targetMarginController.dispose();
    _additionalCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parseDecimal(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  String _formatInputNumber(double value) {
    if (value.truncateToDouble() == value) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  RecipeTechnicalSheet _buildDraft() {
    final now = DateTime.now();
    return RecipeTechnicalSheet(
      id: widget.initialRecipe?.id ?? now.microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      yieldQuantity: _parseDecimal(_yieldQuantityController.text),
      yieldUnit: _yieldUnit,
      targetMarginPercent: _parseDecimal(_targetMarginController.text),
      additionalCost: _parseDecimal(_additionalCostController.text),
      notes: _notesController.text.trim(),
      ingredients: _ingredients,
      createdAt: widget.initialRecipe?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _addIngredient() async {
    final ingredient = await showDialog<RecipeIngredientItem>(
      context: context,
      builder: (_) => const _IngredientDialog(),
    );
    if (ingredient == null) return;
    setState(() {
      _ingredients = [..._ingredients, ingredient];
    });
  }

  Future<void> _editIngredient(RecipeIngredientItem ingredient) async {
    final updated = await showDialog<RecipeIngredientItem>(
      context: context,
      builder: (_) => _IngredientDialog(initialIngredient: ingredient),
    );
    if (updated == null) return;
    setState(() {
      _ingredients = _ingredients
          .map((item) => item.id == ingredient.id ? updated : item)
          .toList();
    });
  }

  void _removeIngredient(RecipeIngredientItem ingredient) {
    setState(() {
      _ingredients =
          _ingredients.where((item) => item.id != ingredient.id).toList();
    });
  }

  void _save() {
    final draft = _buildDraft();
    final analysis = RecipePricingCalculator.analyzeSheet(draft);

    if (draft.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome da receita.')),
      );
      return;
    }
    if (draft.yieldQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o rendimento/tamanho.')),
      );
      return;
    }
    if (draft.ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um ingrediente.')),
      );
      return;
    }
    if (analysis.invalidIngredients > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revise os ingredientes com medidas invalidas.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      draft.copyWith(
        targetMarginPercent: RecipePricingCalculator.normalizeMargin(
          draft.targetMarginPercent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = _buildDraft();
    final analysis = RecipePricingCalculator.analyzeSheet(draft);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.94,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.initialRecipe == null
                        ? 'Nova ficha tecnica'
                        : 'Editar ficha tecnica',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dados da receita',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da receita/produto',
                            hintText: 'Ex.: Acai 500ml tradicional',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _yieldQuantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Tamanho/rendimento',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child:
                                  DropdownButtonFormField<RecipeMeasureUnit>(
                                value: _yieldUnit,
                                decoration: const InputDecoration(
                                  labelText: 'Unidade',
                                ),
                                items: RecipeMeasureUnit.values.map((unit) {
                                  return DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit.label),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _yieldUnit = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _targetMarginController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Margem alvo (%)',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _additionalCostController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Custos extras',
                                  hintText: 'Embalagem, gas, taxa...',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _notesController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Observacoes',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetricPill(
                          label: 'Ingredientes',
                          value: AppFormatters.currency(analysis.ingredientsCost),
                        ),
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
                          label: 'Status',
                          value: analysis.statusLabel,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ingredientes/insumos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _addIngredient,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_ingredients.isEmpty)
                    const Text(
                      'Nenhum ingrediente adicionado ainda.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ..._ingredients.map((ingredient) {
                    final itemAnalysis =
                        RecipePricingCalculator.analyzeIngredient(ingredient);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ingredient.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _editIngredient(ingredient),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () => _removeIngredient(ingredient),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            Text(
                              'Compra: ${ingredient.purchaseQuantity.toStringAsFixed(2)} ${ingredient.purchaseUnit.label} por ${AppFormatters.currency(ingredient.purchaseCost)}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Uso: ${ingredient.usageQuantity.toStringAsFixed(2)} ${ingredient.usageUnit.label} | Perda: ${ingredient.wastePercent.toStringAsFixed(1)}%',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              itemAnalysis.valid
                                  ? 'Custo calculado: ${AppFormatters.currency(itemAnalysis.totalCost)}'
                                  : 'Revisar: ${itemAnalysis.issue}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: itemAnalysis.valid
                                    ? const Color(0xFF166534)
                                    : const Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Salvar ficha tecnica'),
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

class _IngredientDialog extends StatefulWidget {
  const _IngredientDialog({this.initialIngredient});

  final RecipeIngredientItem? initialIngredient;

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _purchaseQuantityController;
  late final TextEditingController _purchaseCostController;
  late final TextEditingController _usageQuantityController;
  late final TextEditingController _wastePercentController;
  late RecipeMeasureUnit _purchaseUnit;
  late RecipeMeasureUnit _usageUnit;

  @override
  void initState() {
    super.initState();
    final ingredient = widget.initialIngredient;
    _nameController = TextEditingController(text: ingredient?.name ?? '');
    _purchaseQuantityController = TextEditingController(
      text: ingredient == null
          ? ''
          : ingredient.purchaseQuantity.toStringAsFixed(2),
    );
    _purchaseCostController = TextEditingController(
      text: ingredient == null ? '' : ingredient.purchaseCost.toStringAsFixed(2),
    );
    _usageQuantityController = TextEditingController(
      text: ingredient == null ? '' : ingredient.usageQuantity.toStringAsFixed(2),
    );
    _wastePercentController = TextEditingController(
      text: ingredient == null || ingredient.wastePercent == 0
          ? ''
          : ingredient.wastePercent.toStringAsFixed(1),
    );
    _purchaseUnit = ingredient?.purchaseUnit ?? RecipeMeasureUnit.gram;
    _usageUnit = ingredient?.usageUnit ?? _purchaseUnit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchaseQuantityController.dispose();
    _purchaseCostController.dispose();
    _usageQuantityController.dispose();
    _wastePercentController.dispose();
    super.dispose();
  }

  double _parseDecimal(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  RecipeIngredientItem _buildDraft() {
    final nowId = DateTime.now().microsecondsSinceEpoch.toString();
    final usageUnit = RecipePricingCalculator.compatibleUnits(
      _purchaseUnit,
      _usageUnit,
    )
        ? _usageUnit
        : RecipePricingCalculator.unitsForFamily(_purchaseUnit.family).first;
    return RecipeIngredientItem(
      id: widget.initialIngredient?.id ?? nowId,
      name: _nameController.text.trim(),
      purchaseQuantity: _parseDecimal(_purchaseQuantityController.text),
      purchaseUnit: _purchaseUnit,
      purchaseCost: _parseDecimal(_purchaseCostController.text),
      usageQuantity: _parseDecimal(_usageQuantityController.text),
      usageUnit: usageUnit,
      wastePercent: _parseDecimal(_wastePercentController.text),
    );
  }

  void _save() {
    final draft = _buildDraft();
    final analysis = RecipePricingCalculator.analyzeIngredient(draft);

    if (draft.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do ingrediente.')),
      );
      return;
    }
    if (draft.purchaseQuantity <= 0 || draft.usageQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe quantidades validas.')),
      );
      return;
    }
    if (!analysis.valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(analysis.issue ?? 'Revise os dados.')),
      );
      return;
    }

    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _buildDraft();
    final analysis = RecipePricingCalculator.analyzeIngredient(draft);
    final allowedUsageUnits = RecipePricingCalculator.unitsForFamily(
      _purchaseUnit.family,
    );
    final selectedUsageUnit = allowedUsageUnits.contains(_usageUnit)
        ? _usageUnit
        : allowedUsageUnits.first;

    return AlertDialog(
      title: Text(
        widget.initialIngredient == null
            ? 'Novo ingrediente'
            : 'Editar ingrediente',
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do ingrediente',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _purchaseQuantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Qtde comprada',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<RecipeMeasureUnit>(
                      value: _purchaseUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unid. compra',
                      ),
                      items: RecipeMeasureUnit.values.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _purchaseUnit = value;
                          if (_usageUnit.family != value.family) {
                            _usageUnit = RecipePricingCalculator.unitsForFamily(
                              value.family,
                            ).first;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _purchaseCostController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Custo da compra',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _usageQuantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Qtde usada',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<RecipeMeasureUnit>(
                      value: selectedUsageUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unid. usada',
                      ),
                      items: allowedUsageUnits.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _usageUnit = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _wastePercentController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Perda/quebra (%)',
                  hintText: 'Opcional',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  analysis.valid
                      ? 'Custo automatico: ${AppFormatters.currency(analysis.totalCost)}'
                      : 'Preencha os campos para calcular automaticamente.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: analysis.valid
                        ? const Color(0xFF166534)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Salvar ingrediente'),
        ),
      ],
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
