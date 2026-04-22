import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';
import '../../core/subscription_middleware.dart';
import '../../core/utils/search_utils.dart';
import '../shared/gradient_card.dart';
import '../subscription/services/export_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _search = '';
  final TextEditingController _searchController = TextEditingController();
  final _subscriptionMiddleware = SubscriptionMiddleware();
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
    return error.toString();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _importCustomers(AppStore store) async {
    if (_isImporting) return;

    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'addCustomer',
    );
    if (!canAccess) return;

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
      debugPrint('[Customers][Import] Falha: $error');
      debugPrint('$stackTrace');
      _showMessage('Erro ao importar clientes: $error');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _addCustomer(AppStore store) async {
    // Verificar acesso antes de permitir adicionar
    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'addCustomer',
    );
    if (!canAccess) return;

    await _upsertCustomer(store: store);
  }

  Future<void> _editCustomer(AppStore store, CustomerRecord customer) async {
    // Verificar acesso antes de permitir editar
    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'updateCustomer',
    );
    if (!canAccess) return;

    await _upsertCustomer(store: store, customer: customer);
  }

  Future<void> _upsertCustomer({
    required AppStore store,
    CustomerRecord? customer,
  }) async {
    final isEditing = customer != null;
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Editar cliente' : 'Novo cliente'),
        content: Form(
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
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone (com DDD)',
                ),
              ),
            ],
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
    if (isEditing) {
      try {
        await store.updateCustomer(
          customerId: customer.id,
          name: nameController.text.trim(),
          phone: phoneController.text.trim(),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
      return;
    }

    try {
      await store.addCustomer(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cliente salvo.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  Future<void> _removeCustomer(AppStore store, CustomerRecord customer) async {
    // Verificar acesso antes de permitir remover
    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'removeCustomer',
    );
    if (!canAccess) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover cliente'),
        content: Text(
          'Se o cliente tiver fiados/emprestimos em aberto, ele sera inativado ao inves de excluido.\n\nContinuar com ${customer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    CustomerRemovalOutcome outcome;
    try {
      outcome = await store.removeCustomerWithPolicy(customer: customer);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      return;
    }
    if (!mounted) return;
    final text = outcome == CustomerRemovalOutcome.deleted
        ? 'Cliente excluido com sucesso.'
        : 'Cliente com pendencias foi inativado.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _reactivateCustomer(
    AppStore store,
    CustomerRecord customer,
  ) async {
    // Verificar acesso antes de permitir reativar
    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'reactivateCustomer',
    );
    if (!canAccess) return;

    await store.reactivateCustomer(customerId: customer.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cliente reativado.')));
  }

  Future<void> _showCustomerActions(
    AppStore store,
    CustomerRecord customer,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.history, size: 28),
            title: const Text('Ver historico'),
            onTap: () => Navigator.of(context).pop('history'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, size: 28),
            title: const Text('Editar'),
            onTap: () => Navigator.of(context).pop('edit'),
          ),
          if (!customer.isActive)
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined, size: 28),
              title: const Text('Reativar cliente'),
              onTap: () => Navigator.of(context).pop('reactivate'),
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline, size: 28),
            title: const Text('Excluir/Inativar'),
            onTap: () => Navigator.of(context).pop('remove'),
          ),
        ],
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'history') {
      await _openHistory(store, customer);
      return;
    }
    if (action == 'edit') {
      await _editCustomer(store, customer);
      return;
    }
    if (action == 'reactivate') {
      await _reactivateCustomer(store, customer);
      return;
    }
    if (action == 'remove') {
      await _removeCustomer(store, customer);
    }
  }

  List<CustomerRecord> _smartFilter(List<CustomerRecord> source) {
    final ordered = source.toList()
      ..sort((a, b) {
        if (a.isActive == b.isActive) return 0;
        return a.isActive ? -1 : 1;
      });

    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return ordered;

    final starts = <CustomerRecord>[];
    final contains = <CustomerRecord>[];
    final phone = <CustomerRecord>[];

    for (final customer in ordered) {
      final name = customer.name.toLowerCase();
      final number = customer.phone.toLowerCase();
      if (name.startsWith(query)) {
        starts.add(customer);
      } else if (name.contains(query)) {
        contains.add(customer);
      } else if (number.contains(query)) {
        phone.add(customer);
      }
    }

    return [...starts, ...contains, ...phone];
  }

  String _historyText(AppStore store, CustomerRecord customer) {
    final normalized = customer.name.trim().toLowerCase();
    final sales = store.sales
        .where(
          (sale) =>
              (sale.customerName ?? '').trim().toLowerCase() == normalized,
        )
        .toList();
    final debts = store.debts
        .where((debt) => debt.customerName.trim().toLowerCase() == normalized)
        .toList();
    final loans = store.loans
        .where((loan) => loan.customerName.trim().toLowerCase() == normalized)
        .toList();

    final salesTotal = sales.fold<double>(0, (acc, sale) => acc + sale.total);
    final debtOpen = debts.fold<double>(
      0,
      (acc, debt) => acc + debt.openAmount,
    );
    final loanOpen = loans.fold<double>(
      0,
      (acc, loan) => acc + store.getLoanOpenAmount(loan),
    );

    final lines = <String>[
      'Historico do cliente: ${customer.name}',
      'Telefone: ${customer.phone.isEmpty ? 'Nao cadastrado' : customer.phone}',
      '',
      'Resumo',
      '- Compras: ${sales.length} (${AppFormatters.currency(salesTotal)})',
      '- Fiados em aberto: ${AppFormatters.currency(debtOpen)}',
      '- Emprestimos em aberto: ${AppFormatters.currency(loanOpen)}',
      '',
      'Ultimas vendas',
    ];

    if (sales.isEmpty) {
      lines.add('- Nenhuma venda vinculada.');
    } else {
      for (final sale in sales.take(8)) {
        lines.add(
          '- ${AppFormatters.date(sale.createdAt)} ${AppFormatters.time(sale.createdAt)} | ${sale.description} | ${AppFormatters.currency(sale.total)} | ${sale.paymentMethod}',
        );
      }
    }

    lines.add('');
    lines.add('Fiados');
    if (debts.isEmpty) {
      lines.add('- Nenhum fiado.');
    } else {
      for (final debt in debts.take(8)) {
        final isPaid = debt.openAmount <= 0;
        final status = isPaid
            ? 'quitado'
            : 'aberto: ${AppFormatters.currency(debt.openAmount)}';
        lines.add('- ${debt.description} | $status');
      }
    }

    lines.add('');
    lines.add('Emprestimos');
    if (loans.isEmpty) {
      lines.add('- Nenhum emprestimo.');
    } else {
      for (final loan in loans.take(8)) {
        final open = store.getLoanOpenAmount(loan);
        lines.add(
          '- Venc.: ${AppFormatters.date(loan.dueDate)} | aberto: ${AppFormatters.currency(open)}',
        );
      }
    }

    return lines.join('\n');
  }

  String _normalizePhoneForWhatsapp(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('55')) return digits;
    if (digits.length == 10 || digits.length == 11) return '55$digits';
    return digits;
  }

  Future<void> _shareHistory(AppStore store, CustomerRecord customer) async {
    final text = _historyText(store, customer);
    final encodedText = Uri.encodeComponent(text);
    final phone = _normalizePhoneForWhatsapp(customer.phone);
    final url = phone.isEmpty
        ? 'https://wa.me/?text=$encodedText'
        : 'https://wa.me/$phone?text=$encodedText';

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel abrir o WhatsApp.')),
      );
    }
  }

  Future<void> _openHistory(AppStore store, CustomerRecord customer) async {
    final text = _historyText(store, customer);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Historico de ${customer.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(text),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _shareHistory(store, customer),
                  icon: const Icon(Icons.share),
                  label: const Text('Compartilhar no WhatsApp'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Historico copiado.')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadCustomerTemplate() async {
    try {
      await _exportService.exportCustomerTemplate();
    } catch (e) {
      if (mounted) _showMessage('Erro ao baixar modelo: $e');
    }
  }

  Future<void> _showSpreadsheetGuide() async {
    const guide = '''
Modelo de planilha - Clientes (CSV/XLSX)

Colunas obrigatorias:
1) nome

Colunas opcionais:
2) telefone

Exemplo:
nome,telefone
Ricardo,11999998888
Maria,21988887777

Regras:
- primeira linha deve ser o cabecalho
- telefone com DDD (somente numeros)
- um cliente por linha
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

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            tooltip: 'Modelo de planilha',
            onPressed: _showSpreadsheetGuide,
            icon: const Icon(Icons.table_chart_outlined),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final customers = _smartFilter(store.customers.toList());

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              GradientCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Importar clientes',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Importe uma planilha CSV/XLSX para cadastrar ou atualizar em lote.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _isImporting
                            ? null
                            : () => _importCustomers(store),
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
                              : 'Importar clientes agora',
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: _downloadCustomerTemplate,
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: const Text(
                          'Baixar modelo de planilha',
                          style: TextStyle(fontSize: 12),
                        ),
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
                    labelText: 'Busca inteligente por nome/telefone',
                    hintText: 'Ex.: Ricardo, Ric, 1199...',
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
              if (customers.isEmpty)
                const GradientCard(
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('Nenhum cliente encontrado.'),
                    ),
                  ),
                ),
              ...customers.map(
                (customer) => GradientCard(
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(customer.name)),
                          if (!customer.isActive)
                            const Chip(
                              label: Text('Inativo'),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      subtitle: Text(
                        customer.phone.isEmpty
                            ? 'Sem telefone'
                            : customer.phone,
                      ),
                      trailing: IconButton(
                        tooltip: 'Acoes',
                        onPressed: () => _showCustomerActions(store, customer),
                        icon: const Icon(Icons.more_vert),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCustomer(store),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Novo cliente'),
      ),
    );
  }
}
