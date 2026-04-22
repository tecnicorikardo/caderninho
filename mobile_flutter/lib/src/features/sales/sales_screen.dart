import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/app_formatters.dart';
import '../../core/app_store.dart';
import '../../core/subscription_middleware.dart';
import '../../core/utils/search_utils.dart';
import '../shared/gradient_card.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key, required this.onFiadoSaleCreated});
  final VoidCallback onFiadoSaleCreated;
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _subscriptionMiddleware = SubscriptionMiddleware();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _customerSearchController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _loanDueDateController = TextEditingController();
  final _loanInterestController = TextEditingController(text: '2');
  String _mode = 'livre';
  String _paymentMethod = 'pix';
  LoanInterestUnit _loanInterestUnit = LoanInterestUnit.month;
  String? _selectedProductId;
  CustomerRecord? _selectedCustomer;
  String _errorText(Object error) {
    if (error is FirebaseException) {
      return error.message ?? 'Falha ao salvar no Firebase.';
    }
    return error.toString();
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'pix':
        return 'Pix';
      case 'dinheiro':
        return 'Dinheiro';
      case 'cartao':
        return 'Cartao';
      case 'fiado':
        return 'Fiado';
      case 'emprestimo':
        return 'Emprestimo';
      default:
        return 'Outros';
    }
  }

  Future<Uint8List> _buildReceiptPdfBytes(
    _SaleReceiptData data,
    ShopProfile profile,
  ) async {
    final doc = pw.Document();
    final storeName = profile.storeName.trim().isEmpty
        ? 'LOJA'
        : profile.storeName.trim().toUpperCase();
    final storeAddress = profile.address.trim();
    final storePhone = profile.phone.trim();
    final customerLabel = (data.customerName ?? '').trim().isEmpty
        ? 'Nao informado'
        : data.customerName!.trim();
    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 1.2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    storeName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                if (storeAddress.isNotEmpty)
                  pw.Text(
                    storeAddress,
                    style: const pw.TextStyle(fontSize: 10.5),
                  ),
                if (storePhone.isNotEmpty)
                  pw.Text(
                    'Tel: $storePhone',
                    style: const pw.TextStyle(fontSize: 10.5),
                  ),
                if (storeAddress.isNotEmpty || storePhone.isNotEmpty)
                  pw.SizedBox(height: 8),
                pw.Text(
                  'RECIBO DE VENDA',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Data: ${AppFormatters.date(data.createdAt)} ${AppFormatters.time(data.createdAt)}',
                  style: const pw.TextStyle(fontSize: 10.5),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Descricao: ${data.description}',
                  style: const pw.TextStyle(fontSize: 10.5),
                ),
                if (data.productName != null && data.productName!.isNotEmpty)
                  pw.Text(
                    'Produto: ${data.productName}',
                    style: const pw.TextStyle(fontSize: 10.5),
                  ),
                if (data.quantity != null)
                  pw.Text(
                    'Quantidade: ${data.quantity!.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 10.5),
                  ),
                pw.Text(
                  'Cliente: $customerLabel',
                  style: const pw.TextStyle(fontSize: 10.5),
                ),
                pw.Text(
                  'Pagamento: ${_paymentMethodLabel(data.paymentMethod)}',
                  style: const pw.TextStyle(fontSize: 10.5),
                ),
                pw.Text(
                  'Total: ${AppFormatters.currency(data.total)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 22),
                pw.Text('Assinatura do cliente:'),
                pw.SizedBox(height: 24),
                pw.Container(height: 1, width: 250),
                pw.SizedBox(height: 14),
                pw.Text(
                  'Obrigado pela preferencia.',
                  style: const pw.TextStyle(fontSize: 10.5),
                ),
              ],
            ),
          );
        },
      ),
    );
    return doc.save();
  }

  String _receiptFileName(ShopProfile profile, DateTime createdAt) {
    final title = profile.storeName.trim().isEmpty
        ? 'recibo'
        : profile.storeName.trim().replaceAll(' ', '_');
    final date = AppFormatters.date(createdAt).replaceAll('/', '-');
    return '${title}_$date.pdf';
  }

  Future<void> _shareReceipt(_SaleReceiptData data, ShopProfile profile) async {
    final bytes = await _buildReceiptPdfBytes(data, profile);
    final filename = _receiptFileName(profile, data.createdAt);
    try {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel compartilhar o comprovante.'),
        ),
      );
    }
  }

  Future<void> _printReceipt(_SaleReceiptData data, ShopProfile profile) async {
    final bytes = await _buildReceiptPdfBytes(data, profile);
    if (!mounted) return;

    final title = profile.storeName.trim().isEmpty
        ? 'Recibo'
        : profile.storeName.trim();
    final fileName = _receiptFileName(profile, data.createdAt);

    var canPrint = true;
    try {
      final info = await Printing.info();
      canPrint = info.canPrint;
    } catch (_) {
      // Mantem fallback quando o plugin nao consegue informar capacidade.
    }

    Future<bool> tryShare(String successMessage) async {
      try {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
        if (!mounted) return true;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
        return true;
      } catch (_) {
        return false;
      }
    }

    if (!canPrint) {
      final shared = await tryShare(
        'Este dispositivo nao suporta impressao direta. Comprovante pronto para compartilhar.',
      );
      if (!shared && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impressao indisponivel neste dispositivo. Use compartilhar para enviar o comprovante.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final opened = await Printing.layoutPdf(
        name: '$title - Recibo',
        onLayout: (_) async => bytes,
      );
      if (opened) return;
    } catch (_) {
      // Segue para fallback de compartilhamento.
    }

    final shared = await tryShare(
      'Nao foi possivel abrir a impressao. Comprovante pronto para compartilhar.',
    );
    if (!shared && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao foi possivel abrir a impressao neste dispositivo.',
          ),
        ),
      );
    }
  }

  Future<String?> _askReceiptAction() async {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Deseja enviar ou imprimir o comprovante?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Enviar via WhatsApp / compartilhar'),
                subtitle: const Text('Usa o compartilhamento do aparelho'),
                onTap: () => Navigator.of(context).pop('share'),
              ),
              ListTile(
                leading: const Icon(Icons.print_outlined),
                title: const Text('Imprimir'),
                onTap: () => Navigator.of(context).pop('print'),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Finalizar sem comprovante'),
                onTap: () => Navigator.of(context).pop('none'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelCompletedSale(AppStore store, SaleRecord sale) async {
    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'removeSale',
    );
    if (!canAccess) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar venda concluida'),
        content: Text(
          'Deseja cancelar esta venda?\n\nIsso vai remover a venda e desfazer estoque/financeiro quando aplicavel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar venda'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await store.cancelSale(sale: sale);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Venda cancelada com sucesso.')),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    _quantityController.dispose();
    _customerSearchController.dispose();
    _productSearchController.dispose();
    _loanDueDateController.dispose();
    _loanInterestController.dispose();
    super.dispose();
  }

  List<CustomerRecord> _customerMatches(List<CustomerRecord> customers) {
    final query = _customerSearchController.text.trim().toLowerCase();
    if (query.length < 3) return const <CustomerRecord>[];
    return customers.where((customer) {
      if (!customer.isActive) return false;
      final name = customer.name.toLowerCase();
      final phone = customer.phone.toLowerCase();
      return name.startsWith(query) ||
          name.contains(query) ||
          phone.contains(query);
    }).toList();
  }

  void _onCustomerTextChanged(String value) {
    setState(() {
      if (_selectedCustomer == null) return;
      final current = value.trim().toLowerCase();
      if (current != _selectedCustomer!.name.toLowerCase()) {
        _selectedCustomer = null;
      }
    });
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

  void _resetAfterSale({required bool clearCustomer}) {
    setState(() {
      _descriptionController.clear();
      _valueController.clear();
      _quantityController.text = '1';
      _selectedProductId = null;
      if (clearCustomer) {
        _customerSearchController.clear();
        _selectedCustomer = null;
      }
    });
  }

  bool get _hasDraft {
    return _descriptionController.text.trim().isNotEmpty ||
        _valueController.text.trim().isNotEmpty ||
        _quantityController.text.trim() != '1' ||
        _customerSearchController.text.trim().isNotEmpty ||
        _productSearchController.text.trim().isNotEmpty ||
        _loanDueDateController.text.trim().isNotEmpty ||
        _loanInterestController.text.trim() != '2' ||
        _selectedProductId != null ||
        _selectedCustomer != null;
  }

  Future<void> _cancelSaleDraft() async {
    if (!_hasDraft) return;
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar venda'),
        content: const Text('Deseja limpar os dados preenchidos desta venda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar venda'),
          ),
        ],
      ),
    );
    if (shouldCancel != true || !mounted) return;
    setState(() {
      _mode = 'livre';
      _paymentMethod = 'pix';
      _productSearchController.clear();
      _loanDueDateController.clear();
      _loanInterestController.text = '2';
      _loanInterestUnit = LoanInterestUnit.month;
    });
    _resetAfterSale(clearCustomer: true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Venda cancelada.')));
  }

  Future<void> _registerSale(AppStore store) async {
    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'registerSale',
    );
    if (!canAccess) return;
    final isFiado = _paymentMethod == 'fiado';
    final isLoan = _paymentMethod == 'emprestimo';
    final typedCustomer = _customerSearchController.text.trim();
    final customerName =
        _selectedCustomer?.name ??
        (typedCustomer.isEmpty ? null : typedCustomer);
    if ((isFiado || isLoan) && customerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLoan
                ? 'Informe o cliente para venda de emprestimo.'
                : 'Informe o cliente para venda fiado.',
          ),
        ),
      );
      return;
    }
    DateTime? loanDueDate;
    var loanInterestRate = 2.0;
    if (isLoan) {
      final parts = _loanDueDateController.text.split('/');
      if (parts.length != 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe o vencimento do emprestimo.')),
        );
        return;
      }
      loanDueDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      loanInterestRate =
          double.tryParse(_loanInterestController.text.replaceAll(',', '.')) ??
          0;
    }
    final mustUseProduct = _mode == 'produto';
    if (mustUseProduct && _selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um produto para venda com produto.'),
        ),
      );
      return;
    }
    final shouldUseProduct = _selectedProductId != null;
    late final _SaleReceiptData receiptData;
    if (shouldUseProduct) {
      final quantity = double.tryParse(
        _quantityController.text.replaceAll(',', '.'),
      );
      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe uma quantidade valida.')),
        );
        return;
      }
      final error = await store.registerProductSale(
        productId: _selectedProductId!,
        quantity: quantity,
        paymentMethod: _paymentMethod,
        customerName: customerName,
        loanDueDate: loanDueDate,
        loanInterestRate: loanInterestRate,
        loanInterestUnit: _loanInterestUnit,
      );
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      ProductRecord? product;
      for (final item in store.products) {
        if (item.id == _selectedProductId) {
          product = item;
          break;
        }
      }
      final total = (product?.salePrice ?? 0) * quantity;
      receiptData = _SaleReceiptData(
        description: 'Venda de ${product?.name ?? 'Produto'}',
        total: total,
        paymentMethod: _paymentMethod,
        customerName: customerName,
        productName: product?.name,
        quantity: quantity,
        createdAt: DateTime.now(),
      );
    } else {
      final value = double.tryParse(_valueController.text.replaceAll(',', '.'));
      if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informe um valor valido para a venda livre.'),
          ),
        );
        return;
      }
      try {
        await store.registerFreeSale(
          description: _descriptionController.text.trim().isEmpty
              ? 'Venda livre'
              : _descriptionController.text.trim(),
          total: value,
          paymentMethod: _paymentMethod,
          customerName: customerName,
          loanDueDate: loanDueDate,
          loanInterestRate: loanInterestRate,
          loanInterestUnit: _loanInterestUnit,
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
        return;
      }
      if (!mounted) return;
      receiptData = _SaleReceiptData(
        description: _descriptionController.text.trim().isEmpty
            ? 'Venda livre'
            : _descriptionController.text.trim(),
        total: value,
        paymentMethod: _paymentMethod,
        customerName: customerName,
        productName: null,
        quantity: null,
        createdAt: DateTime.now(),
      );
    }
    if (!mounted) return;
    final action = await _askReceiptAction();
    if (action == 'print') {
      await _printReceipt(receiptData, store.shopProfile);
    } else if (action == 'share') {
      await _shareReceipt(receiptData, store.shopProfile);
    }
    _resetAfterSale(clearCustomer: isFiado);
    if (isFiado) {
      widget.onFiadoSaleCreated();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venda registrada com sucesso.')),
      );
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
          final allProducts = store.products.toList();
          final products = _productMatches(allProducts);
          final dropdownProducts = _dropdownProducts(
            filtered: products,
            all: allProducts,
            selectedId: _selectedProductId,
          );
          final customers = store.customers.toList();
          final sales = store.sales.toList();
          final customerMatches = _customerMatches(customers);
          final customerQuery = _customerSearchController.text.trim();
          final productQuery = _productSearchController.text.trim();
          final showProductSuggestions = productQuery.isNotEmpty;
          if (_selectedProductId != null &&
              allProducts.every((p) => p.id != _selectedProductId)) {
            _selectedProductId = null;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'livre',
                    label: Text('Venda livre'),
                  ),
                  ButtonSegment<String>(
                    value: 'produto',
                    label: Text('Com produto'),
                  ),
                ],
                selected: <String>{_mode},
                onSelectionChanged: (value) {
                  setState(() {
                    _mode = value.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerSearchController,
                decoration: InputDecoration(
                  labelText: 'Cliente (opcional)',
                  hintText: 'Digite 3 letras para buscar (ex: Ric)',
                  prefixIcon: const Icon(Icons.person_search_outlined),
                  suffixIcon: _customerSearchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _customerSearchController.clear();
                              _selectedCustomer = null;
                            });
                          },
                        ),
                ),
                onChanged: _onCustomerTextChanged,
              ),
              if (customerQuery.isNotEmpty && customerQuery.length < 3)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Digite pelo menos 3 letras para a busca inteligente.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
              if (customerMatches.isNotEmpty)
                GradientCard(
                  margin: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: customerMatches.take(8).map((customer) {
                      final subtitle = customer.phone.isEmpty
                          ? 'Sem telefone'
                          : customer.phone;
                      return ListTile(
                        title: Text(customer.name),
                        subtitle: Text(subtitle),
                        onTap: () {
                          setState(() {
                            _selectedCustomer = customer;
                            _customerSearchController.text = customer.name;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _productSearchController,
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
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: SingleChildScrollView(
                      child: Column(
                        children: products.take(8).map((product) {
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                              '${product.category} | Estoque: ${product.stock.toStringAsFixed(2)} ${product.unit}',
                            ),
                            trailing: Text(
                              AppFormatters.currency(product.salePrice),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedProductId = product.id;
                                _productSearchController.text = product.name;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              if (_mode == 'produto' && productQuery.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Digite no campo de busca para listar produtos.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _selectedProductId,
                menuMaxHeight: 320,
                decoration: const InputDecoration(
                  labelText: 'Produto (opcional)',
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sem produto'),
                  ),
                  ...dropdownProducts.map(
                    (product) => DropdownMenuItem<String?>(
                      value: product.id,
                      child: Text(
                        '${product.name} (${product.stock.toStringAsFixed(2)} ${product.unit})',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    _onProductSelectionChanged(value, allProducts),
              ),
              if (_selectedProductId != null || _mode == 'produto') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                ),
              ] else ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descricao da venda',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                ),
              ],
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Forma de pagamento',
                ),
                items: const [
                  DropdownMenuItem(value: 'pix', child: Text('Pix')),
                  DropdownMenuItem(value: 'dinheiro', child: Text('Dinheiro')),
                  DropdownMenuItem(value: 'cartao', child: Text('Cartao')),
                  DropdownMenuItem(value: 'fiado', child: Text('Fiado')),
                  DropdownMenuItem(
                    value: 'emprestimo',
                    child: Text('Emprestimo'),
                  ),
                  DropdownMenuItem(value: 'outros', child: Text('Outros')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value ?? 'pix';
                  });
                },
              ),
              if (_paymentMethod == 'emprestimo') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _loanDueDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Vencimento do emprestimo',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (selected == null) return;
                    setState(() {
                      _loanDueDateController.text = AppFormatters.date(
                        selected,
                      );
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _loanInterestController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Juros (%)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<LoanInterestUnit>(
                  value: _loanInterestUnit,
                  decoration: const InputDecoration(
                    labelText: 'Periodicidade dos juros',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: LoanInterestUnit.day,
                      child: Text('Ao dia'),
                    ),
                    DropdownMenuItem(
                      value: LoanInterestUnit.month,
                      child: Text('Ao mes'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _loanInterestUnit = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async => _registerSale(store),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Finalizar venda'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _hasDraft ? _cancelSaleDraft : null,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Vendas registradas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (sales.isEmpty)
                const GradientCard(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Nenhuma venda registrada ainda.'),
                  ),
                ),
              ...sales.map((sale) {
                final modeLabel = sale.mode == SaleMode.product
                    ? 'Com produto'
                    : 'Livre';
                final customerLabel = sale.customerName ?? 'Sem cliente';
                final productLabel = sale.productName ?? 'Sem produto';
                return GradientCard(
                  child: ListTile(
                    title: Text(sale.description),
                    subtitle: Text(
                      '$modeLabel | Cliente: $customerLabel | Produto: $productLabel | ${sale.paymentMethod} | ${AppFormatters.time(sale.createdAt)}',
                    ),
                    trailing: SizedBox(
                      width: 130,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              AppFormatters.currency(sale.total),
                              textAlign: TextAlign.end,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cancelar venda concluida',
                            onPressed: () => _cancelCompletedSale(store, sale),
                            icon: const Icon(Icons.undo),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _SaleReceiptData {
  _SaleReceiptData({
    required this.description,
    required this.total,
    required this.paymentMethod,
    required this.customerName,
    required this.productName,
    required this.quantity,
    required this.createdAt,
  });
  final String description;
  final double total;
  final String paymentMethod;
  final String? customerName;
  final String? productName;
  final double? quantity;
  final DateTime createdAt;
}
