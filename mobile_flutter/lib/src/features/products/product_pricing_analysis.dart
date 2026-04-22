import '../../core/app_store.dart';

class ProductPricingAnalysis {
  const ProductPricingAnalysis({
    required this.product,
    required this.targetMarginPercent,
    required this.profitPerUnit,
    required this.markupPercent,
    required this.marginPercent,
    required this.suggestedPrice,
    required this.adjustmentValue,
    required this.adjustmentPercent,
    required this.potentialRevenue,
    required this.potentialProfit,
    required this.suggestedPotentialRevenue,
    required this.isBelowTarget,
    required this.hasCost,
  });

  final ProductRecord product;
  final double targetMarginPercent;
  final double profitPerUnit;
  final double markupPercent;
  final double marginPercent;
  final double suggestedPrice;
  final double adjustmentValue;
  final double adjustmentPercent;
  final double potentialRevenue;
  final double potentialProfit;
  final double suggestedPotentialRevenue;
  final bool isBelowTarget;
  final bool hasCost;

  String get statusLabel {
    if (!hasCost) return 'Sem custo';
    return isBelowTarget ? 'Abaixo da meta' : 'Na meta';
  }
}

class ProductPricingSummary {
  const ProductPricingSummary({
    required this.totalProducts,
    required this.productsBelowTarget,
    required this.currentPotentialRevenue,
    required this.currentPotentialProfit,
    required this.suggestedPotentialRevenue,
    required this.averageMarginPercent,
  });

  final int totalProducts;
  final int productsBelowTarget;
  final double currentPotentialRevenue;
  final double currentPotentialProfit;
  final double suggestedPotentialRevenue;
  final double averageMarginPercent;

  double get suggestedRevenueDelta =>
      suggestedPotentialRevenue - currentPotentialRevenue;
}

class ProductPricingCalculator {
  static double normalizeTargetMargin(double value) {
    if (value.isNaN || value.isInfinite) return 30;
    if (value < 0) return 0;
    if (value > 95) return 95;
    return value;
  }

  static ProductPricingAnalysis analyze(
    ProductRecord product, {
    required double targetMarginPercent,
  }) {
    final safeTargetMargin = normalizeTargetMargin(targetMarginPercent);
    final hasCost = product.cost > 0;
    final profitPerUnit = product.salePrice - product.cost;
    final double markupPercent =
        hasCost ? (profitPerUnit / product.cost) * 100.0 : 0.0;
    final double marginPercent = product.salePrice > 0
        ? (profitPerUnit / product.salePrice) * 100.0
        : 0.0;
    final targetRatio = safeTargetMargin / 100;
    final suggestedPrice = hasCost && targetRatio < 1
        ? product.cost / (1 - targetRatio)
        : product.salePrice;
    final adjustmentValue = suggestedPrice - product.salePrice;
    final double adjustmentPercent = product.salePrice > 0
        ? (adjustmentValue / product.salePrice) * 100.0
        : 0.0;
    final potentialRevenue = product.salePrice * product.stock;
    final potentialProfit = profitPerUnit * product.stock;
    final suggestedPotentialRevenue = suggestedPrice * product.stock;
    final isBelowTarget = hasCost && marginPercent + 0.001 < safeTargetMargin;

    return ProductPricingAnalysis(
      product: product,
      targetMarginPercent: safeTargetMargin,
      profitPerUnit: profitPerUnit,
      markupPercent: markupPercent,
      marginPercent: marginPercent,
      suggestedPrice: suggestedPrice,
      adjustmentValue: adjustmentValue,
      adjustmentPercent: adjustmentPercent,
      potentialRevenue: potentialRevenue,
      potentialProfit: potentialProfit,
      suggestedPotentialRevenue: suggestedPotentialRevenue,
      isBelowTarget: isBelowTarget,
      hasCost: hasCost,
    );
  }

  static ProductPricingSummary summarize(
    List<ProductRecord> products, {
    required double targetMarginPercent,
  }) {
    final analyses = products
        .map(
          (product) => analyze(
            product,
            targetMarginPercent: targetMarginPercent,
          ),
        )
        .toList();

    final currentPotentialRevenue = analyses.fold<double>(
      0,
      (sum, item) => sum + item.potentialRevenue,
    );
    final currentPotentialProfit = analyses.fold<double>(
      0,
      (sum, item) => sum + item.potentialProfit,
    );
    final suggestedPotentialRevenue = analyses.fold<double>(
      0,
      (sum, item) => sum + item.suggestedPotentialRevenue,
    );
    final productsBelowTarget = analyses.where((item) => item.isBelowTarget).length;
    final double averageMarginPercent = currentPotentialRevenue > 0
        ? (currentPotentialProfit / currentPotentialRevenue) * 100.0
        : 0.0;

    return ProductPricingSummary(
      totalProducts: products.length,
      productsBelowTarget: productsBelowTarget,
      currentPotentialRevenue: currentPotentialRevenue,
      currentPotentialProfit: currentPotentialProfit,
      suggestedPotentialRevenue: suggestedPotentialRevenue,
      averageMarginPercent: averageMarginPercent,
    );
  }
}
