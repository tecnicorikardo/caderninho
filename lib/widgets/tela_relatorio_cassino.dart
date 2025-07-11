import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/casa_aposta.dart';
import '../core/app_colors.dart';

class TelaRelatorioCassino extends StatefulWidget {
  const TelaRelatorioCassino({super.key});

  @override
  State<TelaRelatorioCassino> createState() => _TelaRelatorioCassinoState();
}

class _TelaRelatorioCassinoState extends State<TelaRelatorioCassino> {
  final DatabaseService _db = DatabaseService.instance;
  bool _isLoading = true;
  
  // Filtros
  DateTime? _dataInicio;
  DateTime? _dataFim;
  CasaAposta? _casaSelecionada;
  List<CasaAposta> _casas = [];
  
  // Dados do relatório
  double _totalDepositos = 0;
  double _totalSaques = 0;
  double _saldo = 0;
  List<Map<String, dynamic>> _depositos = [];
  List<Map<String, dynamic>> _saques = [];

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

      final casas = await _db.getCasasAposta();
      setState(() {
        _casas = casas;
        _isLoading = false;
      });

      _gerarRelatorio();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  Future<void> _gerarRelatorio() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final relatorio = await _db.getRelatorioCassino(
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        casaApostaId: _casaSelecionada?.id,
      );

      setState(() {
        _totalDepositos = relatorio['totalDepositos'] as double;
        _totalSaques = relatorio['totalSaques'] as double;
        _saldo = relatorio['saldo'] as double;
        _depositos = relatorio['depositos'] as List<Map<String, dynamic>>;
        _saques = relatorio['saques'] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar relatório: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Relatório Cassino'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _limparFiltros,
            icon: const Icon(Icons.clear),
            tooltip: 'Limpar filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFiltros(),
          
          // Resumo
          _buildResumo(),
          
          // Lista de transações
          Expanded(child: _buildTransacoes()),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Datas
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Data Início'),
                  subtitle: Text(_dataInicio != null 
                      ? _formatarData(_dataInicio!) 
                      : 'Selecionar'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selecionarData(true),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text('Data Fim'),
                  subtitle: Text(_dataFim != null 
                      ? _formatarData(_dataFim!) 
                      : 'Selecionar'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selecionarData(false),
                ),
              ),
            ],
          ),
          
          // Casa de aposta
          DropdownButtonFormField<CasaAposta>(
            value: _casaSelecionada,
            decoration: const InputDecoration(
              labelText: 'Casa de Aposta (opcional)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<CasaAposta>(
                value: null,
                child: Text('Todas as casas'),
              ),
              ..._casas.map((casa) {
                return DropdownMenuItem<CasaAposta>(
                  value: casa,
                  child: Text(casa.nome),
                );
              }),
            ],
            onChanged: (CasaAposta? casa) {
              setState(() {
                _casaSelecionada = casa;
              });
              _gerarRelatorio();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Botão gerar relatório
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _gerarRelatorio,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Gerar Relatório'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Resumo do Período',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Saldo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _saldo >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'R\$ ${_saldo.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Totais
          Row(
            children: [
              Expanded(
                child: _buildCardResumo(
                  'Depósitos',
                  _totalDepositos,
                  Icons.arrow_downward,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCardResumo(
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

  Widget _buildCardResumo(String titulo, double valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 16),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransacoes() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Depósitos'),
              Tab(text: 'Saques'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildListaDepositos(),
                _buildListaSaques(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaDepositos() {
    if (_depositos.isEmpty) {
      return const Center(
        child: Text('Nenhum depósito encontrado'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _depositos.length,
      itemBuilder: (context, index) {
        final deposito = _depositos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              child: Icon(Icons.arrow_downward, color: Colors.green),
            ),
            title: Text(
              'R\$ ${(deposito['valor'] as num).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Data: ${_formatarData(DateTime.parse(deposito['data'] as String))}',
            ),
            trailing: Icon(
              (deposito['confirmado'] as int) == 1 ? Icons.check_circle : Icons.pending,
              color: (deposito['confirmado'] as int) == 1 ? Colors.green : Colors.orange,
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaSaques() {
    if (_saques.isEmpty) {
      return const Center(
        child: Text('Nenhum saque encontrado'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _saques.length,
      itemBuilder: (context, index) {
        final saque = _saques[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: Icon(Icons.arrow_upward, color: Colors.orange),
            ),
            title: Text(
              'R\$ ${(saque['valor'] as num).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Data: ${_formatarData(DateTime.parse(saque['data'] as String))}',
            ),
            trailing: Icon(
              (saque['confirmado'] as int) == 1 ? Icons.check_circle : Icons.pending,
              color: (saque['confirmado'] as int) == 1 ? Colors.green : Colors.orange,
            ),
          ),
        );
      },
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Future<void> _selecionarData(bool isInicio) async {
    final data = await showDatePicker(
      context: context,
      initialDate: isInicio ? (_dataInicio ?? DateTime.now()) : (_dataFim ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (data != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = data;
          // Se data fim é anterior à data início, limpar data fim
          if (_dataFim != null && _dataFim!.isBefore(data)) {
            _dataFim = null;
          }
        } else {
          _dataFim = data;
        }
      });
      // Atualizar relatório automaticamente
      _gerarRelatorio();
    }
  }

  void _limparFiltros() {
    setState(() {
      _dataInicio = null;
      _dataFim = null;
      _casaSelecionada = null;
    });
    _gerarRelatorio();
  }
} 