class RecipeTechnicalSheet {
  const RecipeTechnicalSheet({
    required this.id,
    required this.name,
    required this.yieldQuantity,
    required this.yieldUnit,
    required this.targetMarginPercent,
    required this.additionalCost,
    required this.notes,
    required this.ingredients,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double yieldQuantity;
  final RecipeMeasureUnit yieldUnit;
  final double targetMarginPercent;
  final double additionalCost;
  final String notes;
  final List<RecipeIngredientItem> ingredients;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecipeTechnicalSheet copyWith({
    String? id,
    String? name,
    double? yieldQuantity,
    RecipeMeasureUnit? yieldUnit,
    double? targetMarginPercent,
    double? additionalCost,
    String? notes,
    List<RecipeIngredientItem>? ingredients,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecipeTechnicalSheet(
      id: id ?? this.id,
      name: name ?? this.name,
      yieldQuantity: yieldQuantity ?? this.yieldQuantity,
      yieldUnit: yieldUnit ?? this.yieldUnit,
      targetMarginPercent: targetMarginPercent ?? this.targetMarginPercent,
      additionalCost: additionalCost ?? this.additionalCost,
      notes: notes ?? this.notes,
      ingredients: ingredients ?? this.ingredients,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'yieldQuantity': yieldQuantity,
      'yieldUnit': yieldUnit.name,
      'targetMarginPercent': targetMarginPercent,
      'additionalCost': additionalCost,
      'notes': notes,
      'ingredients': ingredients.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RecipeTechnicalSheet.fromJson(Map<String, dynamic> json) {
    return RecipeTechnicalSheet(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      yieldQuantity: _asDouble(json['yieldQuantity']),
      yieldUnit: RecipeMeasureUnit.values.byName(
        (json['yieldUnit'] ?? RecipeMeasureUnit.unit.name).toString(),
      ),
      targetMarginPercent: _asDouble(json['targetMarginPercent']),
      additionalCost: _asDouble(json['additionalCost']),
      notes: (json['notes'] ?? '').toString(),
      ingredients: ((json['ingredients'] as List<dynamic>?) ?? const [])
          .map(
            (item) => RecipeIngredientItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      createdAt: _dateFrom(json['createdAt']),
      updatedAt: _dateFrom(json['updatedAt']),
    );
  }
}

class RecipeIngredientItem {
  const RecipeIngredientItem({
    required this.id,
    required this.name,
    required this.purchaseQuantity,
    required this.purchaseUnit,
    required this.purchaseCost,
    required this.usageQuantity,
    required this.usageUnit,
    required this.wastePercent,
  });

  final String id;
  final String name;
  final double purchaseQuantity;
  final RecipeMeasureUnit purchaseUnit;
  final double purchaseCost;
  final double usageQuantity;
  final RecipeMeasureUnit usageUnit;
  final double wastePercent;

  RecipeIngredientItem copyWith({
    String? id,
    String? name,
    double? purchaseQuantity,
    RecipeMeasureUnit? purchaseUnit,
    double? purchaseCost,
    double? usageQuantity,
    RecipeMeasureUnit? usageUnit,
    double? wastePercent,
  }) {
    return RecipeIngredientItem(
      id: id ?? this.id,
      name: name ?? this.name,
      purchaseQuantity: purchaseQuantity ?? this.purchaseQuantity,
      purchaseUnit: purchaseUnit ?? this.purchaseUnit,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      usageQuantity: usageQuantity ?? this.usageQuantity,
      usageUnit: usageUnit ?? this.usageUnit,
      wastePercent: wastePercent ?? this.wastePercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'purchaseQuantity': purchaseQuantity,
      'purchaseUnit': purchaseUnit.name,
      'purchaseCost': purchaseCost,
      'usageQuantity': usageQuantity,
      'usageUnit': usageUnit.name,
      'wastePercent': wastePercent,
    };
  }

  factory RecipeIngredientItem.fromJson(Map<String, dynamic> json) {
    return RecipeIngredientItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      purchaseQuantity: _asDouble(json['purchaseQuantity']),
      purchaseUnit: RecipeMeasureUnit.values.byName(
        (json['purchaseUnit'] ?? RecipeMeasureUnit.unit.name).toString(),
      ),
      purchaseCost: _asDouble(json['purchaseCost']),
      usageQuantity: _asDouble(json['usageQuantity']),
      usageUnit: RecipeMeasureUnit.values.byName(
        (json['usageUnit'] ?? RecipeMeasureUnit.unit.name).toString(),
      ),
      wastePercent: _asDouble(json['wastePercent']),
    );
  }
}

enum RecipeMeasureFamily { mass, volume, unit }

enum RecipeMeasureUnit {
  gram,
  kilogram,
  milliliter,
  liter,
  unit,
  portion,
}

extension RecipeMeasureUnitX on RecipeMeasureUnit {
  String get label {
    switch (this) {
      case RecipeMeasureUnit.gram:
        return 'g';
      case RecipeMeasureUnit.kilogram:
        return 'kg';
      case RecipeMeasureUnit.milliliter:
        return 'ml';
      case RecipeMeasureUnit.liter:
        return 'l';
      case RecipeMeasureUnit.unit:
        return 'un';
      case RecipeMeasureUnit.portion:
        return 'porcao';
    }
  }

  RecipeMeasureFamily get family {
    switch (this) {
      case RecipeMeasureUnit.gram:
      case RecipeMeasureUnit.kilogram:
        return RecipeMeasureFamily.mass;
      case RecipeMeasureUnit.milliliter:
      case RecipeMeasureUnit.liter:
        return RecipeMeasureFamily.volume;
      case RecipeMeasureUnit.unit:
      case RecipeMeasureUnit.portion:
        return RecipeMeasureFamily.unit;
    }
  }

  double get factorToBase {
    switch (this) {
      case RecipeMeasureUnit.gram:
      case RecipeMeasureUnit.milliliter:
      case RecipeMeasureUnit.unit:
      case RecipeMeasureUnit.portion:
        return 1;
      case RecipeMeasureUnit.kilogram:
      case RecipeMeasureUnit.liter:
        return 1000;
    }
  }
}

class RecipeIngredientCostResult {
  const RecipeIngredientCostResult({
    required this.ingredient,
    required this.valid,
    required this.unitCost,
    required this.baseCost,
    required this.totalCost,
    required this.issue,
  });

  final RecipeIngredientItem ingredient;
  final bool valid;
  final double unitCost;
  final double baseCost;
  final double totalCost;
  final String? issue;
}

class RecipeTechnicalSheetResult {
  const RecipeTechnicalSheetResult({
    required this.sheet,
    required this.ingredients,
    required this.ingredientsCost,
    required this.totalCost,
    required this.suggestedPrice,
    required this.suggestedProfit,
    required this.costPerYieldUnit,
    required this.invalidIngredients,
  });

  final RecipeTechnicalSheet sheet;
  final List<RecipeIngredientCostResult> ingredients;
  final double ingredientsCost;
  final double totalCost;
  final double suggestedPrice;
  final double suggestedProfit;
  final double costPerYieldUnit;
  final int invalidIngredients;

  bool get canSuggestPrice =>
      invalidIngredients == 0 && totalCost > 0 && sheet.ingredients.isNotEmpty;

  String get statusLabel {
    if (sheet.ingredients.isEmpty) return 'Sem ingredientes';
    if (invalidIngredients > 0) return 'Revisar medidas';
    return 'Calculado';
  }
}

class RecipePricingCalculator {
  static double normalizeMargin(double value) {
    if (value.isNaN || value.isInfinite) return 30;
    if (value < 0) return 0;
    if (value > 95) return 95;
    return value;
  }

  static bool compatibleUnits(
    RecipeMeasureUnit left,
    RecipeMeasureUnit right,
  ) {
    return left.family == right.family;
  }

  static List<RecipeMeasureUnit> unitsForFamily(RecipeMeasureFamily family) {
    return RecipeMeasureUnit.values
        .where((unit) => unit.family == family)
        .toList();
  }

  static double convertToBase({
    required double quantity,
    required RecipeMeasureUnit unit,
  }) {
    return quantity * unit.factorToBase;
  }

  static RecipeIngredientCostResult analyzeIngredient(
    RecipeIngredientItem ingredient,
  ) {
    if (ingredient.name.trim().isEmpty) {
      return RecipeIngredientCostResult(
        ingredient: ingredient,
        valid: false,
        unitCost: 0,
        baseCost: 0,
        totalCost: 0,
        issue: 'Ingrediente sem nome.',
      );
    }

    if (ingredient.purchaseQuantity <= 0) {
      return RecipeIngredientCostResult(
        ingredient: ingredient,
        valid: false,
        unitCost: 0,
        baseCost: 0,
        totalCost: 0,
        issue: 'Quantidade de compra precisa ser maior que zero.',
      );
    }

    if (ingredient.usageQuantity <= 0) {
      return RecipeIngredientCostResult(
        ingredient: ingredient,
        valid: false,
        unitCost: 0,
        baseCost: 0,
        totalCost: 0,
        issue: 'Quantidade usada precisa ser maior que zero.',
      );
    }

    if (!compatibleUnits(ingredient.purchaseUnit, ingredient.usageUnit)) {
      return RecipeIngredientCostResult(
        ingredient: ingredient,
        valid: false,
        unitCost: 0,
        baseCost: 0,
        totalCost: 0,
        issue: 'Unidades de compra e uso sao incompativeis.',
      );
    }

    final purchaseBase = convertToBase(
      quantity: ingredient.purchaseQuantity,
      unit: ingredient.purchaseUnit,
    );
    final usageBase = convertToBase(
      quantity: ingredient.usageQuantity,
      unit: ingredient.usageUnit,
    );
    final double unitCost = purchaseBase > 0
        ? ingredient.purchaseCost / purchaseBase
        : 0.0;
    final double baseCost = unitCost * usageBase;
    final double totalCost =
        baseCost * (1.0 + (ingredient.wastePercent / 100.0));

    return RecipeIngredientCostResult(
      ingredient: ingredient,
      valid: true,
      unitCost: unitCost,
      baseCost: baseCost,
      totalCost: totalCost,
      issue: null,
    );
  }

  static RecipeTechnicalSheetResult analyzeSheet(RecipeTechnicalSheet sheet) {
    final ingredientResults = sheet.ingredients.map(analyzeIngredient).toList();
    final ingredientsCost = ingredientResults
        .where((item) => item.valid)
        .fold<double>(0, (sum, item) => sum + item.totalCost);
    final invalidIngredients = ingredientResults.where((item) => !item.valid).length;
    final totalCost = ingredientsCost + sheet.additionalCost;
    final targetMargin = normalizeMargin(sheet.targetMarginPercent);
    final canSuggestPrice =
        invalidIngredients == 0 && totalCost > 0 && sheet.ingredients.isNotEmpty;
    final double suggestedPrice = canSuggestPrice && targetMargin < 100.0
        ? totalCost / (1.0 - (targetMargin / 100.0))
        : 0.0;
    final suggestedProfit = suggestedPrice - totalCost;
    final costPerYieldUnit = sheet.yieldQuantity > 0
        ? totalCost / sheet.yieldQuantity
        : totalCost;

    return RecipeTechnicalSheetResult(
      sheet: sheet.copyWith(targetMarginPercent: targetMargin),
      ingredients: ingredientResults,
      ingredientsCost: ingredientsCost,
      totalCost: totalCost,
      suggestedPrice: suggestedPrice,
      suggestedProfit: suggestedProfit,
      costPerYieldUnit: costPerYieldUnit,
      invalidIngredients: invalidIngredients,
    );
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}

DateTime _dateFrom(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
