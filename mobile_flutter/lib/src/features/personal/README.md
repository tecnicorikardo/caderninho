# Módulo de Gestão Financeira Pessoal

## Estrutura Implementada

### Models
- ✅ `personal_category.dart` - Categorias personalizadas com ícones e cores
- ✅ `personal_account.dart` - Contas/carteiras
- ✅ `personal_transaction.dart` - Transações com suporte a parcelamento e recorrência

### Services
- ✅ `personal_finance_service.dart` - Lógica de negócio e integração com Firestore

### Controllers
- ✅ `personal_finance_controller.dart` - Gerenciamento de estado com ChangeNotifier

### Screens
- ✅ `personal_finance_home_screen.dart` - Tela principal com resumo
- ⏳ `accounts_screen.dart` - Gerenciar contas
- ⏳ `categories_screen.dart` - Gerenciar categorias
- ⏳ `transaction_form_screen.dart` - Formulário de transação
- ⏳ `transactions_list_screen.dart` - Lista completa de transações

## Funcionalidades Implementadas

### Contas
- Criar, editar e excluir contas
- Saldo automático calculado (saldoInicial + receitas - despesas)
- Apenas transações pagas afetam o saldo

### Categorias
- Categorias padrão inicializadas automaticamente
- Criar categorias personalizadas com ícone e cor
- Não permite excluir categoria com transações vinculadas

### Transações
- Suporte a receitas e despesas
- Parcelamento automático (cria N transações)
- Recorrência (cria 12 ocorrências futuras)
- Status: pendente ou pago
- Notificações (estrutura preparada)

### Filtros
- Por mês
- Por categoria
- Por conta
- Por tipo (receita/despesa)
- Por status (pendente/pago)

### Relatórios
- Resumo mensal
- Total por categoria
- Próximas contas a vencer
- Saldo total de todas as contas

## Firestore Collections

```
users/{uid}/
  ├── personal_accounts/
  ├── personal_categories/
  └── personal_transactions/
```

## Próximos Passos

1. Criar telas restantes (accounts, categories, forms, list)
2. Adicionar gráficos (pizza por categoria)
3. Implementar notificações push
4. Adicionar exportação de relatórios
5. Modo escuro

## Como Usar

```dart
// No home_shell ou router
final service = PersonalFinanceService(uid: currentUser.uid);
final controller = PersonalFinanceController(service: service);

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ChangeNotifierProvider.value(
      value: controller,
      child: PersonalFinanceHomeScreen(uid: currentUser.uid),
    ),
  ),
);
```
