import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/app_store.dart';
import 'core/auth_service.dart';
import 'core/firebase_bootstrap.dart';
import 'core/push_notification_service.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'features/store/store_setup_screen.dart';
import 'features/vitrine/vitrine_page.dart';
import 'theme/app_theme.dart';

class GestorComercialApp extends StatefulWidget {
  const GestorComercialApp({super.key});

  @override
  State<GestorComercialApp> createState() => _GestorComercialAppState();
}

class _GestorComercialAppState extends State<GestorComercialApp> {
  late final Future<FirebaseBootstrapResult> _bootstrapFuture;
  AuthService? _authService;
  final PushNotificationService _pushNotificationService =
      PushNotificationService();
  AppStore? _store;
  String? _storeUid;

  @override
  void initState() {
    super.initState();
    PushNotificationService.registerBackgroundHandler();
    _bootstrapFuture = FirebaseBootstrap.initialize();
  }

  void _ensureStore(String uid) {
    if (_storeUid == uid && _store != null) return;
    _store?.dispose();
    _store = AppStore(uid: uid);
    _storeUid = uid;
  }

  @override
  void dispose() {
    _store?.dispose();
    _pushNotificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseBootstrapResult>(
      future: _bootstrapFuture,
      builder: (context, bootstrapSnapshot) {
        if (!bootstrapSnapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const SplashScreen(),
          );
        }

        final bootstrap = bootstrapSnapshot.data!;
        if (!bootstrap.ok) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Falha ao conectar no Firebase:\n${bootstrap.message ?? 'Erro desconhecido'}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        final authService = _authService ??= AuthService();

        return StreamBuilder<User?>(
          stream: authService.authChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                home: const SplashScreen(),
              );
            }

            final user = authSnapshot.data;
            if (user != null) {
              _ensureStore(user.uid);
              unawaited(_pushNotificationService.configureForUser(user.uid));
            } else {
              _store?.dispose();
              _store = null;
              _storeUid = null;
              unawaited(_pushNotificationService.clearUserContext());
            }

            final home = user == null
                ? LoginScreen(authService: authService)
                : const _HomeOrSetup();
            final initialLocation = Uri.base.path.isEmpty || Uri.base.path == '/' 
                ? '/' 
                : Uri.base.path;

            final router = GoRouter(
              initialLocation: initialLocation,
              routerNeglect: true,
              routes: [
                GoRoute(path: '/', builder: (_, __) => home),
                GoRoute(
                  path: '/:slug',
                  builder: (context, state) {
                    final slug = state.pathParameters['slug'] ?? '';
                    return VitrinePage(slug: slug);
                  },
                ),
                GoRoute(
                  path: '/vitrine/:slug',
                  builder: (context, state) {
                    final slug = state.pathParameters['slug'] ?? '';
                    return VitrinePage(slug: slug);
                  },
                ),
              ],
            );

            final app = MaterialApp.router(
              title: 'Gestor Comercial',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              routerConfig: router,
              builder: (context, child) {
                if (_store == null || child == null) {
                  return child ?? const SizedBox.shrink();
                }
                return AppStoreScope(store: _store!, child: child);
              },
            );

            return app;
          },
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ColoredBox(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Image(
              image: AssetImage('assets/images/splash-screen.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

/// Decide entre mostrar o setup da loja ou o app principal.
class _HomeOrSetup extends StatefulWidget {
  const _HomeOrSetup();

  @override
  State<_HomeOrSetup> createState() => _HomeOrSetupState();
}

class _HomeOrSetupState extends State<_HomeOrSetup> {
  bool _setupDone = false;

  @override
  Widget build(BuildContext context) {
    if (_setupDone) return const HomeShell();

    return ListenableBuilder(
      listenable: AppStoreScope.of(context),
      builder: (context, _) {
        final store = AppStoreScope.of(context);
        final hasStore = store.shopProfile.storeName.isNotEmpty;

        if (hasStore || _setupDone) {
          return const HomeShell();
        }

        return StoreSetupScreen(
          onComplete: () => setState(() => _setupDone = true),
        );
      },
    );
  }
}
