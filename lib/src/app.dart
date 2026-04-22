import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/app_bootstrap.dart';
import 'core/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'theme/app_theme.dart';

class GestorComercialApp extends StatefulWidget {
  const GestorComercialApp({super.key});

  @override
  State<GestorComercialApp> createState() => _GestorComercialAppState();
}

class _GestorComercialAppState extends State<GestorComercialApp> {
  late final AuthService _auth;
  late final Future<BootstrapResult> _bootstrap;

  @override
  void initState() {
    super.initState();
    _auth = AuthService();
    _bootstrap = AppBootstrap.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor Comercial',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: FutureBuilder<BootstrapResult>(
        future: _bootstrap,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final bootstrap = snapshot.data!;
          if (!bootstrap.ok) {
            return _SetupErrorScreen(message: bootstrap.message ?? 'Falha ao iniciar Firebase.');
          }

          return StreamBuilder<User?>(
            stream: _auth.authChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              final user = authSnapshot.data;
              if (user == null) {
                return LoginScreen(authService: _auth);
              }

              return HomeShell(authService: _auth, uid: user.uid);
            },
          );
        },
      ),
    );
  }
}

class _SetupErrorScreen extends StatelessWidget {
  const _SetupErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text('Falha de inicializacao do Firebase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
