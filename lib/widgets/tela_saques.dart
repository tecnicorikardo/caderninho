import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/saque.dart';
import '../models/casa_aposta.dart';
import '../models/deposito.dart';
import '../core/app_colors.dart';

class TelaSaques extends StatefulWidget {
  const TelaSaques({super.key});

  @override
  State<TelaSaques> createState() => _TelaSaquesState();
}

class _TelaSaquesState extends State<TelaSaques> {
  final DatabaseService _db = DatabaseService.instance;
  List<Saque> _saques = [];
  List<CasaAposta> _casas = [];
  bool _isLoading = true;

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

      final saques = await _db.getSaques();
      final casas = await _db.getCasasAposta();

      setState(() {
        _saques = saques;
        _casas = casas;
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
        title: const Text('💸 Saques'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _saques.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _saques.length,
                  itemBuilder: (context, index) {
                    final saque = _saques[index];
                    return _buildSaqueCard(saque);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarSaque,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_upward_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum saque registrado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para adicionar um saque',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaqueCard(Saque saque) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          child: Icon(
            Icons.arrow_upward,
            color: Colors.orange,
          ),
        ),
        title: Text(
          saque.casaAposta.nome,
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
              'R\$ ${saque.valor.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Método: ${saque.metodoPagamentoText}',
              style: TextStyle(
                color: context.adaptiveTextSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Data: ${_formatarData(saque.data)}',
              style: TextStyle(
                color: context.adaptiveTextSecondary,
                fontSize: 12,
              ),
            ),
            if (saque.observacoes != null) ...[
              const SizedBox(height: 4),
              Text(
                'Obs: ${saque.observacoes}',
                style: TextStyle(
                  color: context.adaptiveTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  saque.confirmado ? Icons.check_circle : Icons.pending,
                  color: saque.confirmado ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  saque.confirmado ? 'Confirmado' : 'Pendente',
                  style: TextStyle(
                    color: saque.confirmado ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, saque),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: saque.confirmado ? 'unconfirm' : 'confirm',
              child: Row(
                children: [
                  Icon(
                    saque.confirmado ? Icons.pending : Icons.check_circle,
                    color: saque.confirmado ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(saque.confirmado ? 'Desconfirmar' : 'Confirmar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  void _handleMenuAction(String action, Saque saque) {
    switch (action) {
      case 'edit':
        _editarSaque(saque);
        break;
      case 'confirm':
      case 'unconfirm':
        _alterarConfirmacao(saque);
        break;
      case 'delete':
        _excluirSaque(saque);
        break;
    }
  }

  void _adicionarSaque() {
    if (_casas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primeiro cadastre uma casa de aposta!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _mostrarDialogoSaque();
  }

  void _editarSaque(Saque saque) {
    _mostrarDialogoSaque(saque: saque);
  }

  void _mostrarDialogoSaque({Saque? saque}) {
    CasaAposta? casaSelecionada = saque?.casaAposta ?? (_casas.isNotEmpty ? _casas.first : null);
    final valorController = TextEditingController(text: saque?.valor.toString() ?? '');
    final observacoesController = TextEditingController(text: saque?.observacoes ?? '');
    MetodoPagamento metodoSelecionado = saque?.metodoPagamento ?? MetodoPagamento.pix;
    DateTime dataSelecionada = saque?.data ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(saque == null ? 'Novo Saque' : 'Editar Saque'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seletor de casa
                DropdownButtonFormField<CasaAposta>(
                  value: casaSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Casa de Aposta',
                    border: OutlineInputBorder(),
                  ),
                  items: _casas.map((casa) {
                    return DropdownMenuItem<CasaAposta>(
                      value: casa,
                      child: Text(casa.nome),
                    );
                  }).toList(),
                  onChanged: (CasaAposta? casa) {
                    setState(() {
                      casaSelecionada = casa;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Valor
                TextField(
                  controller: valorController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor (R\$)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Método de pagamento
                DropdownButtonFormField<MetodoPagamento>(
                  value: metodoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Método de Pagamento',
                    border: OutlineInputBorder(),
                  ),
                  items: MetodoPagamento.values.map((metodo) {
                    return DropdownMenuItem<MetodoPagamento>(
                      value: metodo,
                      child: Text(_getMetodoPagamentoText(metodo)),
                    );
                  }).toList(),
                  onChanged: (MetodoPagamento? metodo) {
                    setState(() {
                      metodoSelecionado = metodo!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Data
                ListTile(
                  title: const Text('Data'),
                  subtitle: Text(_formatarData(dataSelecionada)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: dataSelecionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (data != null) {
                      setState(() {
                        dataSelecionada = data;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Observações
                TextField(
                  controller: observacoesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                    border: OutlineInputBorder(),
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
              onPressed: () async {
                if (casaSelecionada == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecione uma casa de aposta!')),
                  );
                  return;
                }

                final valor = double.tryParse(valorController.text);
                if (valor == null || valor <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Digite um valor válido!')),
                  );
                  return;
                }

                try {
                  final novoSaque = Saque(
                    id: saque?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    casaAposta: casaSelecionada!,
                    valor: valor,
                    metodoPagamento: metodoSelecionado,
                    data: dataSelecionada,
                    observacoes: observacoesController.text.trim().isEmpty 
                        ? null 
                        : observacoesController.text.trim(),
                    confirmado: saque?.confirmado ?? true,
                  );

                  if (saque == null) {
                    await _db.inserirSaque(novoSaque);
                  } else {
                    await _db.atualizarSaque(novoSaque);
                  }

                  Navigator.pop(context);
                  _carregarDados();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(saque == null ? 'Saque adicionado!' : 'Saque atualizado!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text(saque == null ? 'Adicionar' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMetodoPagamentoText(MetodoPagamento metodo) {
    switch (metodo) {
      case MetodoPagamento.pix:
        return 'PIX';
      case MetodoPagamento.cartao_credito:
        return 'Cartão de Crédito';
      case MetodoPagamento.cartao_debito:
        return 'Cartão de Débito';
      case MetodoPagamento.transferencia:
        return 'Transferência';
      case MetodoPagamento.dinheiro:
        return 'Dinheiro';
      default:
        return 'Desconhecido';
    }
  }

  void _alterarConfirmacao(Saque saque) async {
    try {
      final novoSaque = saque.copyWith(confirmado: !saque.confirmado);
      await _db.atualizarSaque(novoSaque);
      _carregarDados();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saque.confirmado ? 'Saque desconfirmado!' : 'Saque confirmado!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  void _excluirSaque(Saque saque) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o saque de R\$ ${saque.valor.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _db.deletarSaque(saque.id);
        _carregarDados();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saque excluído!'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
} 