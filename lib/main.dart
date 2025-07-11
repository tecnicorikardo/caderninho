import 'package:flutter/material.dart';
import 'widgets/tela_nova_venda.dart';
import 'widgets/tela_clientes.dart';
import 'widgets/tela_estoque.dart';
import 'widgets/tela_fiados.dart';
import 'widgets/tela_relatorios.dart';
import 'widgets/tela_configuracoes.dart';
import 'widgets/tela_contas.dart';
import 'widgets/tela_agenda.dart';
import 'widgets/tela_login.dart';
import 'widgets/tela_trial.dart';
import 'widgets/aviso_trial_widget.dart';
import 'widgets/tela_ia.dart';
import 'widgets/tela_cassino.dart';
import 'services/database_service.dart';
import 'services/config_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/agenda_service.dart';
import 'services/trial_service.dart';
import 'core/app_colors.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    // Para web, usar sqflite_common_ffi_web
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    // Para desktop, usar sqflite_common_ffi
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Inicializar serviços
  await DatabaseService.instance.inicializar();
  await NotificationService.instance.inicializar();
  await AuthService.instance.inicializar();
  await TrialService.instance.inicializar();
  
  // Verificar notificações pendentes da agenda
  try {
    await AgendaService().verificarNotificacoesPendentes();
  } catch (e) {
    debugPrint('Erro ao verificar notificações da agenda: $e');
  }
  
  runApp(const CaderninhoApp());
}

class CaderninhoApp extends StatefulWidget {
  const CaderninhoApp({super.key});

  @override
  State<CaderninhoApp> createState() => _CaderninhoAppState();
}

class _CaderninhoAppState extends State<CaderninhoApp> {
  final ConfigService _configService = ConfigService.instance;
  final AuthService _authService = AuthService.instance;
  final TrialService _trialService = TrialService.instance;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _carregarTema();
    // Escutar mudanças no tema
    _configService.addListener(_onTemaAlterado);
  }

  @override
  void dispose() {
    _configService.removeListener(_onTemaAlterado);
    super.dispose();
  }

  void _onTemaAlterado() {
    setState(() {
      _themeMode = _configService.getThemeMode();
    });
  }

  Future<void> _carregarTema() async {
    await _configService.carregarConfiguracoes();
    setState(() {
      _themeMode = _configService.getThemeMode();
    });
  }

  Widget _getTelaInicial() {
    // Se não estiver logado, vai para login
    if (!_authService.isLoggedIn) {
      return const TelaLogin();
    }
    
    // Se trial expirado, vai para tela de trial
    if (_trialService.isTrialExpirado) {
      return const TelaTrialExperiencia();
    }
    
    // Caso contrário, vai para tela principal
    return const TelaPrincipal();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caderninho do Comerciante',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.background,
        
        // ✅ TEMA DE CORES LIMPO E CONSISTENTE
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
          bodySmall: TextStyle(color: AppColors.textHint),
        ),
        
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryLight,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF121212),
        
        // ✅ TEMA ESCURO MELHORADO COM MELHOR CONTRASTE
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
          bodySmall: TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
        ),
        
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        cardTheme: CardThemeData(
          color: const Color(0xFF2D2D2D),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // Melhorar cores de input
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D2D2D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF424242)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF424242)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFFBDBDBD)),
          hintStyle: const TextStyle(color: Color(0xFF757575)),
        ),
        
        // Melhorar cores de ícones
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        
        // Melhorar cores de divisores
        dividerTheme: const DividerThemeData(
          color: Color(0xFF424242),
          thickness: 1,
        ),
        
        // Melhorar cores de list tiles
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white,
        ),
      ),
      home: _getTelaInicial(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  final DatabaseService _db = DatabaseService.instance;
  
  // Variáveis de estado para o resumo
  double vendasHoje = 0.0;
  double fiadosPendentes = 0.0;
  int estoqueBaixo = 0;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _atualizarResumo();
  }

  Future<void> _atualizarResumo() async {
    setState(() {
      _carregando = true;
    });

    try {
      vendasHoje = await _db.getVendasHoje();
      fiadosPendentes = await _db.getFiadosPendentes();
      estoqueBaixo = await _db.getEstoqueBaixo();
      
      setState(() {
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar resumo: $e');
      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caderninho do Comerciante'),
        actions: [
            const InfoTrialWidget(),
            const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _fazerLogout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com boas-vindas
              _buildCabecalho(),
              const SizedBox(height: 30),
              
              // Aviso de trial (se necessário)
              const AvisoTrialWidget(),
              
              // Resumo do dia
              _buildResumoDia(),
              const SizedBox(height: 40),
              
              // Botões de ação
              _buildBotoesAcao(),
              const SizedBox(height: 30),
              
              // Rodapé
              _buildRodape(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Atualiza o resumo quando a tela volta a ser exibida
    _atualizarResumo();
  }

  Widget _buildCabecalho() {
    final usuario = AuthService.instance.usuarioAtual;
    final saudacao = usuario != null
        ? 'Bem-vindo ao seu caderninho, ${usuario.nome.split(' ').first}!'
        : 'Seja Bem-Vindo ao';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.store,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    saudacao,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    'Caderninho do Comerciante',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResumoDia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Resumo do Dia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: _atualizarResumo,
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar resumo',
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_carregando) ...[
          const Center(
            child: CircularProgressIndicator(),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: _buildCardResumo(
                  'Vendas Hoje',
                  'R\$ ${vendasHoje.toStringAsFixed(2)}',
                  Icons.shopping_cart,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildCardResumo(
                  'Fiados Pendentes',
                  'R\$ ${fiadosPendentes.toStringAsFixed(2)}',
                  Icons.pending,
                  AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildCardResumo(
                  'Estoque Baixo',
                  '$estoqueBaixo produtos',
                  Icons.warning,
                  AppColors.error,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildCardResumo(
                  'Status',
                  'Sistema OK',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCardResumo(String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icone,
                color: cor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotoesAcao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.1,
          children: [
            _buildBotaoAcao(
              'Nova Venda',
              Icons.add_shopping_cart,
              AppColors.primary,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaNovaVenda()),
              ),
            ),
            _buildBotaoAcao(
              'Clientes',
              Icons.people,
              AppColors.info,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaClientes()),
              ),
            ),
            _buildBotaoAcao(
              'Estoque',
              Icons.inventory,
              AppColors.warning,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaEstoque()),
              ),
            ),
            _buildBotaoAcao(
              'Fiados',
              Icons.pending,
              AppColors.error,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaFiados()),
              ),
            ),
            _buildBotaoAcao(
              'Relatórios',
              Icons.analytics,
              AppColors.success,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaRelatorios()),
              ),
            ),
            _buildBotaoAcao(
              'Agenda',
              Icons.calendar_today,
              AppColors.primaryLight,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaAgenda()),
              ),
            ),
            _buildBotaoAcao(
              'Contas',
              Icons.account_balance,
              AppColors.info,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaContas()),
              ),
            ),
            _buildBotaoAcao(
              'IA Assistente',
              Icons.psychology,
              AppColors.warning,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaIA()),
              ),
            ),
            _buildBotaoAcao(
              'Cassino',
              Icons.casino,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaCassino()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBotaoAcao(String titulo, IconData icone, Color cor, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icone,
                  color: cor,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRodape() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Configurações',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildBotaoConfiguracao(
                  'Configurações',
                  Icons.settings,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TelaConfiguracoes()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoConfiguracao(String titulo, IconData icone, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(
              icone,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _fazerLogout() {
    AuthService.instance.fazerLogout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TelaLogin()),
    );
  }
}


