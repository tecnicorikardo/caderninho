import 'package:flutter/material.dart';

import '../customers/customers_screen.dart';
import '../debts/debts_screen.dart';
import '../finance/finance_screen.dart';
import '../products/products_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../sales/sales_screen.dart';
import '../store/store_screen.dart';
import '../subscription/services/subscription_service.dart';
import '../subscription/subscription_screen.dart';
import '../subscription/widgets/subscription_banner.dart';
import 'dashboard_screen.dart';
import '../fiados/fiados_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _subscriptionService = SubscriptionService();

  void _openModule(DashboardModule module) {
    switch (module) {
      case DashboardModule.vendas:
        setState(() => _index = 1);
        return;
      case DashboardModule.clientes:
        setState(() => _index = 2);
        return;
      case DashboardModule.produtos:
        setState(() => _index = 3);
        return;
      case DashboardModule.fiados:
        _openScreen(const FiadosScreen());
        return;
      case DashboardModule.dividas:
        _openScreen(const DebtsScreen());
        return;
      case DashboardModule.financeiro:
        _openScreen(const FinanceScreen());
        return;
      case DashboardModule.relatorios:
        _openScreen(const ReportsScreen());
        return;
      case DashboardModule.configuracoes:
        _openScreen(const SettingsScreen());
        return;
      case DashboardModule.minhaLoja:
        _openScreen(const StoreScreen());
        return;
    }
  }

  void _openFiadosFromSale() {
    _openModule(DashboardModule.fiados);
  }

  Future<void> _openScreen(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openSubscriptionScreen() {
    _openScreen(const SubscriptionScreen());
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onOpenModule: _openModule),
      SalesScreen(onFiadoSaleCreated: _openFiadosFromSale),
      const CustomersScreen(),
      const ProductsScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          // Banner de assinatura
          StreamBuilder(
            stream: _subscriptionService.getCurrentSubscription(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              return SubscriptionBanner(
                subscription: snapshot.data!,
                onRenew: _openSubscriptionScreen,
              );
            },
          ),
          // Conteúdo principal
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            label: 'Vendas',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Produtos',
          ),
        ],
      ),
    );
  }
}
