class PlanModel {
  const PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.months,
    required this.description,
    this.isPopular = false,
    this.savings,
  });

  final String id;
  final String name;
  final double price;
  final int months;
  final String description;
  final bool isPopular;
  final String? savings;

  static const monthly = PlanModel(
    id: 'monthly',
    name: 'Mensal',
    price: 29.90,
    months: 1,
    description: 'Acesso completo por 1 mês',
  );

  static const quarterly = PlanModel(
    id: 'quarterly',
    name: 'Trimestral',
    price: 49.90,
    months: 3,
    description: 'Acesso completo por 3 meses',
    isPopular: true,
    savings: 'Economize ~44%',
  );

  static const annual = PlanModel(
    id: 'annual',
    name: 'Anual',
    price: 299.90,
    months: 12,
    description: 'Acesso completo por 12 meses',
    savings: 'Economize ~16%',
  );

  static const allPlans = [monthly, quarterly, annual];

  double get pricePerMonth => price / months;
}
