# Exemplo de Integração do Middleware de Assinatura

Este documento mostra como integrar o `SubscriptionMiddleware` nas telas existentes para bloquear ações de escrita quando a assinatura estiver expirada.

## 1. Importar o Middleware

```dart
import '../../core/subscription_middleware.dart';
```

## 2. Criar Instância do Middleware

Na classe State da sua tela:

```dart
class _CustomersScreenState extends State<CustomersScreen> {
  final _subscriptionMiddleware = SubscriptionMiddleware();
  // ... resto do código
}
```

## 3. Verificar Acesso Antes de Ações de Escrita

### Exemplo: Adicionar Cliente

```dart
Future<void> _addCustomer(AppStore store) async {
  // Verificar acesso antes de permitir adicionar
  final canAccess = await _subscriptionMiddleware.checkAccess(
    context,
    'addCustomer',
  );
  
  if (!canAccess) return; // Middleware já mostrou o modal
  
  // Continuar com a lógica normal
  await _upsertCustomer(store: store);
}
```

### Exemplo: Editar Cliente

```dart
Future<void> _editCustomer(AppStore store, CustomerRecord customer) async {
  // Verificar acesso antes de permitir editar
  final canAccess = await _subscriptionMiddleware.checkAccess(
    context,
    'updateCustomer',
  );
  
  if (!canAccess) return;
  
  await _upsertCustomer(store: store, customer: customer);
}
```

## 4. Ações que Devem Ser Verificadas

O middleware identifica automaticamente as seguintes ações como "escrita":

- `addCustomer` - Adicionar cliente
- `updateCustomer` - Editar cliente
- `addProduct` - Adicionar produto
- `updateProduct` - Editar produto
- `registerSale` - Registrar venda
- `addDebt` - Adicionar fiado
- `addLoan` - Adicionar empréstimo
- `addExpense` - Adicionar despesa
- `addIncome` - Adicionar receita

## 5. Telas que Precisam de Integração

### CustomersScreen
- `_addCustomer()` → `addCustomer`
- `_editCustomer()` → `updateCustomer`

### ProductsScreen
- `_addProduct()` → `addProduct`
- `_editProduct()` → `updateProduct`

### SalesScreen
- `_registerSale()` → `registerSale`

### FiadosScreen
- `_addDebt()` → `addDebt`

### LoansScreen
- `_addLoan()` → `addLoan`

### FinanceScreen
- `_addExpense()` → `addExpense`
- `_addIncome()` → `addIncome`

## 6. Exemplo Completo

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_store.dart';
import '../../core/subscription_middleware.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _subscriptionMiddleware = SubscriptionMiddleware();
  
  Future<void> _addCustomer(AppStore store) async {
    // Verificar acesso
    final canAccess = await _subscriptionMiddleware.checkAccess(
      context,
      'addCustomer',
    );
    
    if (!canAccess) return;
    
    // Lógica de adicionar cliente
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
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
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    
    if (shouldSave != true) return;
    
    try {
      await store.addCustomer(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente salvo.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $error')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: ListView(
        children: [
          // Lista de clientes
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCustomer(store),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Novo cliente'),
      ),
    );
  }
}
```

## 7. Comportamento do Middleware

Quando a assinatura está expirada e o usuário tenta executar uma ação de escrita:

1. O middleware intercepta a ação
2. Verifica o status da assinatura
3. Se expirada, mostra um modal explicativo
4. O modal informa o que o usuário ainda pode fazer (visualizar e exportar)
5. Oferece botão "Renovar Agora" que leva para a tela de assinatura
6. A ação original é bloqueada

## 8. Ações de Leitura

Ações de leitura (visualizar, buscar, filtrar) NÃO são bloqueadas pelo middleware e continuam funcionando normalmente mesmo com assinatura expirada.
