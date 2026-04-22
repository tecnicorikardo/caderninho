import 'package:flutter/material.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String _mode = 'livre';
  String _paymentMethod = 'pix';
  String? _selectedProductId;

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _registerSale(AppStore store) {
    if (_mode == 'livre') {
      final value = double.tryParse(_valueController.text.replaceAll(',', '.'));
      if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um valor valido para a venda.')),
        );
        return;
      }

      store.registerFreeSale(
        description: _descriptionController.text.trim().isEmpty
            ? 'Venda livre'
            : _descriptionController.text.trim(),
        total: value,
        paymentMethod: _paymentMethod,
      );

      _descriptionController.clear();
      _valueController.clear();
      return;
    }

    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um produto para a venda.')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma quantidade valida.')),
      );
      return;
    }

    final error = store.registerProductSale(
      productId: _selectedProductId!,
      quantity: quantity,
      paymentMethod: _paymentMethod,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _quantityController.text = '1';
  }

  Future<void> _confirmDeleteSale(AppStore store, SaleRecord sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir venda'),
        content: Text(
          'Deseja realmente excluir esta venda?\n\n'
          '${sale.description}\n'
          'Valor: ${AppFormatters.currency(sale.total)}\n\n'
          '${sale.mode == SaleMode.product ? 'O estoque será devolvido.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final error = await store.deleteSale(sale.id);
      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Venda excluída com sucesso')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Vendas')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final products = store.products.toList();
          final sales = store.sales.toList();

          if (_selectedProductId != null && products.every((p) => p.id != _selectedProductId)) {
            _selectedProductId = null;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(value: 'livre', label: Text('Venda livre')),
                  ButtonSegment<String>(value: 'produto', label: Text('Com produto')),
                ],
                selected: <String>{_mode},
                onSelectionChanged: (value) {
                  setState(() {
                    _mode = value.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_mode == 'livre') ...[
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                ),
              ] else ...[
                if (products.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('Cadastre produtos para usar venda com produto.'),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedProductId,
                    decoration: const InputDecoration(labelText: 'Produto'),
                    items: products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.name} (${p.stock.toStringAsFixed(2)} ${p.unit})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProductId = value;
                      });
                    },
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                ),
              ],
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Forma de pagamento'),
                items: const [
                  DropdownMenuItem(value: 'pix', child: Text('Pix')),
                  DropdownMenuItem(value: 'dinheiro', child: Text('Dinheiro')),
                  DropdownMenuItem(value: 'cartao', child: Text('Cartao')),
                  DropdownMenuItem(value: 'outros', child: Text('Outros')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value ?? 'pix';
                  });
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _registerSale(store),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Finalizar venda'),
              ),
              const SizedBox(height: 16),
              Text(
                'Vendas registradas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (sales.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Nenhuma venda registrada ainda.'),
                  ),
                ),
              ...sales.map(
                (sale) => Card(
                  child: ListTile(
                    title: Text(sale.description),
                    subtitle: Text(
                      '${sale.mode == SaleMode.product ? 'Com produto' : 'Livre'} | ${sale.paymentMethod} | ${AppFormatters.time(sale.createdAt)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppFormatters.currency(sale.total)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDeleteSale(store, sale),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
