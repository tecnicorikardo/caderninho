import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';
import '../../core/utils/search_utils.dart';
import '../subscription/models/subscription_model.dart';
import '../subscription/services/export_service.dart';
import '../subscription/services/subscription_service.dart';
import '../subscription/subscription_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pixKeyController = TextEditingController();
  final _subscriptionService = SubscriptionService();
  final _exportService = ExportService();

  bool _loaded = false;
  bool _isDeleting = false;
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _pixKeyController.dispose();
    super.dispose();
  }

  String _errorText(Object error) {
    if (error is FirebaseException) {
      return error.message ?? 'Falha ao salvar configuracoes.';
    }
    return error.toString();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(AppStore store) async {
    if (_formKey.currentState?.validate() != true) return;
    try {
      await store.saveShopProfile(
        storeName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        pixKey: _pixKeyController.text.trim(),
        storeSlug: _nameController.text.trim(), // gera slug a partir do nome
        isActive: true,
      );
      _showMessage('Configuracoes salvas.');
    } catch (error) {
      _showMessage(_errorText(error));
    }
  }

  Future<void> _exportCustomers(AppStore store) async {
    setState(() => _isExporting = true);
    try {
      final savedPath = await _exportService.exportCustomers(
        store.customers.toList(),
      );
      if (savedPath == null) {
        _showMessage('Clientes exportados com sucesso.');
      } else {
        _showMessage('Clientes exportados em: $savedPath');
      }
    } catch (error, stackTrace) {
      debugPrint('[Settings][Export][Clientes] Falha: $error');
      debugPrint('$stackTrace');
      _showMessage('Erro ao exportar clientes: $error');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportProducts(AppStore store) async {
    setState(() => _isExporting = true);
    try {
      final savedPath = await _exportService.exportProducts(
        store.products.toList(),
      );
      if (savedPath == null) {
        _showMessage('Produtos exportados com sucesso.');
      } else {
        _showMessage('Produtos exportados em: $savedPath');
      }
    } catch (error, stackTrace) {
      debugPrint('[Settings][Export][Produtos] Falha: $error');
      debugPrint('$stackTrace');
      _showMessage('Erro ao exportar produtos: $error');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importCustomers(AppStore store) async {
    if (_isImporting) return;

    setState(() => _isImporting = true);
    try {
      final importedRows = await _exportService
          .importCustomersFromSpreadsheet();
      if (importedRows.isEmpty) {
        _showMessage('Importacao cancelada ou sem linhas validas.');
        return;
      }

      final existingByName = <String, CustomerRecord>{
        for (final customer in store.customers)
          normalizeLookupKey(customer.name): customer,
      };
      final processed = <String>{};
      var created = 0;
      var updated = 0;
      var reactivated = 0;

      for (final row in importedRows) {
        final key = normalizeLookupKey(row.name);
        if (key.isEmpty || processed.contains(key)) {
          continue;
        }
        processed.add(key);

        final existing = existingByName[key];
        if (existing == null) {
          await store.addCustomer(name: row.name, phone: row.phone);
          created++;
          continue;
        }

        final mustUpdate =
            existing.name != row.name || existing.phone != row.phone;
        if (mustUpdate) {
          await store.updateCustomer(
            customerId: existing.id,
            name: row.name,
            phone: row.phone,
          );
          updated++;
        }

        if (!existing.isActive) {
          await store.reactivateCustomer(customerId: existing.id);
          reactivated++;
        }
      }

      final reactivatedSuffix = reactivated > 0
          ? ', $reactivated reativados'
          : '';
      _showMessage(
        'Importacao de clientes concluida: $created novos, $updated atualizados$reactivatedSuffix.',
      );
    } catch (error, stackTrace) {
      debugPrint('[Settings][Import][Clientes] Falha: $error');
      debugPrint('$stackTrace');
      _showMessage('Erro ao importar clientes: $error');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _importProducts(AppStore store) async {
    if (_isImporting) return;

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

        BrandRecord? linkedBrand;
        for (final brand in store.brands) {
          if (normalizeLookupKey(brand.name) ==
              normalizeLookupKey(row.brandName)) {
            linkedBrand = brand;
            break;
          }
        }
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
      debugPrint('[Settings][Import][Produtos] Falha: $error');
      debugPrint('$stackTrace');
      _showMessage('Erro ao importar produtos: $error');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _deleteTransactionsOnly(AppStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar somente transacoes?'),
        content: const Text(
          'Isso vai apagar todas as vendas, fiados, emprestimos e lancamentos financeiros.\n\n'
          'Clientes e produtos serao mantidos.\n\n'
          'Esta acao nao pode ser desfeita!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apagar transacoes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await store.deleteAllTransactions();
      _showMessage('Transacoes apagadas com sucesso.');
    } catch (error) {
      _showMessage('Erro ao apagar transacoes: $error');
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _deleteEverything(AppStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar tudo?'),
        content: const Text(
          'Isso vai apagar TODOS os dados:\n'
          '� Clientes\n'
          '� Produtos\n'
          '� Vendas\n'
          '� Fiados\n'
          '� Emprestimos\n'
          '� Lancamentos financeiros\n\n'
          'Esta acao nao pode ser desfeita!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await store.deleteAllData();
      _showMessage('Todos os dados foram apagados.');
    } catch (error) {
      _showMessage('Erro ao apagar dados: $error');
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    if (!_loaded) {
      _nameController.text = store.shopProfile.storeName;
      _addressController.text = store.shopProfile.address;
      _phoneController.text = store.shopProfile.phone;
      _pixKeyController.text = store.shopProfile.pixKey;
      _loaded = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _VitrineCard(store: store),
          const SizedBox(height: 16),
          _MySubscriptionSection(subscriptionService: _subscriptionService),
          const SizedBox(height: 24),
          _ImportSection(
            isImporting: _isImporting,
            onImportCustomers: () => _importCustomers(store),
            onImportProducts: () => _importProducts(store),
          ),
          const SizedBox(height: 24),
          _ExportSection(
            isExporting: _isExporting,
            onExportCustomers: () => _exportCustomers(store),
            onExportProducts: () => _exportProducts(store),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados da Loja',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da loja',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome da loja';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Endereco da loja',
                      ),
                      minLines: 2,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone da loja',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _pixKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Chave PIX',
                        helperText: 'Opcional: usada na cobranca do WhatsApp',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _save(store),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Salvar configuracoes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SupportSection(),
          const SizedBox(height: 24),
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Zona de perigo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isDeleting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.delete_sweep,
                        color: Colors.orange,
                      ),
                      title: const Text('Apagar somente transacoes'),
                      subtitle: const Text(
                        'Remove vendas, fiados e lancamentos. Mantem clientes e produtos.',
                      ),
                      trailing: OutlinedButton(
                        onPressed: () => _deleteTransactionsOnly(store),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                        child: const Text('Apagar'),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      title: const Text('Apagar tudo'),
                      subtitle: const Text(
                        'Remove todos os dados: clientes, produtos, vendas, etc.',
                      ),
                      trailing: OutlinedButton(
                        onPressed: () => _deleteEverything(store),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Apagar'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MySubscriptionSection extends StatelessWidget {
  const _MySubscriptionSection({required this.subscriptionService});

  final SubscriptionService subscriptionService;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_membership),
                const SizedBox(width: 8),
                const Text(
                  'Minha Assinatura',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<SubscriptionModel?>(
              stream: subscriptionService.getCurrentSubscription(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text('Carregando...');
                }

                final subscription = snapshot.data!;
                final isExpired = subscription.isExpired;
                final daysRemaining = subscription.daysUntilExpiration;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Plano: '),
                        Text(
                          subscription.plan == SubscriptionPlan.free
                              ? 'Gratuito (Trial)'
                              : subscription.plan.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Expira em: '),
                        Text(
                          AppFormatters.date(subscription.expirationDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Status: '),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isExpired
                                ? 'Expirada'
                                : daysRemaining == 0
                                ? 'Expira hoje'
                                : 'Ativa ($daysRemaining ${daysRemaining == 1 ? 'dia' : 'dias'})',
                            style: TextStyle(
                              color: isExpired
                                  ? Colors.red.shade900
                                  : Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SubscriptionScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.credit_card),
                        label: const Text('Gerenciar Assinatura'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportSection extends StatelessWidget {
  const _ImportSection({
    required this.isImporting,
    required this.onImportCustomers,
    required this.onImportProducts,
  });

  final bool isImporting;
  final VoidCallback onImportCustomers;
  final VoidCallback onImportProducts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.file_upload),
                const SizedBox(width: 8),
                const Text(
                  'Importar Dados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Importe planilhas CSV/XLSX de clientes e produtos',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (isImporting)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onImportCustomers,
                    icon: const Icon(Icons.people_alt_outlined),
                    label: const Text('Importar clientes'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onImportProducts,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Importar produtos'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ExportSection extends StatelessWidget {
  const _ExportSection({
    required this.isExporting,
    required this.onExportCustomers,
    required this.onExportProducts,
  });

  final bool isExporting;
  final VoidCallback onExportCustomers;
  final VoidCallback onExportProducts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.file_download),
                const SizedBox(width: 8),
                const Text(
                  'Exportar Dados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Exporte seus dados para Excel',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (isExporting)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onExportCustomers,
                    icon: const Icon(Icons.people),
                    label: const Text('Exportar clientes'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onExportProducts,
                    icon: const Icon(Icons.inventory),
                    label: const Text('Exportar produtos'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _VitrineCard extends StatelessWidget {
  const _VitrineCard({required this.store});

  final AppStore store;

  void _copyLink(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copiado!')));
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slug = store.shopProfile.storeSlug;
    final storeName = store.shopProfile.storeName;
    final hasSlug = slug.isNotEmpty;
    final vitrineUrl = hasSlug
        ? 'https://bloquinhodigital.web.app/$slug'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0EA5A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storefront, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Sua Vitrine Online',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasSlug) ...[
            Text(
              storeName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      vitrineUrl!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyLink(context, vitrineUrl!),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar link'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openLink(vitrineUrl!),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Abrir vitrine'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F766E),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'Configure o nome da sua loja abaixo para ativar sua vitrine online.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  Future<void> _openWhatsApp() async {
    final url = Uri.parse('https://wa.me/5521970902074');
    final launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!launched) {
      throw Exception('Nao foi possivel abrir o WhatsApp');
    }
  }

  Future<void> _openEmail() async {
    final url = Uri.parse('mailto:tecnicorikardo@gmail.com');
    final launched = await launchUrl(url);
    if (!launched) {
      throw Exception('Nao foi possivel abrir o email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent),
                const SizedBox(width: 8),
                const Text(
                  'Suporte',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: const Text('tecnicorikardo@gmail.com'),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: _openEmail,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone),
              title: const Text('WhatsApp'),
              subtitle: const Text('(21) 97090-2074'),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: _openWhatsApp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
