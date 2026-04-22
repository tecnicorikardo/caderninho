import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_formatters.dart';
import '../../../theme/app_theme.dart';
import '../../shared/gradient_card.dart';
import '../controllers/personal_finance_controller.dart';
import '../models/personal_category.dart';
import '../models/personal_transaction.dart';
import '../services/personal_finance_service.dart';
import '../widgets/category_chart.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';
import 'personal_reports_screen.dart';
import 'transaction_form_screen.dart';
import 'transactions_list_screen.dart';

class PersonalFinanceHomeScreen extends StatefulWidget {
  const PersonalFinanceHomeScreen({super.key, required this.uid});

  final String uid;

  @override
  State<PersonalFinanceHomeScreen> createState() =>
      _PersonalFinanceHomeScreenState();
}

class _PersonalFinanceHomeScreenState extends State<PersonalFinanceHomeScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
        1,
      );
    });
    final controller = context.read<PersonalFinanceController>();
    controller.setMonthFilter(_selectedMonth);
  }

  Future<void> _showFilterDialog() async {
    final controller = context.read<PersonalFinanceController>();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Limpar filtros'),
              leading: const Icon(Icons.clear_all),
              onTap: () {
                controller.clearFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Apenas receitas'),
              leading: const Icon(Icons.arrow_upward, color: Colors.green),
              onTap: () {
                controller.setFilters(tipo: TipoTransacao.receita);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Apenas despesas'),
              leading: const Icon(Icons.arrow_downward, color: Colors.red),
              onTap: () {
                controller.setFilters(tipo: TipoTransacao.despesa);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Apenas pendentes'),
              leading: const Icon(Icons.schedule),
              onTap: () {
                controller.setFilters(status: StatusTransacao.pendente);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Apenas pagas'),
              leading: const Icon(Icons.check_circle),
              onTap: () {
                controller.setFilters(status: StatusTransacao.pago);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestão Financeira Pessoal'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Início'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Relatório'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filtros',
            ),
            IconButton(
              icon: const Icon(Icons.account_balance_wallet),
              onPressed: () {
                final controller = context.read<PersonalFinanceController>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: controller,
                      child: const AccountsScreen(),
                    ),
                  ),
                );
              },
              tooltip: 'Contas',
            ),
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: () {
                final controller = context.read<PersonalFinanceController>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: controller,
                      child: const CategoriesScreen(),
                    ),
                  ),
                );
              },
              tooltip: 'Categorias',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildHomeTab(),
            const PersonalReportsScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            final controller = context.read<PersonalFinanceController>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: controller,
                  child: const TransactionFormScreen(),
                ),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Nova Transação'),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Consumer<PersonalFinanceController>(
        builder: (context, controller, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Seletor de mês
              GradientCard(
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _changeMonth(-1),
                        ),
                        Text(
                          AppFormatters.monthYear(_selectedMonth),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => _changeMonth(1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card de resumo principal
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo Total',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppFormatters.currency(controller.totalBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Receitas',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              AppFormatters.currency(controller.totalReceitas),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Despesas',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              AppFormatters.currency(controller.totalDespesas),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contas
              if (controller.accounts.isNotEmpty) ...[
                const Text(
                  'Minhas Contas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...controller.accounts.map((account) {
                  final balance = controller.getAccountBalance(account.id);
                  return GradientCard(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.lightBlue.withOpacity(0.2),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: AppTheme.primary,
                          ),
                        ),
                        title: Text(account.nome),
                        subtitle: Text(
                          'Saldo inicial: ${AppFormatters.currency(account.saldoInicial)}',
                        ),
                        trailing: Text(
                          AppFormatters.currency(balance),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Próximas contas a vencer
              if (controller.proximasContas.isNotEmpty) ...[
                const Text(
                  'Próximas Contas (7 dias)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...controller.proximasContas.take(5).map((transaction) {
                  final category = controller.getCategoryById(
                    transaction.categoriaId,
                  );
                  return GradientCard(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(
                          category?.icone ?? Icons.attach_money,
                          color: category?.cor ?? AppTheme.primary,
                        ),
                        title: Text(transaction.nome),
                        subtitle: Text(
                          AppFormatters.date(transaction.dataPrevista),
                        ),
                        trailing: Text(
                          AppFormatters.currency(transaction.valor),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: transaction.tipo == TipoTransacao.receita
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Estatísticas rápidas
              Row(
                children: [
                  Expanded(
                    child: GradientCard(
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: AppTheme.accent,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${controller.transacoesPendentes}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Pendentes',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GradientCard(
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: AppTheme.accent,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${controller.accounts.length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Contas',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gráfico de categorias
              if (controller.transactions.isNotEmpty) ...[
                const Text(
                  'Análise por Categoria',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GradientCard(
                  child: CategoryChart(
                    transactions: controller.transactions,
                    categories: controller.categories,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botão ver todas as transações
              FilledButton.icon(
                onPressed: () {
                  final controller = context.read<PersonalFinanceController>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: controller,
                        child: const TransactionsListScreen(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('Ver Todas as Transações'),
              ),
            ],
          );
        },
      );
  }
}
