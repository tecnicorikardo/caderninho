import 'package:flutter/material.dart';

import '../../data/models/sale_model.dart';
import '../../data/repositories/firestore_repository.dart';
import '../fiados/fiados_screen.dart';
import '../finance/finance_screen.dart';
import '../loans/loans_screen.dart';
import '../reports/reports_screen.dart';
import '../sales/sales_screen.dart';
import '../shared/app_formatters.dart';
import '../shared/sync_status_chip.dart';
import 'widgets/day_summary_modal.dart';
import 'widgets/module_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.uid, required this.repository});

  final String uid;
  final FirestoreRepository repository;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayLabel = AppFormatters.brDate(now);
    final key = AppFormatters.dayKey(now);

    return StreamBuilder<List<SaleModel>>(
      stream: repository.watchSalesOfDay(uid, key),
      builder: (context, snapshot) {
        final sales = snapshot.data ?? const <SaleModel>[];
        final total = sales.fold<double>(0, (sum, s) => sum + s.total);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard do Dia'),
            actions: [
              SyncStatusChip(uid: uid),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(dayLabel),
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
                  gradient: const LinearGradient(colors: [Color(0xFF0EA5A4), Color(0xFF14B8A6)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumo rapido', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text(
                      'Vendas: ${sales.length} | Saldo: ${AppFormatters.currency(total)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Modulos'),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  ModuleTile(
                    icon: Icons.point_of_sale_outlined,
                    title: 'Vendas',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SalesScreen()),
                    ),
                  ),
                  ModuleTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Fiados',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FiadosScreen()),
                    ),
                  ),
                  ModuleTile(
                    icon: Icons.savings_outlined,
                    title: 'Financeiro',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FinanceScreen()),
                    ),
                  ),
                  ModuleTile(
                    icon: Icons.analytics_outlined,
                    title: 'Relatórios',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    ),
                  ),
                  ModuleTile(
                    icon: Icons.account_balance_outlined,
                    title: 'Empréstimos',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoansScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => DaySummaryModal(
                  salesCount: sales.length,
                  salesTotal: total,
                ),
              );
            },
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Resumo do Dia'),
          ),
        );
      },
    );
  }
}
