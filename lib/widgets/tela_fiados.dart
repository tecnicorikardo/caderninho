import 'package:flutter/material.dart';
import '../models/fiado.dart';
import '../models/cliente.dart';
import '../services/database_service.dart';
import '../services/whatsapp_service.dart';

class TelaFiados extends StatefulWidget {
  const TelaFiados({super.key});

  @override
  State<TelaFiados> createState() => _TelaFiadosState();
}

class _TelaFiadosState extends State<TelaFiados> {
  final DatabaseService _db = DatabaseService.instance;
  List<Fiado> _fiados = [];
  bool _carregando = true;
  String _filtro = 'todos'; // todos, pendentes, pagos, vencidos

  @override
  void initState() {
    super.initState();
    _carregarFiados();
  }

  Future<void> _carregarFiados() async {
    setState(() => _carregando = true);
    try {
      final fiados = await _db.getFiados();
      setState(() {
        _fiados = fiados;
        _carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar fiados: $e');
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar fiados: $e')),
        );
      }
    }
  }

  List<Fiado> get _fiadosFiltrados {
    switch (_filtro) {
      case 'pendentes':
        return _fiados.where((f) => f.status == StatusFiado.pendente).toList();
      case 'pagos':
        return _fiados.where((f) => f.status == StatusFiado.pago).toList();
      case 'vencidos':
        return _fiados.where((f) => f.estaVencido).toList();
      default:
        return _fiados;
    }
  }

  double get _totalPendente {
    return _fiados
        .where((f) => f.status != StatusFiado.pago)
        .fold(0.0, (sum, f) => sum + f.valorRestante);
  }

  Future<void> _registrarPagamento(Fiado fiado, double valor) async {
    try {
      final fiadoAtualizado = Fiado(
        id: fiado.id,
        cliente: fiado.cliente,
        valorTotal: fiado.valorTotal,
        valorPago: fiado.valorPago + valor,
        dataFiado: fiado.dataFiado,
        dataVencimento: fiado.dataVencimento,
        observacao: fiado.observacao,
      );
      
      await _db.atualizarFiado(fiadoAtualizado);
      await _carregarFiados();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fiadoAtualizado.status == StatusFiado.pago
                  ? 'Fiado quitado com sucesso!'
                  : 'Pagamento registrado com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar pagamento: $e')),
        );
      }
    }
  }

  Future<void> _excluirFiado(String id) async {
    try {
      await _db.deletarFiado(id);
      await _carregarFiados();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fiado excluído com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir fiado: $e')),
        );
      }
    }
  }

  void _mostrarModalPagamento(Fiado fiado) {
    final valorController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${fiado.cliente.nome}'),
            Text('Valor Total: R\$ ${fiado.valorTotal.toStringAsFixed(2)}'),
            Text('Valor Pago: R\$ ${fiado.valorPago.toStringAsFixed(2)}'),
            Text(
              'Valor Restante: R\$ ${fiado.valorRestante.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valorController,
              decoration: const InputDecoration(
                labelText: 'Valor do Pagamento',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(
                valorController.text.replaceAll(',', '.'),
              );
              
              if (valor == null || valor <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Digite um valor válido!'),
                  ),
                );
                return;
              }
              
              if (valor > fiado.valorRestante) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Valor maior que o restante!'),
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              _registrarPagamento(fiado, valor);
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _confirmarExcluir(Fiado fiado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Fiado'),
        content: Text(
          'Deseja excluir o fiado de ${fiado.cliente.nome}?\n'
          'Valor: R\$ ${fiado.valorTotal.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _excluirFiado(fiado.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('💰 Fiados'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarFiados,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumo e filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Card de resumo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Pendente',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'R\$ ${_totalPendente.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.account_balance_wallet,
                        size: 40,
                        color: Colors.white30,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filtros
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroChip('Todos', 'todos'),
                      const SizedBox(width: 8),
                      _buildFiltroChip('Pendentes', 'pendentes'),
                      const SizedBox(width: 8),
                      _buildFiltroChip('Pagos', 'pagos'),
                      const SizedBox(width: 8),
                      _buildFiltroChip('Vencidos', 'vencidos'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de fiados
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _fiadosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum fiado ${_filtro != "todos" ? _filtro : ""}',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _fiadosFiltrados.length,
                        itemBuilder: (context, index) {
                          final fiado = _fiadosFiltrados[index];
                          return _buildCardFiado(fiado);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label, String value) {
    final isSelected = _filtro == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filtro = value);
      },
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildCardFiado(Fiado fiado) {
    final porcentagemPaga = fiado.valorTotal > 0
        ? (fiado.valorPago / fiado.valorTotal).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(fiado).withValues(alpha: 0.1),
              child: Icon(
                _getStatusIcon(fiado),
                color: _getStatusColor(fiado),
              ),
            ),
            title: Text(
              fiado.cliente.nome,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Total: R\$ ${fiado.valorTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (fiado.dataVencimento != null)
                  Text(
                    'Vence: ${_formatarData(fiado.dataVencimento!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: fiado.estaVencido ? Colors.red : Colors.grey,
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${fiado.valorRestante.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(fiado),
                  ),
                ),
                Text(
                  _getStatusText(fiado),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(fiado),
                  ),
                ),
              ],
            ),
          ),
          
          // Barra de progresso
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: porcentagemPaga,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(fiado),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pago: R\$ ${fiado.valorPago.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${(porcentagemPaga * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Botões de ação
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (fiado.status != StatusFiado.pago)
                  TextButton.icon(
                    onPressed: () => _mostrarModalPagamento(fiado),
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Pagar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await WhatsAppService.enviarCobranca(fiado);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cobrança enviada!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Cobrar'),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'excluir') {
                      _confirmarExcluir(fiado);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(Fiado fiado) {
    if (fiado.status == StatusFiado.pago) return Colors.green;
    if (fiado.estaVencido) return Colors.red;
    if (fiado.status == StatusFiado.parcial) return Colors.orange;
    return Colors.blue;
  }

  IconData _getStatusIcon(Fiado fiado) {
    if (fiado.status == StatusFiado.pago) return Icons.check_circle;
    if (fiado.estaVencido) return Icons.error;
    if (fiado.status == StatusFiado.parcial) return Icons.timelapse;
    return Icons.schedule;
  }

  String _getStatusText(Fiado fiado) {
    if (fiado.status == StatusFiado.pago) return 'Pago';
    if (fiado.estaVencido) return 'Vencido';
    if (fiado.status == StatusFiado.parcial) return 'Parcial';
    return 'Pendente';
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }
} 