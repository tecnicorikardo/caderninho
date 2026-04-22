import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_formatters.dart';
import 'models/plan_model.dart';
import 'models/subscription_model.dart';
import 'services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  SubscriptionModel? _currentSubscription;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final subscription = await _subscriptionService.checkStatus();
    if (mounted) {
      setState(() {
        _currentSubscription = subscription;
      });
    }
  }

  Future<void> _subscribe(PlanModel plan) async {
    setState(() => _isLoading = true);

    try {
      final result =
          await _subscriptionService.createPaymentPreference(plan.id);
      final initPoint = result['initPoint'] as String?;

      if (initPoint == null) {
        throw Exception('URL de pagamento não retornada');
      }

      // Abrir URL do Mercado Pago
      final uri = Uri.parse(initPoint);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir a página de pagamento'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar pagamento: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planos de Assinatura'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_currentSubscription != null) ...[
                  _CurrentPlanCard(subscription: _currentSubscription!),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'Escolha seu plano',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Acesso completo a todas as funcionalidades',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      // Desktop: 3 colunas
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: PlanModel.allPlans
                            .map(
                              (plan) => Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: _PlanCard(
                                    plan: plan,
                                    onSubscribe: () => _subscribe(plan),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    } else {
                      // Mobile: empilhado
                      return Column(
                        children: PlanModel.allPlans
                            .map(
                              (plan) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _PlanCard(
                                  plan: plan,
                                  onSubscribe: () => _subscribe(plan),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),
                const _FAQSection(),
              ],
            ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.subscription});

  final SubscriptionModel subscription;

  @override
  Widget build(BuildContext context) {
    final isExpired = subscription.isExpired;
    final daysRemaining = subscription.daysUntilExpiration;

    return Card(
      color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isExpired ? Icons.error_outline : Icons.check_circle_outline,
                  color: isExpired ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Plano Atual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isExpired ? Colors.red.shade900 : Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subscription.plan == SubscriptionPlan.free
                  ? 'Gratuito (Trial)'
                  : subscription.plan.name.toUpperCase(),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              isExpired
                  ? 'Expirado em ${AppFormatters.date(subscription.expirationDate)}'
                  : daysRemaining == 0
                      ? 'Expira hoje'
                      : 'Expira em $daysRemaining ${daysRemaining == 1 ? 'dia' : 'dias'}',
              style: TextStyle(
                color: isExpired ? Colors.red.shade700 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onSubscribe,
  });

  final PlanModel plan;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: plan.isPopular ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: plan.isPopular
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MAIS POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (plan.isPopular) const SizedBox(height: 12),
            Text(
              plan.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'R\$',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Text(
                  plan.price.toStringAsFixed(2).replaceAll('.', ','),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plan.description,
              style: const TextStyle(color: Colors.grey),
            ),
            if (plan.savings != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.savings!,
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _buildFeature('✓ Clientes ilimitados'),
            _buildFeature('✓ Produtos ilimitados'),
            _buildFeature('✓ Vendas ilimitadas'),
            _buildFeature('✓ Controle de fiados'),
            _buildFeature('✓ Gestão de empréstimos'),
            _buildFeature('✓ Relatórios completos'),
            _buildFeature('✓ Exportação de dados'),
            _buildFeature('✓ Suporte prioritário'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSubscribe,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: plan.isPopular
                      ? Theme.of(context).primaryColor
                      : null,
                ),
                child: const Text(
                  'Assinar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text),
    );
  }
}

class _FAQSection extends StatelessWidget {
  const _FAQSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perguntas Frequentes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFAQItem(
          'Como funciona o período gratuito?',
          'Novos usuários recebem automaticamente 2 meses de acesso gratuito a todas as funcionalidades.',
        ),
        _buildFAQItem(
          'Posso cancelar a qualquer momento?',
          'Sim! Não há fidelidade. Você pode cancelar quando quiser e continuar usando até o fim do período pago.',
        ),
        _buildFAQItem(
          'O que acontece se eu não renovar?',
          'Você ainda poderá visualizar seus dados e exportá-los, mas não poderá adicionar ou editar informações.',
        ),
        _buildFAQItem(
          'Como faço para exportar meus dados?',
          'Nas configurações, você encontrará opções para exportar clientes, produtos e relatórios em formato Excel.',
        ),
        _buildFAQItem(
          'Quais formas de pagamento são aceitas?',
          'Aceitamos cartão de crédito, PIX e boleto através do Mercado Pago.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
