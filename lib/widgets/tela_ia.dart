import 'package:flutter/material.dart';
import '../services/ai_service_offline.dart';
import '../services/database_service.dart';
import '../core/app_colors.dart';

class TelaIA extends StatefulWidget {
  const TelaIA({super.key});

  @override
  State<TelaIA> createState() => _TelaIAState();
}

class _TelaIAState extends State<TelaIA> {
  final AIOfflineService _aiService = AIOfflineService();
  final DatabaseService _db = DatabaseService.instance;
  
  bool _isLoading = false;
  List<SugestaoIA> _sugestoes = [];
  AnaliseTendencias? _tendencias;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Carregando dados...';
    });

    try {
      final vendas = await _db.getVendas();
      
      if (vendas.isEmpty) {
        setState(() {
          _statusMessage = 'Nenhuma venda encontrada. Adicione vendas para obter análises de IA.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _statusMessage = 'Dados carregados: ${vendas.length} vendas';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _analisarVendas() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Analisando vendas com IA...';
    });

    try {
      final vendas = await _db.getVendas();
      final sugestoes = await _aiService.analisarVendas(vendas);
      
      setState(() {
        _sugestoes = sugestoes;
        _statusMessage = 'Análise concluída: ${sugestoes.length} sugestões encontradas';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro na análise: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _analisarTendencias() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Analisando tendências...';
    });

    try {
      final vendas = await _db.getVendas();
      final tendencias = await _aiService.analisarTendencias(vendas);
      
      setState(() {
        _tendencias = tendencias;
        _statusMessage = 'Análise de tendências concluída';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro na análise de tendências: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 IA Assistente'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Column(
        children: [
          // Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryLight.withValues(alpha: 0.1),
            child: Text(
              _statusMessage,
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Botões de ação
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _analisarVendas,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Analisar Vendas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _analisarTendencias,
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Tendências'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Processando com IA...'),
                ],
              ),
            ),

          // Conteúdo
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sugestões de IA
                  if (_sugestoes.isNotEmpty) ...[
                    _buildSecaoTitulo('💡 Sugestões da IA'),
                    const SizedBox(height: 12),
                    ..._sugestoes.map((sugestao) => _buildSugestaoCard(sugestao)),
                    const SizedBox(height: 24),
                  ],

                  // Análise de Tendências
                  if (_tendencias != null) ...[
                    _buildSecaoTitulo('📊 Análise de Tendências'),
                    const SizedBox(height: 12),
                    _buildTendenciasCard(_tendencias!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildSugestaoCard(SugestaoIA sugestao) {
    Color corTipo;
    IconData iconeTipo;
    
    switch (sugestao.tipo) {
      case 'estoque':
        corTipo = AppColors.warning;
        iconeTipo = Icons.inventory;
        break;
      case 'preco':
        corTipo = AppColors.info;
        iconeTipo = Icons.attach_money;
        break;
      case 'promocao':
        corTipo = AppColors.success;
        iconeTipo = Icons.local_offer;
        break;
      case 'cliente':
        corTipo = AppColors.primary;
        iconeTipo = Icons.people;
        break;
      default:
        corTipo = AppColors.grey600;
        iconeTipo = Icons.lightbulb;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconeTipo, color: corTipo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sugestao.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(sugestao.confianca * 100).toInt()}%',
                    style: TextStyle(
                      color: corTipo,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              sugestao.descricao,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTendenciasCard(AnaliseTendencias tendencias) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'Crescimento: ${tendencias.crescimentoVendas.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (tendencias.produtosEmAlta.isNotEmpty) ...[
              const Text(
                '📈 Produtos em Alta:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...tendencias.produtosEmAlta.map((produto) => 
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Text('• $produto'),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (tendencias.produtosEmBaixa.isNotEmpty) ...[
              const Text(
                '📉 Produtos em Baixa:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...tendencias.produtosEmBaixa.map((produto) => 
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Text('• $produto'),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (tendencias.insights.isNotEmpty) ...[
              const Text(
                '💡 Insights:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...tendencias.insights.entries.map((entry) => 
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Text('• ${entry.key}: ${entry.value}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 