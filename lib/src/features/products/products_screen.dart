import 'package:flutter/material.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  Future<void> _addProduct(AppStore store) async {
    final nameController = TextEditingController();
    final categoryController = TextEditingController(text: 'Geral');
    final salePriceController = TextEditingController();
    final costController = TextEditingController();
    final stockController = TextEditingController();
    final unitController = TextEditingController(text: 'un');
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo produto'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: salePriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Preco de venda'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Custo'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: stockController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Estoque'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Unidade (un/kg/lt)'),
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
      ),
    );

    if (shouldSave != true) return;

    store.addProduct(
      name: nameController.text.trim(),
      category: categoryController.text.trim().isEmpty ? 'Geral' : categoryController.text.trim(),
      salePrice: double.tryParse(salePriceController.text.replaceAll(',', '.')) ?? 0,
      cost: double.tryParse(costController.text.replaceAll(',', '.')) ?? 0,
      stock: double.tryParse(stockController.text.replaceAll(',', '.')) ?? 0,
      unit: unitController.text.trim().isEmpty ? 'un' : unitController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Produtos e Estoque')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final products = store.products;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              if (products.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Nenhum produto cadastrado.'),
                  ),
                ),
              ...products.map(
                (product) {
                  final unitProfit = product.salePrice - product.cost;
                  final margin = product.salePrice > 0 
                      ? ((unitProfit / product.salePrice) * 100) 
                      : 0;
                  
                  return Card(
                    child: ExpansionTile(
                      leading: Icon(
                        Icons.inventory_2,
                        color: product.stock > 0 ? Colors.green : Colors.red,
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.category} | Estoque: ${product.stock.toStringAsFixed(2)} ${product.unit}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.currency(product.salePrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${margin.toStringAsFixed(0)}% margem',
                            style: TextStyle(
                              fontSize: 12,
                              color: margin >= 30 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: [
                              const Divider(),
                              _buildInfoRow(
                                'Preço de Venda',
                                AppFormatters.currency(product.salePrice),
                              ),
                              _buildInfoRow(
                                'Custo Unitário',
                                AppFormatters.currency(product.cost),
                              ),
                              _buildInfoRow(
                                'Lucro Unitário',
                                AppFormatters.currency(unitProfit),
                                color: unitProfit >= 0 ? Colors.green : Colors.red,
                              ),
                              _buildInfoRow(
                                'Margem de Lucro',
                                '${margin.toStringAsFixed(1)}%',
                                color: margin >= 30 ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Valor total em estoque: ${AppFormatters.currency(product.cost * product.stock)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
