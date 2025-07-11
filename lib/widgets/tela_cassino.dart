import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/casa_aposta.dart';
import '../models/deposito.dart';
import '../models/saque.dart';
import '../core/app_colors.dart';
import 'tela_casas_aposta.dart';
import 'tela_depositos.dart';
import 'tela_saques.dart';
import 'tela_relatorio_cassino.dart';

class TelaCassino extends StatefulWidget {
  const TelaCassino({super.key});

  @override
  State<TelaCassino> createState() => _TelaCassinoState();
}

class _TelaCassinoState extends State<TelaCassino> {
  final DatabaseService _db = DatabaseService.instance;
  bool _isLoading = true;
  
  // Dados do resumo
  double _totalDepositos = 0;
  double _totalSaques = 0;
  double _saldo = 0;
  int _totalCasas = 0;
  int _totalDepositosCount = 0;
  int _totalSaquesCount = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Carregar dados de resumo
      final casas = await _db.getCasasAposta();
      final depositos = await _db.getDepositos();
      final saques = await _db.getSaques();

      double totalDepositos = 0;
      double totalSaques = 0;

      for (var deposito in depositos) {
        totalDepositos += deposito.valor;
      }

      for (var saque in saques) {
        totalSaques += saque.valor;
      }

      setState(() {
        _totalDepositos = totalDepositos;
        _totalSaques = totalSaques;
        _saldo = totalSaques - totalDepositos;
        _totalCasas = casas.length;
        _totalDepositosCount = depositos.length;
        _totalSaquesCount = saques.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎰 Controle de Cassino'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumo principal
                    _buildResumoPrincipal(),
                    const SizedBox(height: 24),
                    
                    // Cards de navegação
                    _buildCardsNavegacao(),
                    const SizedBox(height: 24),
                    
                    // Últimas transações
                    _buildUltimasTransacoes(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarOpcoesAdicionar(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }

  Widget _buildResumoPrincipal() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.85),
            Colors.white.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo Financeiro',
                      style: TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_totalCasas} casa(s) de aposta',
                      style: const TextStyle(
                        color: Color(0xFF607080),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Saldo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _saldo >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: _saldo >= 0 ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Atual',
                        style: TextStyle(
                          color: Color(0xFF607080),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'R\$ ${_saldo.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Totais
          Row(
            children: [
              Expanded(
                child: _buildCardTotal(
                  'Depósitos',
                  _totalDepositos,
                  Icons.arrow_downward,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCardTotal(
                  'Saques',
                  _totalSaques,
                  Icons.arrow_upward,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardTotal(String titulo, double valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 16),
              const SizedBox(width: 4),
              Text(
                titulo,
                style: const TextStyle(
                  color: Color(0xFF607080),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsNavegacao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gerenciamento',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.adaptiveTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildCardNavegacao(
              '🏢 Casas de Aposta',
              'Gerenciar casas',
              Icons.business,
              AppColors.primary,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaCasasAposta()),
              ),
            ),
            _buildCardNavegacao(
              '💰 Depósitos',
              'Registrar depósitos',
              Icons.arrow_downward,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaDepositos()),
              ),
            ),
            _buildCardNavegacao(
              '💸 Saques',
              'Registrar saques',
              Icons.arrow_upward,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaSaques()),
              ),
            ),
            _buildCardNavegacao(
              '📊 Relatórios',
              'Análise financeira',
              Icons.analytics,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaRelatorioCassino()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardNavegacao(String titulo, String subtitulo, IconData icone, Color cor, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [cor.withValues(alpha: 0.1), cor.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: cor, size: 32),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.adaptiveTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 12,
                  color: context.adaptiveTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUltimasTransacoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estatísticas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.adaptiveTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildEstatistica(
                'Casas de Aposta',
                _totalCasas.toString(),
                Icons.business,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEstatistica(
                'Depósitos',
                _totalDepositosCount.toString(),
                Icons.arrow_downward,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEstatistica(
                'Saques',
                _totalSaquesCount.toString(),
                Icons.arrow_upward,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEstatistica(String titulo, String valor, IconData icone, Color cor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 24),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                color: context.adaptiveTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarOpcoesAdicionar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adicionar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.adaptiveTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.business, color: AppColors.primary),
              title: const Text('Nova Casa de Aposta'),
              subtitle: const Text('Cadastrar uma nova casa'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaCasasAposta()),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.green),
              title: const Text('Novo Depósito'),
              subtitle: const Text('Registrar um depósito'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaDepositos()),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.orange),
              title: const Text('Novo Saque'),
              subtitle: const Text('Registrar um saque'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaSaques()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 