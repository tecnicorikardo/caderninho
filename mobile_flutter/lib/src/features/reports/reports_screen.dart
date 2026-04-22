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
  static const _allBrandsKey = '__all__';
  static const _noBrandKey = '__no_brand__';

  FinancialPeriod _period = FinancialPeriod.month;
  _ProductFilter _productFilter = _ProductFilter.all;
  String _brandKey = _allBrandsKey;

  String _periodLabel(FinancialPeriod period) {
    switch (period) {
      case FinancialPeriod.day:
        return 'Hoje';
      case FinancialPeriod.week:
        return 'Semana';
      case FinancialPeriod.month:
        return 'Mes';
    }
  }

  DateTime _periodStart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case FinancialPeriod.day:
        return today;
      case FinancialPeriod.week:
        return today.subtract(Duration(days: today.weekday - 1));
      case FinancialPeriod.month:
        return DateTime(now.year, now.month, 1);
    }
  }

  String _brandIdentity({String? id, String? name}) {
    final cleanId = (id ?? '').trim();
    if (cleanId.isNotEmpty) return 'id:$cleanId';
    final cleanName = (name ?? '').trim().toLowerCase();
    if (cleanName.isNotEmpty) return 'name:$cleanName';
    return _noBrandKey;
  }

  bool _matchesBrand(String itemKey) {
    return _brandKey == _allBrandsKey || _brandKey == itemKey;
  }

  bool _matchesProduct(ProductRecord product) {
    switch (_productFilter) {
      case _ProductFilter.all:
        return true;
      case _ProductFilter.newProducts:
        return product.situation == ProductSituation.newRelease;
      case _ProductFilter.current:
        return product.situation == ProductSituation.current;
      case _ProductFilter.oldProducts:
        return product.situation.isOldInventory;
      case _ProductFilter.promotions:
        return product.situation == ProductSituation.promotion ||
            product.situation == ProductSituation.clearance;
    }
  }

  ProductRecord? _productForSale(
    SaleRecord sale,
    Map<String, ProductRecord> byId,
    Map<String, ProductRecord> byName,
  ) {
    final productId = sale.productId;
    if (productId != null && productId.isNotEmpty) {
      final product = byId[productId];
      if (product != null) return product;
    }
    final name = (sale.productName ?? '').trim().toLowerCase();
    if (name.isEmpty) return null;
    return byName[name];
  }

  double _saleCommission(SaleRecord sale) {
    final saved = sale.commissionAmount;
    if (saved != null) return saved;
    return sale.total * ((sale.commissionPercent ?? 0) / 100);
  }

  double _saleCost(SaleRecord sale, ProductRecord? product) {
    final quantity = sale.quantity ?? 0;
    if (product == null || quantity <= 0) return 0;
    return product.cost * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatorios')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final productsById = {
            for (final product in store.products) product.id: product,
          };
          final productsByName = {
            for (final product in store.products)
              product.name.trim().toLowerCase(): product,
          };
          final brandChoices = _brandChoices(store);
          if (!brandChoices.any((choice) => choice.key == _brandKey)) {
            _brandKey = _allBrandsKey;
          }

          final products =
              store.products.where((product) {
                final brandKey = _brandIdentity(
                  id: product.brandId,
                  name: product.brandName,
                );
                return _matchesBrand(brandKey) && _matchesProduct(product);
              }).toList()..sort((a, b) {
                final brand = a.brandName.compareTo(b.brandName);
                if (brand != 0) return brand;
                return a.name.compareTo(b.name);
              });

          final start = _periodStart();
          final sales = store.sales.where((sale) {
            if (sale.createdAt.isBefore(start)) return false;
            final product = _productForSale(sale, productsById, productsByName);
            if (_productFilter != _ProductFilter.all) {
              if (product == null || !_matchesProduct(product)) return false;
            }
            final brandKey = _brandIdentity(
              id: sale.brandId,
              name: sale.brandName ?? product?.brandName,
            );
            return _matchesBrand(brandKey);
          }).toList();

          final inventory = _InventorySummary.fromProducts(products);
          final periodSales = _SalesSummary.fromSales(
            sales,
            productForSale: (sale) =>
                _productForSale(sale, productsById, productsByName),
            commissionForSale: _saleCommission,
            costForSale: _saleCost,
          );
          final rowsByBrand = _brandRows(
            products: products,
            sales: sales,
            productForSale: (sale) =>
                _productForSale(sale, productsById, productsByName),
          );
          final productRows = products.map(_ProductRow.fromProduct).toList()
            ..sort((a, b) => b.cost.compareTo(a.cost));
          final selectedBrand = brandChoices
              .firstWhere(
                (choice) => choice.key == _brandKey,
                orElse: () => brandChoices.first,
              )
              .label;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _SectionTitle(
                title: 'Painel simples',
                subtitle:
                    '$selectedBrand - ${_productFilter.label} - ${_periodLabel(_period)}',
              ),
              const SizedBox(height: 12),
              _FiltersCard(
                period: _period,
                periodLabel: _periodLabel,
                onPeriodChanged: (value) => setState(() => _period = value),
                brandKey: _brandKey,
                brandChoices: brandChoices,
                onBrandChanged: (value) {
                  if (value == null) return;
                  setState(() => _brandKey = value);
                },
                productFilter: _productFilter,
                onProductFilterChanged: (value) {
                  setState(() => _productFilter = value);
                },
              ),
              const SizedBox(height: 12),
              const _InfoBox(
                icon: Icons.lightbulb_outline,
                title: 'Leitura rapida',
                text:
                    'Custo mostra quanto esta empatado nos produtos filtrados. Comissao mostra quanto deve ser separado para a marca ou consultora. Exemplo: escolha Natura e Produtos novos para ver somente esse grupo.',
              ),
              const SizedBox(height: 12),
              _MetricGrid(
                title: 'Estoque selecionado',
                subtitle:
                    'Produtos cadastrados agora, respeitando marca e tipo escolhidos.',
                metrics: [
                  _MetricData(
                    label: 'Produtos',
                    value: '${inventory.count}',
                    detail: 'Itens encontrados',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF2563EB),
                  ),
                  _MetricData(
                    label: 'Quantidade',
                    value: inventory.quantity.toStringAsFixed(2),
                    detail: 'Estoque atual',
                    icon: Icons.add_box_outlined,
                    color: const Color(0xFF0891B2),
                  ),
                  _MetricData(
                    label: 'Total de custo',
                    value: AppFormatters.currency(inventory.cost),
                    detail: 'Valor pago no estoque',
                    icon: Icons.shopping_bag_outlined,
                    color: const Color(0xFFB45309),
                  ),
                  _MetricData(
                    label: 'Comissao estimada',
                    value: AppFormatters.currency(inventory.commission),
                    detail: 'Se vender todo o estoque',
                    icon: Icons.percent_outlined,
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MetricGrid(
                title: 'Vendas do periodo',
                subtitle:
                    'Vendas registradas no periodo escolhido e que batem com os filtros.',
                metrics: [
                  _MetricData(
                    label: 'Vendas',
                    value: '${periodSales.count}',
                    detail: 'Registros encontrados',
                    icon: Icons.receipt_long_outlined,
                    color: const Color(0xFF2563EB),
                  ),
                  _MetricData(
                    label: 'Faturamento',
                    value: AppFormatters.currency(periodSales.revenue),
                    detail: 'Valor vendido',
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF15803D),
                  ),
                  _MetricData(
                    label: 'Custo vendido',
                    value: AppFormatters.currency(periodSales.cost),
                    detail: 'Custo estimado',
                    icon: Icons.price_check_outlined,
                    color: const Color(0xFFB45309),
                  ),
                  _MetricData(
                    label: 'Comissao',
                    value: AppFormatters.currency(periodSales.commission),
                    detail: 'Gerada nas vendas',
                    icon: Icons.handshake_outlined,
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ResultCard(summary: periodSales),
              const SizedBox(height: 12),
              _BrandCard(rows: rowsByBrand),
              const SizedBox(height: 12),
              _ProductsCard(rows: productRows),
            ],
          );
        },
      ),
    );
  }

  List<_BrandChoice> _brandChoices(AppStore store) {
    final choices = <String, _BrandChoice>{
      _allBrandsKey: const _BrandChoice(_allBrandsKey, 'Todas'),
    };

    for (final brand in store.brands) {
      choices[_brandIdentity(id: brand.id, name: brand.name)] = _BrandChoice(
        _brandIdentity(id: brand.id, name: brand.name),
        brand.name,
      );
    }

    for (final product in store.products) {
      final key = _brandIdentity(id: product.brandId, name: product.brandName);
      choices.putIfAbsent(
        key,
        () => _BrandChoice(
          key,
          product.brandName.trim().isEmpty ? 'Sem marca' : product.brandName,
        ),
      );
    }

    for (final sale in store.sales) {
      final key = _brandIdentity(id: sale.brandId, name: sale.brandName);
      choices.putIfAbsent(
        key,
        () => _BrandChoice(
          key,
          (sale.brandName ?? '').trim().isEmpty
              ? 'Sem marca'
              : sale.brandName!.trim(),
        ),
      );
    }

    return choices.values.toList()..sort((a, b) {
      if (a.key == _allBrandsKey) return -1;
      if (b.key == _allBrandsKey) return 1;
      if (a.key == _noBrandKey) return 1;
      if (b.key == _noBrandKey) return -1;
      return a.label.compareTo(b.label);
    });
  }

  List<_BrandRow> _brandRows({
    required List<ProductRecord> products,
    required List<SaleRecord> sales,
    required ProductRecord? Function(SaleRecord sale) productForSale,
  }) {
    final rows = <String, _BrandRow>{};

    _BrandRow rowFor(String key, String label) {
      return rows.putIfAbsent(key, () => _BrandRow(key, label));
    }

    for (final product in products) {
      final key = _brandIdentity(id: product.brandId, name: product.brandName);
      final label = product.brandName.trim().isEmpty
          ? 'Sem marca'
          : product.brandName.trim();
      rowFor(key, label).addProduct(product);
    }

    for (final sale in sales) {
      final product = productForSale(sale);
      final key = _brandIdentity(
        id: sale.brandId,
        name: sale.brandName ?? product?.brandName,
      );
      final label = (sale.brandName ?? product?.brandName ?? '').trim();
      rowFor(key, label.isEmpty ? 'Sem marca' : label).addSale(
        sale,
        commission: _saleCommission(sale),
        cost: _saleCost(sale, product),
      );
    }

    return rows.values.toList()..sort((a, b) {
      final revenue = b.revenue.compareTo(a.revenue);
      if (revenue != 0) return revenue;
      return b.inventoryCost.compareTo(a.inventoryCost);
    });
  }
}

enum _ProductFilter { all, newProducts, current, oldProducts, promotions }

extension on _ProductFilter {
  String get label {
    switch (this) {
      case _ProductFilter.all:
        return 'Todos os produtos';
      case _ProductFilter.newProducts:
        return 'Produtos novos';
      case _ProductFilter.current:
        return 'Produtos atuais';
      case _ProductFilter.oldProducts:
        return 'Produtos antigos';
      case _ProductFilter.promotions:
        return 'Promocoes';
    }
  }

  IconData get icon {
    switch (this) {
      case _ProductFilter.all:
        return Icons.apps_outlined;
      case _ProductFilter.newProducts:
        return Icons.fiber_new_outlined;
      case _ProductFilter.current:
        return Icons.check_circle_outline;
      case _ProductFilter.oldProducts:
        return Icons.history_outlined;
      case _ProductFilter.promotions:
        return Icons.local_offer_outlined;
    }
  }
}

class _BrandChoice {
  const _BrandChoice(this.key, this.label);

  final String key;
  final String label;
}

class _InventorySummary {
  const _InventorySummary({
    required this.count,
    required this.quantity,
    required this.cost,
    required this.commission,
  });

  factory _InventorySummary.fromProducts(List<ProductRecord> products) {
    var quantity = 0.0;
    var cost = 0.0;
    var commission = 0.0;
    for (final product in products) {
      final stock = product.stock <= 0 ? 0.0 : product.stock;
      final saleValue = product.effectiveSalePrice * stock;
      quantity += stock;
      cost += product.cost * stock;
      commission += saleValue * (product.commissionPercent / 100);
    }
    return _InventorySummary(
      count: products.length,
      quantity: quantity,
      cost: cost,
      commission: commission,
    );
  }

  final int count;
  final double quantity;
  final double cost;
  final double commission;
}

class _SalesSummary {
  const _SalesSummary({
    required this.count,
    required this.revenue,
    required this.cost,
    required this.commission,
  });

  factory _SalesSummary.fromSales(
    List<SaleRecord> sales, {
    required ProductRecord? Function(SaleRecord sale) productForSale,
    required double Function(SaleRecord sale) commissionForSale,
    required double Function(SaleRecord sale, ProductRecord? product)
    costForSale,
  }) {
    var revenue = 0.0;
    var cost = 0.0;
    var commission = 0.0;
    for (final sale in sales) {
      final product = productForSale(sale);
      revenue += sale.total;
      cost += costForSale(sale, product);
      commission += commissionForSale(sale);
    }
    return _SalesSummary(
      count: sales.length,
      revenue: revenue,
      cost: cost,
      commission: commission,
    );
  }

  final int count;
  final double revenue;
  final double cost;
  final double commission;

  double get result => revenue - cost - commission;

  double get averageTicket => count == 0 ? 0 : revenue / count;

  double get margin => revenue <= 0 ? 0 : (result / revenue) * 100;
}

class _BrandRow {
  _BrandRow(this.key, this.label);

  final String key;
  final String label;
  int products = 0;
  double inventoryCost = 0;
  double inventoryCommission = 0;
  double revenue = 0;
  double salesCost = 0;
  double salesCommission = 0;

  void addProduct(ProductRecord product) {
    final stock = product.stock <= 0 ? 0.0 : product.stock;
    final saleValue = product.effectiveSalePrice * stock;
    products++;
    inventoryCost += product.cost * stock;
    inventoryCommission += saleValue * (product.commissionPercent / 100);
  }

  void addSale(
    SaleRecord sale, {
    required double commission,
    required double cost,
  }) {
    revenue += sale.total;
    salesCost += cost;
    salesCommission += commission;
  }
}

class _ProductRow {
  const _ProductRow({
    required this.name,
    required this.brand,
    required this.situation,
    required this.stock,
    required this.unit,
    required this.cost,
    required this.commission,
    required this.salePotential,
  });

  factory _ProductRow.fromProduct(ProductRecord product) {
    final stock = product.stock <= 0 ? 0.0 : product.stock;
    final salePotential = product.effectiveSalePrice * stock;
    return _ProductRow(
      name: product.name,
      brand: product.brandName.trim().isEmpty
          ? 'Sem marca'
          : product.brandName.trim(),
      situation: product.situation.label,
      stock: stock,
      unit: product.unit,
      cost: product.cost * stock,
      commission: salePotential * (product.commissionPercent / 100),
      salePotential: salePotential,
    );
  }

  final String name;
  final String brand;
  final String situation;
  final double stock;
  final String unit;
  final double cost;
  final double commission;
  final double salePotential;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.period,
    required this.periodLabel,
    required this.onPeriodChanged,
    required this.brandKey,
    required this.brandChoices,
    required this.onBrandChanged,
    required this.productFilter,
    required this.onProductFilterChanged,
  });

  final FinancialPeriod period;
  final String Function(FinancialPeriod period) periodLabel;
  final ValueChanged<FinancialPeriod> onPeriodChanged;
  final String brandKey;
  final List<_BrandChoice> brandChoices;
  final ValueChanged<String?> onBrandChanged;
  final _ProductFilter productFilter;
  final ValueChanged<_ProductFilter> onProductFilterChanged;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardHeader(
              icon: Icons.tune_outlined,
              title: 'Filtros',
              subtitle: 'Escolha marca, periodo e grupo de produtos.',
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: brandKey,
              decoration: const InputDecoration(
                labelText: 'Marca',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              items: brandChoices
                  .map(
                    (choice) => DropdownMenuItem<String>(
                      value: choice.key,
                      child: Text(choice.label),
                    ),
                  )
                  .toList(),
              onChanged: onBrandChanged,
            ),
            const SizedBox(height: 12),
            SegmentedButton<FinancialPeriod>(
              segments: FinancialPeriod.values
                  .map(
                    (item) => ButtonSegment<FinancialPeriod>(
                      value: item,
                      label: Text(periodLabel(item)),
                    ),
                  )
                  .toList(),
              selected: {period},
              onSelectionChanged: (value) => onPeriodChanged(value.first),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ProductFilter.values.map((filter) {
                return FilterChip(
                  selected: filter == productFilter,
                  avatar: Icon(filter.icon, size: 18),
                  label: Text(filter.label),
                  onSelected: (_) => onProductFilterChanged(filter),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(text, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.title,
    required this.subtitle,
    required this.metrics,
  });

  final String title;
  final String subtitle;
  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              icon: Icons.analytics_outlined,
              title: title,
              subtitle: subtitle,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 680;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  childAspectRatio: isWide ? 1.32 : 1.08,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: metrics.map(_MetricTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.metric);

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: metric.color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: metric.color),
          const Spacer(),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: metric.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.summary});

  final _SalesSummary summary;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardHeader(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Resultado explicado',
              subtitle:
                  'Uma conta direta do que entrou, do que custou e da comissao.',
            ),
            const SizedBox(height: 12),
            _AmountLine(
              label: 'Entrou em vendas',
              value: summary.revenue,
              color: const Color(0xFF15803D),
            ),
            _AmountLine(
              label: 'Menos custo dos produtos vendidos',
              value: -summary.cost,
              color: const Color(0xFFB45309),
            ),
            _AmountLine(
              label: 'Menos comissao',
              value: -summary.commission,
              color: const Color(0xFF7C3AED),
            ),
            const Divider(height: 24),
            _AmountLine(
              label: 'Sobra antes das outras despesas',
              value: summary.result,
              color: summary.result >= 0
                  ? const Color(0xFF15803D)
                  : const Color(0xFFB91C1C),
              emphasized: true,
            ),
            const SizedBox(height: 8),
            Text(
              summary.count == 0
                  ? 'Nao houve venda para estes filtros no periodo.'
                  : 'Ticket medio: ${AppFormatters.currency(summary.averageTicket)}. Margem simples: ${summary.margin.toStringAsFixed(1)}%.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.rows});

  final List<_BrandRow> rows;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.take(8).toList();
    return GradientCard(
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardHeader(
              icon: Icons.storefront_outlined,
              title: 'Por marca',
              subtitle:
                  'Compara estoque, faturamento e comissao por marca filtrada.',
            ),
            const SizedBox(height: 12),
            if (visibleRows.isEmpty)
              const _EmptyMessage(text: 'Nenhuma marca encontrada.')
            else
              ...visibleRows.map((row) => _BrandTile(row: row)),
          ],
        ),
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.row});

  final _BrandRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${row.products} produtos',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStat(
                label: 'Custo estoque',
                value: AppFormatters.currency(row.inventoryCost),
              ),
              _MiniStat(
                label: 'Comissao estoque',
                value: AppFormatters.currency(row.inventoryCommission),
              ),
              _MiniStat(
                label: 'Vendido',
                value: AppFormatters.currency(row.revenue),
              ),
              _MiniStat(
                label: 'Comissao venda',
                value: AppFormatters.currency(row.salesCommission),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductsCard extends StatelessWidget {
  const _ProductsCard({required this.rows});

  final List<_ProductRow> rows;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.take(20).toList();
    final hidden = rows.length - visibleRows.length;
    return GradientCard(
      radius: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardHeader(
              icon: Icons.list_alt_outlined,
              title: 'Produtos do filtro',
              subtitle:
                  'Itens que formam o custo e a comissao estimada do estoque.',
            ),
            const SizedBox(height: 12),
            if (visibleRows.isEmpty)
              const _EmptyMessage(text: 'Nenhum produto encontrado.')
            else
              ...visibleRows.map((row) => _ProductTile(row: row)),
            if (hidden > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Mais $hidden produtos ficaram ocultos nesta lista.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.row});

  final _ProductRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.name, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            '${row.brand} - ${row.situation} - ${row.stock.toStringAsFixed(2)} ${row.unit}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStat(
                label: 'Custo',
                value: AppFormatters.currency(row.cost),
              ),
              _MiniStat(
                label: 'Comissao',
                value: AppFormatters.currency(row.commission),
              ),
              _MiniStat(
                label: 'Pode vender',
                value: AppFormatters.currency(row.salePotential),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.label,
    required this.value,
    required this.color,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              AppFormatters.currency(value),
              textAlign: TextAlign.right,
              style: style?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
