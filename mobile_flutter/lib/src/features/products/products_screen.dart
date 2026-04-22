import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';
import '../../core/subscription_middleware.dart';
import '../../core/utils/search_utils.dart';
import '../shared/gradient_card.dart';
import '../subscription/services/export_service.dart';
import 'widgets/recipe_pricing_hub_modal.dart';
import 'widgets/product_pricing_modal.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _subscriptionMiddleware = SubscriptionMiddleware();
  String _search = '';
  ProductSituation? _situationFilter;
  final TextEditingController _searchController = TextEditingController();
  final _exportService = ExportService();
  bool _isImporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _errorText(Object error) {
    if (error is FirebaseException) {
      return error.message ?? 'Falha ao salvar no Firebase.';
    }
    if (error is StateError) return error.message;
    return error.toString();
  }

  double _parseDecimal(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  BrandRecord? _brandById(AppStore store, String? brandId) {
    final id = (brandId ?? '').trim();
    if (id.isEmpty) return null;
    for (final brand in store.brands) {
      if (brand.id == id) return brand;
    }
    return null;
  }

  BrandRecord? _brandByName(AppStore store, String rawName) {
    final target = normalizeLookupKey(rawName);
    if (target.isEmpty) return null;
    for (final brand in store.brands) {
      if (normalizeLookupKey(brand.name) == target) return brand;
    }
    return null;
  }

  Future<void> _importProducts(AppStore store) async {
    if (_isImporting) return;

    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'addProduct',
    );
    if (!canAccess) return;

    setState(() => _isImporting = true);
    try {
      final importedRows = await _exportService.importProductsFromSpreadsheet();
      if (importedRows.isEmpty) {
        _showMessage('Importacao cancelada ou sem linhas validas.');
        return;
      }

      final existingByName = <String, ProductRecord>{
        for (final product in store.products)
          normalizeLookupKey(product.name): product,
      };
      final processed = <String>{};
      var created = 0;
      var updated = 0;

      for (final row in importedRows) {
        final key = normalizeLookupKey(row.name);
        if (key.isEmpty || processed.contains(key)) {
          continue;
        }
        processed.add(key);

        final linkedBrand = _brandByName(store, row.brandName);
        final brandId = linkedBrand?.id ?? '';
        final brandName = linkedBrand?.name ?? row.brandName;
        final commissionPercent = row.commissionPercent > 0
            ? row.commissionPercent
            : (linkedBrand?.defaultCommissionPercent ?? 0);
        final hasCustomCommission =
            row.commissionPercent > 0 &&
            (linkedBrand == null ||
                row.commissionPercent != linkedBrand.defaultCommissionPercent);
        final existing = existingByName[key];
        if (existing == null) {
          await store.addProduct(
            name: row.name,
            sku: row.sku,
            barcode: row.barcode,
            category: row.category,
            brandId: brandId,
            brandName: brandName,
            description: row.description,
            sizeLabel: row.sizeLabel,
            variation: row.variation,
            salePrice: row.salePrice,
            cost: row.cost,
            commissionPercent: commissionPercent,
            hasCustomCommission: hasCustomCommission,
            situation: row.situation,
            automaticDiscountPercent: row.automaticDiscountPercent,
            stock: row.stock,
            stockMinimum: row.stockMinimum,
            expiryDate: row.expiryDate,
            batchCode: row.batchCode,
            storageLocation: row.storageLocation,
            unit: row.unit,
            showInWeb: row.showInWeb,
            notes: row.notes,
            registerStockExpense: false,
          );
          created++;
          continue;
        }

        await store.updateProduct(
          productId: existing.id,
          name: row.name,
          sku: row.sku.isEmpty ? existing.sku : row.sku,
          barcode: row.barcode.isEmpty ? existing.barcode : row.barcode,
          category: row.category,
          brandId: brandId.isEmpty ? existing.brandId : brandId,
          brandName: brandName.isEmpty ? existing.brandName : brandName,
          description: row.description.isEmpty
              ? existing.description
              : row.description,
          sizeLabel: row.sizeLabel.isEmpty ? existing.sizeLabel : row.sizeLabel,
          variation: row.variation.isEmpty ? existing.variation : row.variation,
          salePrice: row.salePrice,
          cost: row.cost,
          commissionPercent: row.commissionPercent > 0 || linkedBrand != null
              ? commissionPercent
              : existing.commissionPercent,
          hasCustomCommission: row.commissionPercent > 0
              ? hasCustomCommission
              : existing.hasCustomCommission,
          situation: row.hasSituation ? row.situation : existing.situation,
          automaticDiscountPercent: row.automaticDiscountPercent > 0
              ? row.automaticDiscountPercent
              : existing.automaticDiscountPercent,
          stock: row.stock,
          stockMinimum: row.stockMinimum > 0
              ? row.stockMinimum
              : existing.stockMinimum,
          expiryDate: row.expiryDate ?? existing.expiryDate,
          batchCode: row.batchCode.isEmpty ? existing.batchCode : row.batchCode,
          storageLocation: row.storageLocation.isEmpty
              ? existing.storageLocation
              : row.storageLocation,
          unit: row.unit,
          showInWeb: existing.showInWeb,
          imageUrl: existing.imageUrl,
          thumbnailUrl: existing.thumbnailUrl,
          notes: row.notes.isEmpty ? existing.notes : row.notes,
          stockChangeReason: 'Importacao de planilha',
          registerStockMovement: false,
          registerStockFinancialEntry: false,
        );
        updated++;
      }

      _showMessage(
        'Importacao de produtos concluida: $created novos, $updated atualizados.',
      );
    } catch (error, stackTrace) {
      debugPrint('[Products][Import] Falha: $error');
      debugPrint('$stackTrace');
      _showMessage('Erro ao importar produtos: $error');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  List<ProductRecord> _smartFilter(List<ProductRecord> source) {
    final tokens = queryTokens(_search);
    if (tokens.isEmpty) return source;

    final starts = <ProductRecord>[];
    final contains = <ProductRecord>[];
    final metadata = <ProductRecord>[];

    for (final product in source) {
      final normalizedName = normalizeForSearch(product.name);
      final normalizedCategory = normalizeForSearch(product.category);
      final normalizedBrand = normalizeForSearch(product.brandName);
      final normalizedSku = normalizeForSearch(product.sku);
      final normalizedBarcode = normalizeForSearch(product.barcode);
      final normalizedDescription = normalizeForSearch(product.description);

      final matchesName = tokens.every(normalizedName.contains);
      final matchesMetadata =
          tokens.every(normalizedCategory.contains) ||
          tokens.every(normalizedBrand.contains) ||
          tokens.every(normalizedSku.contains) ||
          tokens.every(normalizedBarcode.contains) ||
          tokens.every(normalizedDescription.contains);
      if (!matchesName && !matchesMetadata) continue;

      if (normalizedName.startsWith(tokens.first)) {
        starts.add(product);
      } else if (matchesName) {
        contains.add(product);
      } else {
        metadata.add(product);
      }
    }

    return [...starts, ...contains, ...metadata];
  }

  bool _matchesSituationFilter(ProductRecord product) {
    final filter = _situationFilter;
    if (filter == null) return true;
    switch (filter) {
      case ProductSituation.newRelease:
        return product.situation == ProductSituation.newRelease;
      case ProductSituation.old:
        return product.situation == ProductSituation.old ||
            product.situation == ProductSituation.discontinued;
      case ProductSituation.promotion:
        return product.situation == ProductSituation.promotion ||
            product.situation == ProductSituation.clearance;
      case ProductSituation.current:
      case ProductSituation.clearance:
      case ProductSituation.discontinued:
        return product.situation == filter;
    }
  }

  Color _situationColor(ProductSituation situation) {
    switch (situation) {
      case ProductSituation.newRelease:
        return const Color(0xFF2563EB);
      case ProductSituation.current:
        return const Color(0xFF15803D);
      case ProductSituation.old:
        return const Color(0xFFD97706);
      case ProductSituation.promotion:
        return const Color(0xFF7C3AED);
      case ProductSituation.clearance:
        return const Color(0xFFDC2626);
      case ProductSituation.discontinued:
        return const Color(0xFF475569);
    }
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF0F172A),
            fontFamily: 'Roboto',
          ),
          children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            TextSpan(text: label),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color color = const Color(0xFF475569),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductStatusChips(ProductRecord product) {
    final chips = <Widget>[];
    chips.add(
      _buildStatusChip(
        icon: Icons.sell_outlined,
        label: product.situation.label,
        color: _situationColor(product.situation),
      ),
    );
    if (product.brandName.isNotEmpty) {
      chips.add(
        _buildStatusChip(
          icon: Icons.local_offer_outlined,
          label: product.brandName,
          color: const Color(0xFF2563EB),
        ),
      );
    }
    if (product.isExpired) {
      chips.add(
        _buildStatusChip(
          icon: Icons.warning_amber_rounded,
          label: 'Vencido',
          color: const Color(0xFFB91C1C),
        ),
      );
    } else if (product.isExpiringWithin(30)) {
      chips.add(
        _buildStatusChip(
          icon: Icons.event_busy_outlined,
          label: 'Validade proxima',
          color: const Color(0xFFD97706),
        ),
      );
    }
    if (product.isLowStock) {
      chips.add(
        _buildStatusChip(
          icon: Icons.inventory_2_outlined,
          label: 'Estoque baixo',
          color: const Color(0xFFDC2626),
        ),
      );
    }
    if (product.hasCustomCommission) {
      chips.add(
        _buildStatusChip(
          icon: Icons.percent_outlined,
          label: 'Comissao personalizada',
          color: const Color(0xFF7C3AED),
        ),
      );
    }
    if (product.hasAutomaticDiscount) {
      chips.add(
        _buildStatusChip(
          icon: Icons.discount_outlined,
          label:
              'Desconto ${product.automaticDiscountPercent.toStringAsFixed(1)}%',
          color: const Color(0xFFB45309),
        ),
      );
    }
    if (product.showInWeb) {
      chips.add(
        _buildStatusChip(
          icon: Icons.public_outlined,
          label: 'Visivel no web',
          color: const Color(0xFF0F766E),
        ),
      );
    }
    return chips;
  }

  Future<void> _upsertBrand({
    required AppStore store,
    BrandRecord? brand,
  }) async {
    final isEditing = brand != null;
    final nameController = TextEditingController(text: brand?.name ?? '');
    final logoController = TextEditingController(text: brand?.logoUrl ?? '');
    final commissionController = TextEditingController(
      text: brand == null
          ? ''
          : brand.defaultCommissionPercent.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();
    var isActive = brand?.isActive ?? true;
    var syncProducts = isEditing;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEditing ? 'Editar marca' : 'Nova marca'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da marca / empresa',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome da marca';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: commissionController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Comissao padrao (%)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: logoController,
                      decoration: const InputDecoration(
                        labelText: 'Logo URL (opcional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Marca ativa'),
                      value: isActive,
                      onChanged: (value) {
                        setStateDialog(() {
                          isActive = value;
                        });
                      },
                    ),
                    if (isEditing)
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Atualizar produtos vinculados'),
                        subtitle: const Text(
                          'Sincroniza nome e comissao padrao nos produtos sem comissao personalizada.',
                        ),
                        value: syncProducts,
                        onChanged: (value) {
                          setStateDialog(() {
                            syncProducts = value;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.of(context).pop(true);
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    if (shouldSave != true) return;

    try {
      final editingBrand = brand;
      if (editingBrand != null) {
        await store.updateBrand(
          brandId: editingBrand.id,
          name: nameController.text.trim(),
          logoUrl: logoController.text.trim(),
          defaultCommissionPercent: _parseDecimal(commissionController.text),
          isActive: isActive,
          syncProducts: syncProducts,
        );
      } else {
        await store.addBrand(
          name: nameController.text.trim(),
          logoUrl: logoController.text.trim(),
          defaultCommissionPercent: _parseDecimal(commissionController.text),
          isActive: isActive,
        );
      }
      if (!mounted) return;
      _showMessage(
        isEditing
            ? 'Marca atualizada com sucesso.'
            : 'Marca criada com sucesso.',
      );
    } catch (error) {
      _showMessage(_errorText(error));
    }
  }

  Future<void> _showBrandManager(AppStore store) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) {
                final brands = store.brands.toList()
                  ..sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Marcas e comissoes',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Cadastre empresas, ajuste comissao padrao e mantenha o catalogo organizado.',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _upsertBrand(store: store),
                          icon: const Icon(Icons.add_business_outlined),
                          label: const Text('Nova marca'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (brands.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Nenhuma marca cadastrada ainda.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: brands.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final brand = brands[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: brand.isActive
                                        ? const Color(0xFFDBEAFE)
                                        : const Color(0xFFE5E7EB),
                                    foregroundColor: brand.isActive
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFF475569),
                                    child: Text(
                                      brand.name.isEmpty
                                          ? '?'
                                          : brand.name
                                                .substring(0, 1)
                                                .toUpperCase(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          brand.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _buildMetricPill(
                                              label: 'comissao padrao',
                                              value:
                                                  '${brand.defaultCommissionPercent.toStringAsFixed(1)}%',
                                              color: const Color(0xFF2563EB),
                                            ),
                                            _buildMetricPill(
                                              label: brand.isActive
                                                  ? 'ativa'
                                                  : 'inativa',
                                              value: 'Status',
                                              color: brand.isActive
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Editar marca',
                                    onPressed: () => _upsertBrand(
                                      store: store,
                                      brand: brand,
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fechar'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addProduct(AppStore store) async {
    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'addProduct',
    );
    if (!canAccess) return;

    await _upsertProduct(store: store);
  }

  Future<void> _editProduct(AppStore store, ProductRecord product) async {
    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'updateProduct',
    );
    if (!canAccess) return;

    await _upsertProduct(store: store, product: product);
  }

  Future<void> _upsertProduct({
    required AppStore store,
    ProductRecord? product,
  }) async {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final skuController = TextEditingController(text: product?.sku ?? '');
    final barcodeController = TextEditingController(
      text: product?.barcode ?? '',
    );
    final categoryController = TextEditingController(
      text: product?.category.isNotEmpty == true ? product!.category : 'Geral',
    );
    final descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    final sizeController = TextEditingController(
      text: product?.sizeLabel ?? '',
    );
    final variationController = TextEditingController(
      text: product?.variation ?? '',
    );
    final salePriceController = TextEditingController(
      text: product == null ? '' : product.salePrice.toStringAsFixed(2),
    );
    final costController = TextEditingController(
      text: product == null ? '' : product.cost.toStringAsFixed(2),
    );
    final commissionController = TextEditingController(
      text: product == null ? '' : product.commissionPercent.toStringAsFixed(2),
    );
    final discountController = TextEditingController(
      text: product == null
          ? ''
          : product.automaticDiscountPercent.toStringAsFixed(2),
    );
    final stockController = TextEditingController(
      text: product == null ? '' : product.stock.toStringAsFixed(2),
    );
    final stockMinimumController = TextEditingController(
      text: product == null ? '' : product.stockMinimum.toStringAsFixed(2),
    );
    final unitController = TextEditingController(text: product?.unit ?? 'un');
    final batchController = TextEditingController(
      text: product?.batchCode ?? '',
    );
    final locationController = TextEditingController(
      text: product?.storageLocation ?? '',
    );
    final imageController = TextEditingController(
      text: product?.imageUrl ?? '',
    );
    final thumbnailController = TextEditingController(
      text: product?.thumbnailUrl ?? '',
    );
    final notesController = TextEditingController(text: product?.notes ?? '');
    final expiryController = TextEditingController(
      text: product?.expiryDate == null
          ? ''
          : AppFormatters.date(product!.expiryDate!),
    );
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var showInWeb = product?.showInWeb ?? false;
    var hasCustomCommission = product?.hasCustomCommission ?? false;
    var situation = product?.situation ?? ProductSituation.current;
    var selectedBrandId = product?.brandId.trim().isEmpty ?? true
        ? null
        : product!.brandId;
    DateTime? expiryDate = product?.expiryDate;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final availableBrands = store.brands
              .where(
                (brand) =>
                    brand.isActive ||
                    (selectedBrandId != null && brand.id == selectedBrandId),
              )
              .toList();
          final selectedBrand = _brandById(store, selectedBrandId);
          if (!hasCustomCommission && selectedBrand != null) {
            commissionController.text = selectedBrand.defaultCommissionPercent
                .toStringAsFixed(2);
          }

          final salePrice = _parseDecimal(salePriceController.text);
          final discountPercent = _parseDecimal(discountController.text);
          final normalizedDiscountPercent = discountPercent
              .clamp(0, 90)
              .toDouble();
          final automaticDiscountAmount = situation.canUseAutomaticDiscount
              ? salePrice * (normalizedDiscountPercent / 100)
              : 0.0;
          final effectiveSalePrice = salePrice - automaticDiscountAmount;
          final estimatedProfit =
              effectiveSalePrice -
              _parseDecimal(costController.text) -
              (effectiveSalePrice *
                  (_parseDecimal(commissionController.text) / 100));

          return AlertDialog(
            title: Text(isEditing ? 'Editar produto' : 'Novo produto'),
            content: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do produto',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o nome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: skuController,
                              decoration: const InputDecoration(
                                labelText: 'Codigo / SKU',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: barcodeController,
                              decoration: const InputDecoration(
                                labelText: 'Codigo de barras',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: categoryController,
                              decoration: const InputDecoration(
                                labelText: 'Categoria',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: selectedBrandId,
                              decoration: const InputDecoration(
                                labelText: 'Marca / Empresa',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Sem marca'),
                                ),
                                ...availableBrands.map(
                                  (brand) => DropdownMenuItem<String?>(
                                    value: brand.id,
                                    child: Text(brand.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setStateDialog(() {
                                  selectedBrandId = value;
                                  final brand = _brandById(store, value);
                                  if (!hasCustomCommission) {
                                    commissionController.text = brand == null
                                        ? '0'
                                        : brand.defaultCommissionPercent
                                              .toStringAsFixed(2);
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ProductSituation>(
                        value: situation,
                        decoration: const InputDecoration(
                          labelText: 'Situacao',
                        ),
                        items: ProductSituation.values
                            .map(
                              (item) => DropdownMenuItem<ProductSituation>(
                                value: item,
                                child: Text(item.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setStateDialog(() {
                            situation = value;
                            if (!situation.canUseAutomaticDiscount) {
                              discountController.text = '0';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descricao completa',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: sizeController,
                              decoration: const InputDecoration(
                                labelText: 'Tamanho / ML / Volume',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: variationController,
                              decoration: const InputDecoration(
                                labelText: 'Cor / Variacao',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: costController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Preco de custo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: salePriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Preco de venda',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Comissao personalizada para este produto',
                        ),
                        subtitle: Text(
                          selectedBrand == null
                              ? 'Sem marca selecionada.'
                              : 'Marca: ${selectedBrand.name} (${selectedBrand.defaultCommissionPercent.toStringAsFixed(1)}%)',
                        ),
                        value: hasCustomCommission,
                        onChanged: (value) {
                          setStateDialog(() {
                            hasCustomCommission = value;
                            if (!value) {
                              commissionController.text = selectedBrand == null
                                  ? '0'
                                  : selectedBrand.defaultCommissionPercent
                                        .toStringAsFixed(2);
                            }
                          });
                        },
                      ),
                      TextFormField(
                        controller: commissionController,
                        readOnly: !hasCustomCommission && selectedBrand != null,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Comissao aplicada (%)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: discountController,
                        enabled: situation.canUseAutomaticDiscount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Desconto automatico (%)',
                          helperText: situation.canUseAutomaticDiscount
                              ? 'Aplicado automaticamente na venda.'
                              : 'Disponivel para Antigo, Promocao, Queima e Fora de linha.',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'Preco efetivo: ${AppFormatters.currency(effectiveSalePrice)} | Lucro estimado: ${AppFormatters.currency(estimatedProfit)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: estimatedProfit >= 0
                                ? const Color(0xFF166534)
                                : const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: stockController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Estoque',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: stockMinimumController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Estoque minimo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: unitController,
                              decoration: const InputDecoration(
                                labelText: 'Unidade',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: batchController,
                              decoration: const InputDecoration(
                                labelText: 'Lote',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: locationController,
                              decoration: const InputDecoration(
                                labelText: 'Localizacao no estoque',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: expiryController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Data de validade',
                          suffixIcon: Wrap(
                            spacing: 2,
                            children: [
                              if (expiryDate != null)
                                IconButton(
                                  tooltip: 'Limpar validade',
                                  onPressed: () {
                                    setStateDialog(() {
                                      expiryDate = null;
                                      expiryController.clear();
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                              IconButton(
                                tooltip: 'Selecionar validade',
                                onPressed: () async {
                                  final selected = await showDatePicker(
                                    context: context,
                                    initialDate: expiryDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (selected == null) return;
                                  setStateDialog(() {
                                    expiryDate = selected;
                                    expiryController.text = AppFormatters.date(
                                      selected,
                                    );
                                  });
                                },
                                icon: const Icon(Icons.calendar_today_outlined),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: reasonController,
                          decoration: const InputDecoration(
                            labelText:
                                'Motivo da alteracao de estoque (se mudar)',
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: imageController,
                        decoration: const InputDecoration(
                          labelText: 'URL da imagem',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: thumbnailController,
                        decoration: const InputDecoration(
                          labelText: 'URL da thumbnail (recomendado)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: notesController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observacoes',
                        ),
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Exibir na Vitrine Online'),
                        value: showInWeb,
                        onChanged: (value) {
                          setStateDialog(() {
                            showInWeb = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.of(context).pop(true);
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    if (shouldSave != true) return;

    final selectedBrand = _brandById(store, selectedBrandId);
    final resolvedUnit = unitController.text.trim().isEmpty
        ? 'un'
        : unitController.text.trim();
    final resolvedCommission = _parseDecimal(commissionController.text);

    if (isEditing) {
      try {
        await store.updateProduct(
          productId: product.id,
          name: nameController.text.trim(),
          sku: skuController.text.trim(),
          barcode: barcodeController.text.trim(),
          category: categoryController.text.trim().isEmpty
              ? 'Geral'
              : categoryController.text.trim(),
          brandId: selectedBrand?.id ?? '',
          brandName: selectedBrand?.name ?? '',
          description: descriptionController.text.trim(),
          sizeLabel: sizeController.text.trim(),
          variation: variationController.text.trim(),
          salePrice: _parseDecimal(salePriceController.text),
          cost: _parseDecimal(costController.text),
          commissionPercent: resolvedCommission,
          hasCustomCommission: hasCustomCommission,
          situation: situation,
          automaticDiscountPercent: _parseDecimal(discountController.text),
          stock: _parseDecimal(stockController.text),
          stockMinimum: _parseDecimal(stockMinimumController.text),
          expiryDate: expiryDate,
          batchCode: batchController.text.trim(),
          storageLocation: locationController.text.trim(),
          unit: resolvedUnit,
          showInWeb: showInWeb,
          imageUrl: imageController.text.trim(),
          thumbnailUrl: thumbnailController.text.trim(),
          notes: notesController.text.trim(),
          stockChangeReason: reasonController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Produto atualizado.')));
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
      return;
    }

    try {
      await store.addProduct(
        name: nameController.text.trim(),
        sku: skuController.text.trim(),
        barcode: barcodeController.text.trim(),
        category: categoryController.text.trim().isEmpty
            ? 'Geral'
            : categoryController.text.trim(),
        brandId: selectedBrand?.id ?? '',
        brandName: selectedBrand?.name ?? '',
        description: descriptionController.text.trim(),
        sizeLabel: sizeController.text.trim(),
        variation: variationController.text.trim(),
        salePrice: _parseDecimal(salePriceController.text),
        cost: _parseDecimal(costController.text),
        commissionPercent: resolvedCommission,
        hasCustomCommission: hasCustomCommission,
        situation: situation,
        automaticDiscountPercent: _parseDecimal(discountController.text),
        stock: _parseDecimal(stockController.text),
        stockMinimum: _parseDecimal(stockMinimumController.text),
        expiryDate: expiryDate,
        batchCode: batchController.text.trim(),
        storageLocation: locationController.text.trim(),
        unit: resolvedUnit,
        showInWeb: showInWeb,
        imageUrl: imageController.text.trim(),
        thumbnailUrl: thumbnailController.text.trim(),
        notes: notesController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produto salvo.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  Future<void> _deleteProduct(AppStore store, ProductRecord product) async {
    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'removeProduct',
    );
    if (!canAccess) return;
    if (!mounted) return;

    final reasonController = TextEditingController(text: 'Exclusao do produto');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ao excluir, o estoque restante sera baixado automaticamente e registrado com motivo.',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Motivo da baixa'),
            ),
          ],
        ),
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

    if (confirm != true) return;

    try {
      await store.deleteProduct(
        product: product,
        reason: reasonController.text.trim().isEmpty
            ? 'Exclusao do produto'
            : reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produto excluido.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  Future<void> _stockMovement(AppStore store, ProductRecord product) async {
    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'updateProduct',
    );
    if (!canAccess) return;
    if (!mounted) return;

    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String type = 'in';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Movimentar estoque: ${product.name}'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                        value: 'in',
                        child: Text('Entrada (adicionar)'),
                      ),
                      DropdownMenuItem(
                        value: 'out',
                        child: Text('Baixa (remover)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() {
                        type = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                    validator: (value) {
                      final parsed = _parseDecimal(value ?? '');
                      if (parsed <= 0) return 'Informe uma quantidade valida';
                      if (type == 'out' && parsed > product.stock) {
                        return 'Baixa maior que o estoque atual';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(labelText: 'Motivo'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o motivo';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(context).pop(true);
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    final quantity = _parseDecimal(amountController.text);
    final signed = type == 'out' ? -quantity : quantity;
    try {
      await store.updateProduct(
        productId: product.id,
        name: product.name,
        sku: product.sku,
        barcode: product.barcode,
        category: product.category,
        brandId: product.brandId,
        brandName: product.brandName,
        description: product.description,
        sizeLabel: product.sizeLabel,
        variation: product.variation,
        salePrice: product.salePrice,
        cost: product.cost,
        commissionPercent: product.commissionPercent,
        hasCustomCommission: product.hasCustomCommission,
        situation: product.situation,
        automaticDiscountPercent: product.automaticDiscountPercent,
        stock: product.stock + signed,
        stockMinimum: product.stockMinimum,
        expiryDate: product.expiryDate,
        batchCode: product.batchCode,
        storageLocation: product.storageLocation,
        unit: product.unit,
        showInWeb: product.showInWeb,
        imageUrl: product.imageUrl,
        thumbnailUrl: product.thumbnailUrl,
        notes: product.notes,
        stockChangeReason: reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Movimentacao registrada.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  Future<void> _showProductActions(
    AppStore store,
    ProductRecord product,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined, size: 28),
            title: const Text('Editar'),
            onTap: () => Navigator.of(context).pop('edit'),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined, size: 28),
            title: const Text('Movimentar estoque'),
            onTap: () => Navigator.of(context).pop('stock'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, size: 28),
            title: const Text('Excluir'),
            onTap: () => Navigator.of(context).pop('delete'),
          ),
        ],
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'edit') {
      await _editProduct(store, product);
      return;
    }
    if (action == 'stock') {
      await _stockMovement(store, product);
      return;
    }
    if (action == 'delete') {
      await _deleteProduct(store, product);
    }
  }

  Future<void> _downloadProductTemplate() async {
    try {
      await _exportService.exportProductTemplate();
    } catch (e) {
      if (mounted) _showMessage('Erro ao baixar modelo: $e');
    }
  }

  Future<void> _showSpreadsheetGuide() async {
    const guide = '''
Modelo de planilha - Produtos (CSV/XLSX)

Colunas obrigatorias:
1) nome
2) categoria
3) preco_venda
4) custo
5) estoque
6) unidade

Colunas extras recomendadas:
- sku
- codigo_barras
- marca
- descricao
- tamanho
- variacao
- comissao
- estoque_minimo
- validade
- lote
- localizacao
- vitrine
- observacoes

Exemplo:
nome,sku,marca,categoria,preco_venda,custo,comissao,estoque,estoque_minimo,validade,unidade
Colonia Lily,BOT-LILY-100,O Boticario,Perfumes,189.90,120.00,15,8,2,15/12/2026,un
Batom Glam,EUD-BAT-014,Eudora,Cosmeticos,39.90,21.50,20,15,4,01/10/2026,un

Regras:
- primeira linha deve ser o cabecalho
- valores decimais com ponto ou virgula
- datas podem estar em dd/mm/aaaa ou formato ISO
- unidade recomendada: un, kg, lt, ml
''';

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Como montar a planilha'),
        content: const SingleChildScrollView(child: SelectableText(guide)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPricingModal(List<ProductRecord> products) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ProductPricingModal(products: products),
    );
  }

  Future<void> _showRecipePricingModal() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const RecipePricingHubModal(),
    );
  }

  Widget _buildToolSection({
    required IconData icon,
    required String title,
    required String description,
    required List<Widget> actions,
    List<Widget> metrics = const [],
  }) {
    return GradientCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF2563EB),
                  child: Icon(icon, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (metrics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: metrics),
            ],
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }

  Future<void> _showToolsPanel(AppStore store) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final catalog = store.products.toList();
            final filteredCatalog = catalog
                .where(_matchesSituationFilter)
                .toList();
            final products = _smartFilter(filteredCatalog);
            final activeBrands = store.brands.where((b) => b.isActive).length;
            final customCommissionCount = catalog
                .where((p) => p.hasCustomCommission)
                .length;
            final stockValue = catalog.fold<double>(
              0,
              (total, product) => total + (product.cost * product.stock),
            );

            return FractionallySizedBox(
              heightFactor: 0.9,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ferramentas',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Acoes avancadas do modulo de produtos e estoque.',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Fechar',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildToolSection(
                        icon: Icons.storefront_outlined,
                        title: 'Marcas e comissoes',
                        description:
                            'Organize fornecedores, comissao padrao e a base do catalogo.',
                        metrics: [
                          _buildMetricPill(
                            label: 'marcas ativas',
                            value: '$activeBrands',
                            color: const Color(0xFF2563EB),
                          ),
                          _buildMetricPill(
                            label: 'produtos com comissao propria',
                            value: '$customCommissionCount',
                            color: const Color(0xFF7C3AED),
                          ),
                          _buildMetricPill(
                            label: 'valor estimado em estoque',
                            value: AppFormatters.currency(stockValue),
                            color: const Color(0xFF15803D),
                          ),
                        ],
                        actions: [
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _showBrandManager(store);
                            },
                            icon: const Icon(Icons.storefront_outlined),
                            label: const Text('Gerenciar marcas'),
                          ),
                        ],
                      ),
                      _buildToolSection(
                        icon: Icons.upload_file_outlined,
                        title: 'Importacao em lote',
                        description:
                            'Use planilha CSV/XLSX para cadastrar ou atualizar varios produtos.',
                        actions: [
                          OutlinedButton.icon(
                            onPressed: _isImporting
                                ? null
                                : () => _importProducts(store),
                            icon: _isImporting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.file_upload_outlined),
                            label: Text(
                              _isImporting
                                  ? 'Importando...'
                                  : 'Importar planilha',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _downloadProductTemplate,
                            icon: const Icon(Icons.download_outlined, size: 16),
                            label: const Text('Baixar modelo'),
                          ),
                          TextButton.icon(
                            onPressed: _showSpreadsheetGuide,
                            icon: const Icon(
                              Icons.table_chart_outlined,
                              size: 16,
                            ),
                            label: const Text('Ver guia'),
                          ),
                        ],
                      ),
                      _buildToolSection(
                        icon: Icons.restaurant_menu_outlined,
                        title: 'Ficha tecnica para acai e comida',
                        description:
                            'Monte receitas, insumos e custo automatico fora do estoque comum.',
                        actions: [
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _showRecipePricingModal();
                            },
                            icon: const Icon(Icons.restaurant_menu_outlined),
                            label: const Text('Abrir ficha tecnica'),
                          ),
                        ],
                      ),
                      _buildToolSection(
                        icon: Icons.price_change_outlined,
                        title: 'Precificacao de produtos',
                        description:
                            'Veja margem atual, preco sugerido e exporte a analise completa.',
                        actions: [
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _showPricingModal(products);
                            },
                            icon: const Icon(Icons.price_change_outlined),
                            label: Text(
                              products.isEmpty
                                  ? 'Abrir precificacao'
                                  : 'Analisar ${products.length} produto(s)',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Produtos e Estoque',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _showToolsPanel(store),
              icon: const Icon(Icons.construction_outlined, size: 18),
              label: const Text('Ferramentas'),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final catalog = store.products.toList()
            ..sort((a, b) {
              int priority(ProductRecord product) {
                if (product.isExpired) return 0;
                if (product.isLowStock) return 1;
                if (product.isExpiringWithin(30)) return 2;
                return 3;
              }

              final compare = priority(a).compareTo(priority(b));
              if (compare != 0) return compare;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
          final filteredCatalog = catalog
              .where(_matchesSituationFilter)
              .toList();
          final products = _smartFilter(filteredCatalog);
          final lowStockCount = catalog.where((p) => p.isLowStock).length;
          final expiredCount = catalog.where((p) => p.isExpired).length;
          final expiringSoonCount = catalog
              .where((p) => !p.isExpired && p.isExpiringWithin(30))
              .length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSummaryCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Produtos cadastrados',
                    value: '${catalog.length}',
                    color: const Color(0xFF2563EB),
                  ),
                  _buildSummaryCard(
                    icon: Icons.remove_shopping_cart_outlined,
                    label: 'Estoque baixo',
                    value: '$lowStockCount',
                    color: const Color(0xFFDC2626),
                  ),
                  _buildSummaryCard(
                    icon: Icons.event_busy_outlined,
                    label: 'Vencendo em ate 30 dias',
                    value: '$expiringSoonCount',
                    color: const Color(0xFFD97706),
                  ),
                  _buildSummaryCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Produtos vencidos',
                    value: '$expiredCount',
                    color: const Color(0xFFB91C1C),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GradientCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _situationFilter == null,
                        onSelected: (_) {
                          setState(() => _situationFilter = null);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Novos'),
                        selected:
                            _situationFilter == ProductSituation.newRelease,
                        onSelected: (_) {
                          setState(
                            () =>
                                _situationFilter = ProductSituation.newRelease,
                          );
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Antigos'),
                        selected: _situationFilter == ProductSituation.old,
                        onSelected: (_) {
                          setState(
                            () => _situationFilter = ProductSituation.old,
                          );
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Promocao'),
                        selected:
                            _situationFilter == ProductSituation.promotion,
                        onSelected: (_) {
                          setState(
                            () => _situationFilter = ProductSituation.promotion,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GradientCard(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Busca por nome, marca, SKU ou descricao',
                    hintText: 'Ex.: lily, natura, BOT-001, hidratante...',
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
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _search = value.trim();
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (products.isEmpty)
                const GradientCard(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Nenhum produto encontrado. Cadastre um item novo ou importe uma planilha.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ...products.map((product) {
                final identityParts = <String>[
                  product.category,
                  if (product.sku.isNotEmpty) 'SKU ${product.sku}',
                  if (product.barcode.isNotEmpty) 'Cod. ${product.barcode}',
                  if (product.sizeLabel.isNotEmpty) product.sizeLabel,
                  if (product.variation.isNotEmpty) product.variation,
                ];
                final financialChips = <Widget>[
                  _buildInfoChip(
                    icon: Icons.inventory_2_outlined,
                    label:
                        '${product.stock.toStringAsFixed(2)} ${product.unit}',
                    color: product.isLowStock
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF475569),
                  ),
                  if (product.stockMinimum > 0)
                    _buildInfoChip(
                      icon: Icons.low_priority_outlined,
                      label: 'Min. ${product.stockMinimum.toStringAsFixed(2)}',
                    ),
                  _buildInfoChip(
                    icon: Icons.percent_outlined,
                    label: '${product.commissionPercent.toStringAsFixed(1)}%',
                    color: const Color(0xFF7C3AED),
                  ),
                  _buildInfoChip(
                    icon: Icons.trending_up_outlined,
                    label:
                        'Lucro ${AppFormatters.currency(product.estimatedProfitPerUnit)}',
                    color: const Color(0xFF15803D),
                  ),
                  if (product.hasAutomaticDiscount)
                    _buildInfoChip(
                      icon: Icons.discount_outlined,
                      label:
                          '${product.automaticDiscountPercent.toStringAsFixed(1)}% off',
                      color: const Color(0xFFB45309),
                    ),
                  if (product.expiryDate != null)
                    _buildInfoChip(
                      icon: Icons.event_outlined,
                      label: AppFormatters.date(product.expiryDate!),
                      color: product.isExpired
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF475569),
                    ),
                ];
                final chips = _buildProductStatusChips(product);

                return GradientCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
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
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    identityParts.join(' | '),
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  AppFormatters.currency(
                                    product.effectiveSalePrice,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (product.hasAutomaticDiscount)
                                  Text(
                                    AppFormatters.currency(product.salePrice),
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  tooltip: 'Acoes',
                                  visualDensity: VisualDensity.compact,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  onPressed: () =>
                                      _showProductActions(store, product),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (product.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: financialChips,
                        ),
                        if (product.batchCode.isNotEmpty ||
                            product.storageLocation.isNotEmpty ||
                            product.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            [
                              if (product.batchCode.isNotEmpty)
                                'Lote ${product.batchCode}',
                              if (product.storageLocation.isNotEmpty)
                                'Local ${product.storageLocation}',
                              if (product.notes.isNotEmpty) product.notes,
                            ].join(' | '),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (chips.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, runSpacing: 6, children: chips),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addProduct(store),
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Novo produto'),
      ),
    );
  }
}
