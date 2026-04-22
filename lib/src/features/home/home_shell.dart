import 'package:flutter/material.dart';

import '../../core/auth_service.dart';
import '../../data/repositories/firestore_repository.dart';
import '../customers/customers_screen.dart';
import '../products/products_screen.dart';
import '../sales/sales_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.authService, required this.uid});

  final AuthService authService;
  final String uid;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final FirestoreRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = FirestoreRepository();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(uid: widget.uid, repository: _repo),
      const SalesScreen(),
      const CustomersScreen(),
      const ProductsScreen(),
      SettingsScreen(
        uid: widget.uid,
        repository: _repo,
        authService: widget.authService,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), label: 'Vendas'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Produtos'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Configurações'),
        ],
      ),
    );
  }
}
