import 'package:flutter/material.dart';

import '../../core/auth_service.dart';
import 'screens/personal_finance_home_screen.dart';

class PersonalManagementScreen extends StatelessWidget {
  const PersonalManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pegar o UID do usuário atual
    final authService = AuthService();
    final uid = authService.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestão Pessoal')),
        body: const Center(
          child: Text('Usuário não autenticado'),
        ),
      );
    }

    return PersonalFinanceHomeScreen(uid: uid);
  }
}
