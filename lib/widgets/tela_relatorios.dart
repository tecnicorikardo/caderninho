import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/venda.dart';
import '../models/produto.dart';
import '../models/cliente.dart';

class TelaRelatorios extends StatefulWidget {
  const TelaRelatorios({super.key});

  @override
  State<TelaRelatorios> createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  final DatabaseService _db = DatabaseService.instance;
  
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dataFim = DateTime.now();
  
  bool _carregando = true;
  
  // Dados dos relatórios
  double _totalVendas = 0.0;
  int _numeroVendas = 0;
  double _ticketMedio = 0.0;
  final Map<FormaPagamento, double> _vendasPorFormaPagamento = {};
  List<MapEntry<Produto, int>> _produtosMaisVendidos = [];
  List<MapEntry<Cliente, double>> _melhoresClientes = [];
  final Map<DateTime, double> _vendasPorDia = {};

  @override
  void initState() {
    super.initState();
    _carregarRelatorios();
  }

  Future<void> _carregarRelatorios() async {
    setState(() => _carregando = true);
    
    try {
      final vendas = await _db.getVendas();
      
      // Filtrar vendas pelo período
      final vendasFiltradas = vendas.where((v) {
        // Normalizar as datas para comparar apenas dia/mês/ano
        final dataVenda = DateTime(v.dataVenda.year, v.dataVenda.month, v.dataVenda.day);
        final dataInicio = DateTime(_dataInicio.year, _dataInicio.month, _dataInicio.day);
        final dataFim = DateTime(_dataFim.year, _dataFim.month, _dataFim.day);
        
        // Verificar se a data da venda está no período (inclusive)
        // Usar comparação de milissegundos para evitar problemas de horário
        final estaNoPeriodo = (dataVenda.millisecondsSinceEpoch >= dataInicio.millisecondsSinceEpoch) && 
                              (dataVenda.millisecondsSinceEpoch <= dataFim.millisecondsSinceEpoch);
        
        return estaNoPeriodo;
      }).toList();
      
      _calcularEstatisticas(vendasFiltradas);
      
      setState(() {
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  void _calcularEstatisticas(List<Venda> vendas) {
    // Total e número de vendas
    _totalVendas = vendas.fold(0.0, (sum, v) => sum + v.total);
    _numeroVendas = vendas.length;
    _ticketMedio = _numeroVendas > 0 ? _totalVendas / _numeroVendas : 0.0;
    
    // Vendas por forma de pagamento
    _vendasPorFormaPagamento.clear();
    for (var venda in vendas) {
      _vendasPorFormaPagamento[venda.formaPagamento] = 
          (_vendasPorFormaPagamento[venda.formaPagamento] ?? 0.0) + venda.total;
    }
    
    // Produtos mais vendidos
    final produtosContador = <String, int>{};
    final produtosMap = <String, Produto>{};
    
    for (var venda in vendas) {
      for (var item in venda.itens) {
        produtosContador[item.produto.id] = 
            (produtosContador[item.produto.id] ?? 0) + item.quantidade;
        produtosMap[item.produto.id] = item.produto;
      }
    }
    
    _produtosMaisVendidos = produtosContador.entries
        .map((e) => MapEntry(produtosMap[e.key]!, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Melhores clientes
    final clientesTotal = <String, double>{};
    final clientesMap = <String, Cliente>{};
    
    for (var venda in vendas) {
      if (venda.cliente != null) {
        clientesTotal[venda.cliente!.id] = 
            (clientesTotal[venda.cliente!.id] ?? 0.0) + venda.total;
        clientesMap[venda.cliente!.id] = venda.cliente!;
      }
    }
    
    _melhoresClientes = clientesTotal.entries
        .map((e) => MapEntry(clientesMap[e.key]!, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Vendas por dia
    _vendasPorDia.clear();
    for (var venda in vendas) {
      final dia = DateTime(venda.dataVenda.year, venda.dataVenda.month, venda.dataVenda.day);
      _vendasPorDia[dia] = (_vendasPorDia[dia] ?? 0.0) + venda.total;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('📊 Relatórios'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selecionarPeriodo,
            tooltip: 'Selecionar Período',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Período selecionado
                  _buildPeriodoCard(),
                  const SizedBox(height: 16),
                  
                  // Cards de resumo
                  _buildCardsResumo(),
                  const SizedBox(height: 16),
                  
                  // Gráfico de vendas por forma de pagamento
                  _buildGraficoPagamento(),
                  const SizedBox(height: 16),
                  
                  // Top produtos
                  _buildTopProdutos(),
                  const SizedBox(height: 16),
                  
                  // Top clientes
                  _buildTopClientes(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Período Analisado',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${_formatarData(_dataInicio)} até ${_formatarData(_dataFim)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _selecionarPeriodo,
              child: const Text('Alterar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsResumo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCardResumo(
                icon: Icons.point_of_sale,
                titulo: 'Total de Vendas',
                valor: 'R\$ ${_totalVendas.toStringAsFixed(2)}',
                cor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardResumo(
                icon: Icons.shopping_cart,
                titulo: 'Número de Vendas',
                valor: _numeroVendas.toString(),
                cor: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCardResumo(
                icon: Icons.receipt,
                titulo: 'Ticket Médio',
                valor: 'R\$ ${_ticketMedio.toStringAsFixed(2)}',
                cor: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardResumo(
                icon: Icons.trending_up,
                titulo: 'Média por Dia',
                valor: 'R\$ ${(_totalVendas / (_vendasPorDia.length > 0 ? _vendasPorDia.length : 1)).toStringAsFixed(2)}',
                cor: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardResumo({
    required IconData icon,
    required String titulo,
    required String valor,
    required Color cor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: cor, size: 32),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoPagamento() {
    if (_vendasPorFormaPagamento.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💳 Vendas por Forma de Pagamento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._vendasPorFormaPagamento.entries.map((entry) {
              final porcentagem = (_totalVendas > 0) 
                  ? (entry.value / _totalVendas * 100) 
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getFormaPagamentoText(entry.key),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'R\$ ${entry.value.toStringAsFixed(2)} (${porcentagem.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: porcentagem / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCorFormaPagamento(entry.key),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProdutos() {
    if (_produtosMaisVendidos.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏆 Produtos Mais Vendidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._produtosMaisVendidos.take(5).map((entry) {
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    '${_produtosMaisVendidos.indexOf(entry) + 1}º',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(entry.key.nome),
                trailing: Text(
                  '${entry.value} ${entry.key.unidade}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopClientes() {
    if (_melhoresClientes.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⭐ Melhores Clientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getPeriodoText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._melhoresClientes.take(5).map((entry) {
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.withValues(alpha: 0.2),
                  child: Icon(
                    _melhoresClientes.indexOf(entry) == 0 
                        ? Icons.emoji_events
                        : Icons.person,
                    color: Colors.amber[700],
                  ),
                ),
                title: Text(entry.key.nome),
                trailing: Text(
                  'R\$ ${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _selecionarPeriodo() async {
    DateTime? novaDataInicio = _dataInicio;
    DateTime? novaDataFim = _dataFim;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('📅 Selecionar Período'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Períodos pré-definidos
                  const Text('Períodos rápidos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            novaDataFim = DateTime.now();
                            novaDataInicio = DateTime.now().subtract(const Duration(days: 7));
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('7 dias'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            novaDataFim = DateTime.now();
                            novaDataInicio = DateTime.now().subtract(const Duration(days: 15));
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('15 dias'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            novaDataFim = DateTime.now();
                            novaDataInicio = DateTime.now().subtract(const Duration(days: 30));
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('30 dias'),
                      ),
                      // Botão Mês Atual
                      ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            final agora = DateTime.now();
                            novaDataInicio = DateTime(agora.year, agora.month, 1);
                            novaDataFim = DateTime(agora.year, agora.month + 1, 0);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Mês Atual'),
                      ),
                      // Botão Ano Atual
                      ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            final agora = DateTime.now();
                            novaDataInicio = DateTime(agora.year, 1, 1);
                            novaDataFim = DateTime(agora.year, 12, 31);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Ano Atual'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Seleção manual
                  const Text('Período personalizado:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // Data início
                  ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.blue),
                    title: const Text('Data Início'),
                    subtitle: Text(novaDataInicio != null ? _formatarData(novaDataInicio!) : 'Selecionar'),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final data = await showDatePicker(
                        context: context,
                        initialDate: novaDataInicio ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: (novaDataFim != null && novaDataFim!.isAfter(DateTime(2020))) ? novaDataFim! : DateTime.now().add(const Duration(days: 365)),
                      );
                      if (data != null) {
                        setDialogState(() {
                          novaDataInicio = DateTime(data.year, data.month, data.day);
                          print('Data início alterada para: ${_formatarData(novaDataInicio!)}');
                        });
                      }
                    },
                  ),
                  
                  // Data fim
                  ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.green),
                    title: const Text('Data Fim'),
                    subtitle: Text(novaDataFim != null ? _formatarData(novaDataFim!) : 'Selecionar'),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final data = await showDatePicker(
                        context: context,
                        initialDate: novaDataFim ?? DateTime.now(),
                        firstDate: (novaDataInicio != null && novaDataInicio!.isAfter(DateTime(2020))) ? novaDataInicio! : DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (data != null) {
                        setDialogState(() {
                          novaDataFim = DateTime(data.year, data.month, data.day);
                          print('Data fim alterada para: ${_formatarData(novaDataFim!)}');
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Preview do período
                  if (novaDataInicio != null && novaDataFim != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Período: ${_formatarData(novaDataInicio!)} até ${_formatarData(novaDataFim!)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (novaDataInicio != null && novaDataFim != null) {
                    print('Aplicando período: ${_formatarData(novaDataInicio!)} até ${_formatarData(novaDataFim!)}');
                    setState(() {
                      _dataInicio = novaDataInicio!;
                      _dataFim = novaDataFim!;
                    });
                    Navigator.pop(context);
                    _carregarRelatorios();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecione as datas de início e fim!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getPeriodoText() {
    final agora = DateTime.now();
    final inicioMes = DateTime(agora.year, agora.month, 1);
    final fimMes = DateTime(agora.year, agora.month + 1, 0);
    final inicioAno = DateTime(agora.year, 1, 1);
    final fimAno = DateTime(agora.year, 12, 31);
    
    // Verificar se é o mês atual
    if (_dataInicio.year == inicioMes.year && 
        _dataInicio.month == inicioMes.month && 
        _dataInicio.day == inicioMes.day &&
        _dataFim.year == fimMes.year && 
        _dataFim.month == fimMes.month && 
        _dataFim.day == fimMes.day) {
      return 'Período: Mês Atual (${_formatarData(_dataInicio)} até ${_formatarData(_dataFim)})';
    }
    
    // Verificar se é o ano atual
    if (_dataInicio.year == inicioAno.year && 
        _dataInicio.month == inicioAno.month && 
        _dataInicio.day == inicioAno.day &&
        _dataFim.year == fimAno.year && 
        _dataFim.month == fimAno.month && 
        _dataFim.day == fimAno.day) {
      return 'Período: Ano Atual (${_formatarData(_dataInicio)} até ${_formatarData(_dataFim)})';
    }
    
    // Período personalizado
    return 'Período: ${_formatarData(_dataInicio)} até ${_formatarData(_dataFim)}';
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  String _getFormaPagamentoText(FormaPagamento forma) {
    switch (forma) {
      case FormaPagamento.dinheiro:
        return 'Dinheiro';
      case FormaPagamento.cartao:
        return 'Cartão';
      case FormaPagamento.pix:
        return 'PIX';
      case FormaPagamento.fiado:
        return 'Fiado';
    }
  }

  Color _getCorFormaPagamento(FormaPagamento forma) {
    switch (forma) {
      case FormaPagamento.dinheiro:
        return Colors.green;
      case FormaPagamento.cartao:
        return Colors.blue;
      case FormaPagamento.pix:
        return Colors.purple;
      case FormaPagamento.fiado:
        return Colors.orange;
    }
  }
} 