import 'package:flutter/material.dart';

import '../../../core/app_formatters.dart';
import '../../../core/app_store.dart';
import '../../../core/utils/search_utils.dart';
import '../../shared/gradient_card.dart';

class FastSaleModal extends StatefulWidget {
  const FastSaleModal({super.key});

  @override
  State<FastSaleModal> createState() => _FastSaleModalState();
}

class _FastSaleModalState extends State<FastSaleModal> {
  final _productSearchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String? _selectedProductId;

  @override
  void dispose() {
    _productSearchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  ProductRecord? _findProductById(
    List<ProductRecord> products,
    String? productId,
  ) {
    if (productId == null) return null;
    for (final product in products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  void _onProductTextChanged(String value, List<ProductRecord> products) {
    setState(() {
      final selected = _findProductById(products, _selectedProductId);
      if (selected == null) {
        _selectedProductId = null;
        return;
      }
      if (normalizeForSearch(value) != normalizeForSearch(selected.name)) {
        _selectedProductId = null;
      }
    });
  }

  void _onProductSelectionChanged(String? value, List<ProductRecord> products) {
    setState(() {
      _selectedProductId = value;
      final selected = _findProductById(products, value);
      if (selected == null) {
        _productSearchController.clear();
        return;
      }
      _productSearchController.text = selected.name;
    });
  }

  List<ProductRecord> _productMatches(List<ProductRecord> products) {
    final tokens = queryTokens(_productSearchController.text);
    if (tokens.isEmpty) return products;

    final starts = <ProductRecord>[];
    final contains = <ProductRecord>[];
    final category = <ProductRecord>[];

    for (final product in products) {
      final normalizedName = normalizeForSearch(product.name);
      final normalizedCategory = normalizeForSearch(product.category);

      final matchesName = tokens.every(normalizedName.contains);
      final matchesCategory = tokens.every(normalizedCategory.contains);

      if (!matchesName && !matchesCategory) continue;

      if (normalizedName.startsWith(tokens.first)) {
        starts.add(product);
      } else if (matchesName) {
        contains.add(product);
      } else {
        category.add(product);
      }
    }

    return [...starts, ...contains, ...category];
  }

  List<ProductRecord> _dropdownProducts({
    required List<ProductRecord> filtered,
    required List<ProductRecord> all,
    required String? selectedId,
  }) {
    final selected = _findProductById(all, selectedId);
    if (selected == null) return filtered;
    if (filtered.any((product) => product.id == selected.id)) return filtered;
    return <ProductRecord>[selected, ...filtered];
  }

  Future<void> _finishSale(AppStore store, String paymentMethod) async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um produto para a venda.')),
      );
      return;
    }

    final quantity = double.tryParse(
      _quantityController.text.replaceAll(',', '.'),
    );
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma quantidade válida.')),
      );
      return;
    }

    final error = await store.registerProductSale(
      productId: _selectedProductId!,
      quantity: quantity,
      paymentMethod: paymentMethod, // 'pix' or 'dinheiro'
      customerName: null,
      loanDueDate: null,
      loanInterestRate: 0,
      loanInterestUnit: LoanInterestUnit.month,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Venda rápida registrada com sucesso!')),
    );

    Navigator.of(context).pop(); // Fechar o Bottom Sheet
  }

  void _incrementQuantity() {
    final current =
        double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0;
    _quantityController.text = (current + 1).toStringAsFixed(0);
  }

  void _decrementQuantity() {
    final current =
        double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0;
    if (current > 1) {
      _quantityController.text = (current - 1).toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final allProducts = store.products.toList();
        final products = _productMatches(allProducts);
        final dropdownProducts = _dropdownProducts(
          filtered: products,
          all: allProducts,
          selectedId: _selectedProductId,
        );

        final productQuery = _productSearchController.text.trim();
        final showProductSuggestions = productQuery.isNotEmpty;

        if (_selectedProductId != null &&
            allProducts.every((p) => p.id != _selectedProductId)) {
          _selectedProductId = null;
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '⚡ Venda Rápida',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _productSearchController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Buscar produto',
                  hintText: 'Digite nome ou categoria',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _productSearchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            setState(() {
                              _productSearchController.clear();
                              _selectedProductId = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (value) => _onProductTextChanged(value, allProducts),
              ),
              if (showProductSuggestions && products.isNotEmpty)
                GradientCard(
                  margin: const EdgeInsets.only(top: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: products.take(5).map((product) {
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                              '${product.category} | Estoque: ${product.stock.toStringAsFixed(2)} ${product.unit}',
                            ),
                            trailing: Text(
                              AppFormatters.currency(
                                product.effectiveSalePrice,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedProductId = product.id;
                                _productSearchController.text = product.name;
                                FocusScope.of(context).unfocus();
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              if (productQuery.isNotEmpty && products.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Nenhum produto encontrado para esta busca.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _selectedProductId,
                menuMaxHeight: 250,
                decoration: const InputDecoration(
                  labelText: 'Produto Selecionado',
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Nenhum produto selecionado'),
                  ),
                  ...dropdownProducts.map(
                    (product) => DropdownMenuItem<String?>(
                      value: product.id,
                      child: Text(
                        '${product.name} - ${AppFormatters.currency(product.effectiveSalePrice)}',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    _onProductSelectionChanged(value, allProducts),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Quantidade:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _decrementQuantity,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 8,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _incrementQuantity,
                    icon: const Icon(Icons.add_circle_outline),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              if (!isKeyboardOpen)
                const SizedBox(height: 32)
              else
                const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981), // Emerald 500
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _selectedProductId == null
                          ? null
                          : () => _finishSale(store, 'dinheiro'),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text(
                        'DINHEIRO',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9), // Sky 500
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _selectedProductId == null
                          ? null
                          : () => _finishSale(store, 'pix'),
                      icon: const Icon(Icons.pix),
                      label: const Text(
                        'PIX',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
