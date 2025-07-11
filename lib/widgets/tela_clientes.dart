import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cliente.dart';
import '../models/venda.dart';
import '../models/produto.dart';
import '../services/whatsapp_service.dart';
import '../services/database_service.dart';

class TelaClientes extends StatefulWidget {
  const TelaClientes({super.key});

  @override
  State<TelaClientes> createState() => _TelaClientesState();
}

class _TelaClientesState extends State<TelaClientes> {
  final DatabaseService _db = DatabaseService.instance;
  List<Cliente> _clientes = [];
  List<Cliente> _clientesFiltrados = [];
  bool _carregando = true;
  String _busca = '';
  final _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarClientes() async {
    setState(() => _carregando = true);
    final clientes = await _db.getClientes();
    setState(() {
      _clientes = clientes;
      _filtrarClientes(); // Sempre aplica o filtro, mesmo se o campo estiver vazio
      _carregando = false;
    });
  }

  void _filtrarClientes() {
    final texto = _buscaController.text.toLowerCase().trim();
    
    if (texto.isEmpty) {
      _clientesFiltrados = List.from(_clientes);
    } else {
      _clientesFiltrados = _clientes.where((c) {
        final nomeMatch = c.nome.toLowerCase().contains(texto);
        final telefoneMatch = c.telefone != null && 
                             c.telefone!.replaceAll(RegExp(r'\D'), '').contains(texto.replaceAll(RegExp(r'\D'), ''));
        return nomeMatch || telefoneMatch;
      }).toList();
    }
  }

  Future<void> _adicionarCliente(Cliente cliente) async {
    try {
      await _db.inserirCliente(cliente);
      await _carregarClientes();
    } catch (e) {
      // Comentado para produção: print('Erro ao adicionar cliente: $e');
    }
  }

  Future<void> _editarCliente(Cliente cliente) async {
    try {
      await _db.atualizarCliente(cliente);
      await _carregarClientes();
    } catch (e) {
      // Comentado para produção: print('Erro ao editar cliente: $e');
    }
  }

  Future<void> _excluirCliente(String id) async {
    try {
      await _db.deletarCliente(id);
      await _carregarClientes();
    } catch (e) {
      // Comentado para produção: print('Erro ao excluir cliente: $e');
    }
  }

  void _abrirModalCliente({Cliente? cliente}) {
    final nomeController = TextEditingController(text: cliente?.nome ?? '');
    final telefoneController = TextEditingController(text: cliente?.telefone ?? '');
    final enderecoController = TextEditingController(text: cliente?.endereco ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cliente == null ? 'Adicionar Cliente' : 'Editar Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: telefoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
            TextField(
              controller: enderecoController,
              decoration: const InputDecoration(labelText: 'Endereço'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              if (nome.isEmpty) return;
              final novoCliente = Cliente(
                id: cliente?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                nome: nome,
                telefone: telefoneController.text.trim(),
                endereco: enderecoController.text.trim(),
                dataCadastro: cliente?.dataCadastro ?? DateTime.now(),
              );
              if (cliente == null) {
                await _adicionarCliente(novoCliente);
              } else {
                await _editarCliente(novoCliente);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(cliente == null ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  void _confirmarExcluirCliente(Cliente cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Cliente'),
        content: Text('Deseja excluir o cliente "${cliente.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _excluirCliente(cliente.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _compartilharResumoClientes() async {
    try {
      final mensagem = _formatarResumoClientes();
      final url = _criarUrlWhatsApp(mensagem);
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resumo de clientes compartilhado!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Não foi possível abrir o WhatsApp');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao compartilhar. Verifique se o WhatsApp está instalado.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatarResumoClientes() {
    final totalClientes = _clientes.length;
    String mensagem = '''
🏪 *CADERNINHO DO COMERCIANTE*

📊 *RESUMO DE CLIENTES*

👥 *Total de Clientes:* $totalClientes
''';
    return mensagem;
  }

  String _criarUrlWhatsApp(String mensagem) {
    final mensagemCodificada = Uri.encodeComponent(mensagem);
    return 'https://wa.me/?text=$mensagemCodificada';
  }

  Future<void> _compartilharClienteWhatsApp(Cliente cliente) async {
    try {
      final mensagem = 'Cliente: ${cliente.nome}\nTelefone: ${cliente.telefone ?? '-'}';
      final mensagemCodificada = Uri.encodeComponent(mensagem);
      
      // Tentar primeiro o app nativo do WhatsApp
      final urlApp = 'whatsapp://send?text=$mensagemCodificada';
      if (await canLaunchUrl(Uri.parse(urlApp))) {
        await launchUrl(Uri.parse(urlApp), mode: LaunchMode.externalApplication);
        return;
      }
      
      // Fallback para WhatsApp Web
      final urlWeb = 'https://wa.me/?text=$mensagemCodificada';
      if (await canLaunchUrl(Uri.parse(urlWeb))) {
        await launchUrl(Uri.parse(urlWeb), mode: LaunchMode.externalApplication);
        return;
      }
      
      // Se nenhum funcionar, mostrar erro
      throw Exception('Não foi possível abrir o WhatsApp. Verifique se está instalado.');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _compartilharHistoricoCompleto(Cliente cliente) async {
    try {
      await WhatsAppService.compartilharHistoricoCompleto(cliente);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Histórico completo de ${cliente.nome} compartilhado!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _compartilharResumoClientes,
            tooltip: 'Compartilhar resumo',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _abrirModalCliente(),
            tooltip: 'Adicionar cliente',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                hintText: 'Buscar cliente por nome ou telefone',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                suffixIcon: _buscaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscaController.clear();
                          setState(() {
                            _filtrarClientes();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _filtrarClientes();
                });
              },
              textInputAction: TextInputAction.search,
              autocorrect: false,
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _clientesFiltrados.isEmpty
                    ? const Center(child: Text('Nenhum cliente cadastrado'))
                    : ListView.builder(
                        itemCount: _clientesFiltrados.length,
                        itemBuilder: (context, index) {
                          final cliente = _clientesFiltrados[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?'),
                                ),
                                title: Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (cliente.telefone != null && cliente.telefone!.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 14),
                                          const SizedBox(width: 4),
                                          Text(cliente.telefone!),
                                        ],
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                                        IconButton(
                      icon: const Icon(Icons.share, color: Colors.green),
                      onPressed: () => _compartilharHistoricoCompleto(cliente),
                      tooltip: 'Compartilhar histórico completo',
                    ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Detalhes do Cliente'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Nome: ${cliente.nome}'),
                                                if (cliente.telefone != null && cliente.telefone!.isNotEmpty)
                                                  Text('Telefone: ${cliente.telefone}'),
                                                if (cliente.endereco != null && cliente.endereco!.isNotEmpty)
                                                  Text('Endereço: ${cliente.endereco}'),
                                                Text('Cadastrado em: ${cliente.dataCadastro.toString().substring(0, 10)}'),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Fechar'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      tooltip: 'Ver detalhes',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _abrirModalCliente(cliente: cliente),
                                      tooltip: 'Editar cliente',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmarExcluirCliente(cliente),
                                      tooltip: 'Excluir cliente',
                                    ),
                                  ],
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class TelaDetalhesCliente extends StatelessWidget {
  final Cliente cliente;
  final List<Venda> vendas;

  const TelaDetalhesCliente({
    super.key,
    required this.cliente,
    required this.vendas,
  });

  @override
  Widget build(BuildContext context) {
    final totalGasto = vendas.fold(0.0, (sum, venda) => sum + venda.total);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('👤 ${cliente.nome}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                await WhatsAppService.compartilharHistoricoCompleto(cliente);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Histórico completo de ${cliente.nome} compartilhado!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao compartilhar: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do cliente
            _buildCardInformacoes(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInformacoes(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    cliente.nome.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nome,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      if (cliente.telefone != null)
                        Text(
                          '📞 ${cliente.telefone}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (cliente.endereco != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cliente.endereco!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }



  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
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
} 