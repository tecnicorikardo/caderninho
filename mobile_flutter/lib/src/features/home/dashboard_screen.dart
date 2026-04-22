import 'package:flutter/material.dart';

import '../../core/app_formatters.dart';
import '../../core/app_store.dart';
import '../../core/auth_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/day_summary_modal.dart';
import 'widgets/fast_sale_modal.dart';
import 'widgets/module_tile.dart';

enum DashboardModule {
  vendas,
  fiados,
  dividas,
  financeiro,
  relatorios,
  configuracoes,
  produtos,
  clientes,
  minhaLoja,
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onOpenModule});

  final ValueChanged<DashboardModule> onOpenModule;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hideLowStockAlertUntilRelogin = false;

  List<ProductRecord> _lowStockProducts(AppStore store) {
    final low = store.products.where((p) => p.stock <= 5).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));
    return low;
  }

  int _moduleColumnCount(double width) {
    if (width >= 1500) return 5;
    if (width >= 1100) return 4;
    if (width >= 780) return 3;
    return 2;
  }

  double _moduleHeight(double width) {
    if (width >= 1100) return 132;
    if (width >= 780) return 140;
    return 148;
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final authService = AuthService();
    final userEmail = authService.currentUser?.email ?? '';
    final firstName = userEmail.split('@').first.split('.').first;
    final displayName = firstName.isNotEmpty 
        ? firstName[0].toUpperCase() + firstName.substring(1) 
        : 'Usuário';
    
    final now = DateTime.now();
    final date = AppFormatters.date(now);
    final salesCount = store.todaysSalesCount;
    final salesTotal = store.todaysSalesTotal;
    final fiadosCount = store.todaysFiadosCount;
    final fiadosOpen = store.todaysFiadosOpenTotal;
    final revenue = store.todayRevenue;
    final expense = store.todayExpense;
    final balance = store.todayBalance;
    final lowStock = _lowStockProducts(store);
    final screenWidth = MediaQuery.of(context).size.width;
    final moduleColumnCount = _moduleColumnCount(screenWidth);
    final moduleHeight = _moduleHeight(screenWidth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard do Dia'),
        actions: [
          Center(
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sair'),
                  content: const Text('Deseja realmente sair da conta?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                await authService.signOut();
              }
            },
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(date),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumo rapido',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vendas: $salesCount | Fiados: $fiadosCount | Saldo: ${AppFormatters.currency(balance)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_hideLowStockAlertUntilRelogin && lowStock.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Alerta: ${lowStock.length} produto(s) com estoque baixo (<= 5).',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar alerta',
                        onPressed: () {
                          setState(() {
                            _hideLowStockAlertUntilRelogin = true;
                          });
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...lowStock
                      .take(5)
                      .map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '- ${product.name}: ${product.stock.toStringAsFixed(2)} ${product.unit}',
                            style: const TextStyle(color: Color(0xFF78350F)),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text('Modulos'),
          const SizedBox(height: 10),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: moduleColumnCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: moduleHeight,
            ),
            children: [
              ModuleTile(
                icon: Icons.point_of_sale_outlined,
                title: 'Vendas',
                onTap: () => widget.onOpenModule(DashboardModule.vendas),
              ),
              ModuleTile(
                icon: Icons.receipt_long_outlined,
                title: 'Fiados',
                onTap: () => widget.onOpenModule(DashboardModule.fiados),
              ),
              ModuleTile(
                icon: Icons.savings_outlined,
                title: 'Financeiro',
                onTap: () => widget.onOpenModule(DashboardModule.financeiro),
              ),
              ModuleTile(
                icon: Icons.bar_chart_outlined,
                title: 'Relatorios',
                onTap: () => widget.onOpenModule(DashboardModule.relatorios),
              ),
              ModuleTile(
                icon: Icons.settings_outlined,
                title: 'Configuracoes',
                onTap: () => widget.onOpenModule(DashboardModule.configuracoes),
              ),
              ModuleTile(
                icon: Icons.inventory_2_outlined,
                title: 'Produtos',
                onTap: () => widget.onOpenModule(DashboardModule.produtos),
              ),
              ModuleTile(
                icon: Icons.people_outline,
                title: 'Clientes',
                onTap: () => widget.onOpenModule(DashboardModule.clientes),
              ),
              ModuleTile(
                icon: Icons.storefront_outlined,
                title: 'Minha Loja',
                onTap: () => widget.onOpenModule(DashboardModule.minhaLoja),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fast_sale_fab',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const FastSaleModal(),
              );
            },
            icon: const Icon(Icons.bolt, color: Colors.amber),
            label: const Text('Venda Rápida', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'summary_fab',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => DaySummaryModal(
                  salesCount: salesCount,
                  salesTotal: salesTotal,
                  fiadosCount: fiadosCount,
                  fiadosOpenTotal: fiadosOpen,
                  revenue: revenue,
                  expense: expense,
                  balance: balance,
                  onActionSelected: (module) {
                    Navigator.of(context).pop();
                    widget.onOpenModule(module);
                  },
                ),
              );
            },
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Resumo do Dia'),
          ),
        ],
      ),
    );
  }
}
