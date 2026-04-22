import 'package:flutter/material.dart';

import '../models/subscription_model.dart';

class SubscriptionBanner extends StatelessWidget {
  const SubscriptionBanner({
    required this.subscription,
    required this.onRenew,
    super.key,
  });

  final SubscriptionModel subscription;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    if (subscription.isExpired) {
      return _ExpiredBanner(onRenew: onRenew);
    }

    if (subscription.shouldShowWarning) {
      return _WarningBanner(
        daysRemaining: subscription.daysUntilExpiration,
        onRenew: onRenew,
      );
    }

    return const SizedBox.shrink();
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.daysRemaining,
    required this.onRenew,
  });

  final int daysRemaining;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade900),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              daysRemaining == 1
                  ? 'Sua assinatura expira amanhã!'
                  : 'Sua assinatura expira em $daysRemaining dias',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRenew,
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade900,
              backgroundColor: Colors.white,
            ),
            child: const Text('Renovar'),
          ),
        ],
      ),
    );
  }
}

class _ExpiredBanner extends StatelessWidget {
  const _ExpiredBanner({required this.onRenew});

  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.red.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade900),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Assinatura expirada. Renove para continuar usando.',
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: onRenew,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade900,
            ),
            child: const Text('Renovar Agora'),
          ),
        ],
      ),
    );
  }
}
