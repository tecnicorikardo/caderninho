import 'package:flutter/material.dart';

import '../../core/app_store.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _search = '';

  Future<void> _addCustomer(AppStore store) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo cliente'),
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
                decoration: const InputDecoration(labelText: 'Telefone'),
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

    store.addCustomer(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final customers = store.customers.where((c) {
            if (_search.isEmpty) return true;
            final q = _search.toLowerCase();
            return c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q);
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar por nome ou telefone',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _search = value.trim();
                  });
                },
              ),
              const SizedBox(height: 12),
              if (customers.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Nenhum cliente encontrado.'),
                  ),
                ),
              ...customers.map(
                (customer) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(customer.name),
                    subtitle: Text(customer.phone.isEmpty ? 'Sem telefone' : customer.phone),
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
