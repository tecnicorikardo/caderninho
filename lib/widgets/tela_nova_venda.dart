import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../models/cliente.dart';
import '../models/venda.dart';
import '../models/fiado.dart';
import '../services/database_service.dart';
import '../core/app_colors.dart';

class TelaNovaVenda extends StatefulWidget {
  const TelaNovaVenda({super.key});

  @override
  State<TelaNovaVenda> createState() => _TelaNovaVendaState();
}

class _TelaNovaVendaState extends State<TelaNovaVenda> {
  final DatabaseService _db = DatabaseService.instance;
  final List<ItemVenda> _itens = [];
  final List<Adicional> _adicionais = [];
  Cliente? _clienteSelecionado;
  FormaPagamento _formaPagamento = FormaPagamento.dinheiro;

  List<Produto> _produtos = [];
  List<Cliente> _clientes = [];
  List<Cliente> _clientesFiltrados = [];
  bool _isLoading = true;
  final TextEditingController _buscaClienteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _buscaClienteController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final produtos = await _db.getProdutos();
      final clientes = await _db.getClientes();
      
      setState(() {
        _produtos = produtos;
        _clientes = clientes;
        _clientesFiltrados = clientes; // Inicializa com todos os clientes
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

  double get _subtotal => _itens.fold(0, (sum, item) => sum + item.total);
  double get _totalAdicionais => _adicionais.fold(0, (sum, adicional) => sum + adicional.valor);
  double get _total => _subtotal + _totalAdicionais;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 Nova Venda'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando dados...'),
                ],
              ),
            )
          : Column(
              children: [
                // Resumo da venda
                _buildResumoVenda(),

                // Lista de itens e adicionais
                Expanded(child: _buildListaItensEAdicionais()),

                // Botões de ação
                _buildBotoesAcao(),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botão para adicionar adicional
          FloatingActionButton(
            onPressed: _adicionarAdicional,
            backgroundColor: AppColors.warning,
            heroTag: 'adicionar_adicional',
            child: const Icon(Icons.add_circle, color: Colors.white),
          ),
          const SizedBox(height: 16),
          // Botão para adicionar produto
          FloatingActionButton(
        onPressed: _adicionarItem,
        backgroundColor: Theme.of(context).colorScheme.primary,
            heroTag: 'adicionar_produto',
        child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoVenda() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
                      Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💰 Total da Venda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.adaptiveTextPrimary,
                  ),
                ),
                Text(
                  'R\$ ${_total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                  ),
                ),
              ],
            ),
          if (_totalAdicionais > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal:',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.adaptiveTextSecondary,
                  ),
                ),
                Text(
                  'R\$ ${_subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.adaptiveTextSecondary,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Adicionais:',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.adaptiveTextSecondary,
                  ),
                ),
                Text(
                  'R\$ ${_totalAdicionais.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.adaptiveTextSecondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 15),
          // Campo de busca com 100% de largura
          _buildCampoBuscaCliente(),
          const SizedBox(height: 10),
          // Cliente e pagamento com 50% cada
          Row(
            children: [
              Expanded(child: _buildSeletorCliente()),
              const SizedBox(width: 10),
              Expanded(child: _buildSeletorPagamento()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampoBuscaCliente() {
    return TextField(
      controller: _buscaClienteController,
      decoration: InputDecoration(
        labelText: '🔍 Buscar cliente',
        hintText: 'Digite o nome ou telefone',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _buscaClienteController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _buscaClienteController.clear();
                  _filtrarClientes('');
                },
              )
            : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: _filtrarClientes,
    );
  }

  Widget _buildSeletorCliente() {
    return DropdownButtonFormField<Cliente>(
      value: _clienteSelecionado,
      decoration: const InputDecoration(
        labelText: '👤 Cliente',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<Cliente>(
          value: null,
          child: Text('Sem cliente'),
        ),
        ..._clientesFiltrados.map(
          (cliente) => DropdownMenuItem<Cliente>(
            value: cliente,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cliente.nome,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (cliente.telefone != null)
                  Text(
                    cliente.telefone!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      onChanged: (Cliente? cliente) {
        setState(() {
          _clienteSelecionado = cliente;
        });
      },
    );
  }

  void _filtrarClientes(String query) {
    setState(() {
      if (query.isEmpty) {
        _clientesFiltrados = _clientes;
      } else {
        final queryLower = query.toLowerCase();
        _clientesFiltrados = _clientes.where((cliente) {
          return cliente.nome.toLowerCase().contains(queryLower) ||
                 (cliente.telefone != null && 
                  cliente.telefone!.toLowerCase().contains(queryLower));
        }).toList();
      }
    });
  }

  Widget _buildSeletorPagamento() {
    return DropdownButtonFormField<FormaPagamento>(
      value: _formaPagamento,
      decoration: const InputDecoration(
        labelText: '💳 Pagamento',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: FormaPagamento.values
          .map(
            (forma) => DropdownMenuItem<FormaPagamento>(
              value: forma,
              child: Text(_getFormaPagamentoText(forma)),
            ),
          )
          .toList(),
      onChanged: (FormaPagamento? forma) {
        setState(() {
          _formaPagamento = forma!;
        });
      },
    );
  }

  Widget _buildListaItensEAdicionais() {
    if (_itens.isEmpty && _adicionais.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum item adicionado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Toque no + para adicionar produtos ou adicionais',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Seção de produtos
        if (_itens.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '📦 Produtos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.adaptiveTextPrimary,
              ),
            ),
          ),
          ..._itens.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.inventory,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              item.produto.nome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${item.quantidade} ${item.produto.unidade} × R\$ ${item.precoUnitario.toStringAsFixed(2)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'R\$ ${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removerItem(index),
                ),
              ],
            ),
          ),
        );
          }).toList(),
        ],
        
        // Seção de adicionais
        if (_adicionais.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '💰 Adicionais',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.adaptiveTextPrimary,
              ),
            ),
          ),
          ..._adicionais.asMap().entries.map((entry) {
            final index = entry.key;
            final adicional = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  child: Icon(
                    _getIconeAdicional(adicional.tipo),
                    color: AppColors.warning,
                  ),
                ),
                title: Text(
                  adicional.descricao,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _getTipoAdicionalText(adicional.tipo),
                  style: TextStyle(
                    color: context.adaptiveTextSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'R\$ ${adicional.valor.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removerAdicional(index),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  IconData _getIconeAdicional(TipoAdicional tipo) {
    switch (tipo) {
      case TipoAdicional.taxa_servico:
        return Icons.construction;
      case TipoAdicional.emprestimo:
        return Icons.account_balance_wallet;
    }
  }

  String _getTipoAdicionalText(TipoAdicional tipo) {
    switch (tipo) {
      case TipoAdicional.taxa_servico:
        return 'Taxa de Serviço';
      case TipoAdicional.emprestimo:
        return 'Empréstimo';
    }
  }

  Widget _buildBotoesAcao() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _itens.isEmpty ? null : _finalizarVenda,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '✅ FINALIZAR VENDA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _adicionarItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildModalAdicionarItem(),
      ),
    );
  }

  void _adicionarItemComQuantidade(Produto produto, int quantidade) {
    if (produto.quantidadeEstoque < quantidade) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estoque insuficiente! Disponível: ${produto.quantidadeEstoque} ${produto.unidade}',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final item = ItemVenda(
      produto: produto,
      quantidade: quantidade,
      precoUnitario: produto.preco,
    );
    setState(() {
      _itens.add(item);
    });
  }

  Widget _buildModalAdicionarItem() {
    Produto? produtoSelecionado;
    double precoUnitario = 0.0;
    final quantidadeController = TextEditingController(text: '1');
    final precoController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📦 Adicionar Produto',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: context.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Seletor de produto
              DropdownButtonFormField<Produto>(
                decoration: const InputDecoration(
                  labelText: 'Produto',
                  border: OutlineInputBorder(),
                ),
                items: _produtos
                    .map(
                      (produto) => DropdownMenuItem<Produto>(
                        value: produto,
                        child: Text(
                          '${produto.nome} - R\$ ${produto.preco.toStringAsFixed(2)}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (Produto? produto) {
                  setState(() {
                    produtoSelecionado = produto;
                    precoUnitario = produto?.preco ?? 0.0;
                    precoController.text = precoUnitario.toString();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Quantidade
              Row(
                children: [
                  // Botão para diminuir
                  IconButton(
                    onPressed: () {
                      int atual = int.tryParse(quantidadeController.text) ?? 1;
                      if (atual > 1) {
                        quantidadeController.text = (atual - 1).toString();
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.grey200,
                    ),
                  ),
                  
                  // Campo de quantidade
                  Expanded(
                    child: TextFormField(
                      controller: quantidadeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      autofocus: false,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.adaptiveTextPrimary,
                      ),
                                              decoration: InputDecoration(
                          labelText: 'Quantidade',
                          labelStyle: TextStyle(color: context.adaptiveTextSecondary),
                          hintText: '1',
                          hintStyle: TextStyle(color: context.adaptiveTextSecondary),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: context.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: context.surfaceColor,
                        ),
                      onChanged: (value) {
                        // Validação em tempo real
                        if (value.isNotEmpty) {
                          final quantidade = int.tryParse(value);
                          if (quantidade == null || quantidade <= 0) {
                            quantidadeController.text = '1';
                            quantidadeController.selection = TextSelection.fromPosition(
                              TextPosition(offset: quantidadeController.text.length),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  
                  // Botão para aumentar
                  IconButton(
                    onPressed: () {
                      int atual = int.tryParse(quantidadeController.text) ?? 1;
                      if (produtoSelecionado == null || atual < produtoSelecionado!.quantidadeEstoque) {
                        quantidadeController.text = (atual + 1).toString();
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.successWithOpacity,
                    ),
                  ),
                ],
              ),
              
              // Unidade e estoque disponível
              if (produtoSelecionado != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Unidade: ${produtoSelecionado!.unidade} | Estoque: ${produtoSelecionado!.quantidadeEstoque}',
                    style: TextStyle(
                      color: context.adaptiveTextSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),

              // Preço unitário
              TextFormField(
                controller: precoController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.adaptiveTextPrimary,
                ),
                                  decoration: InputDecoration(
                    labelText: 'Preço Unitário (R\$)',
                    labelStyle: TextStyle(color: context.adaptiveTextSecondary),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: context.primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: context.surfaceColor,
                  ),
                onChanged: (value) {
                  setState(() {
                    precoUnitario = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: produtoSelecionado == null
                          ? null
                          : () {
                              if (produtoSelecionado != null) {
                                final quantidadeFinal = int.tryParse(quantidadeController.text);
                                final precoFinal = double.tryParse(precoController.text);
                                
                                // ✅ VALIDAÇÕES MELHORADAS
                                if (quantidadeFinal == null || quantidadeFinal <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Quantidade deve ser maior que zero!')),
                                  );
                                  return;
                                }
                                
                                if (precoFinal == null || precoFinal <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Preço deve ser maior que zero!')),
                                  );
                                  return;
                                }
                                
                                if (produtoSelecionado!.quantidadeEstoque < quantidadeFinal) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Estoque insuficiente! Disponível: ${produtoSelecionado!.quantidadeEstoque} ${produtoSelecionado!.unidade}',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                
                                final item = ItemVenda(
                                  produto: produtoSelecionado!,
                                  quantidade: quantidadeFinal,
                                  precoUnitario: precoFinal,
                                );
                                this.setState(() {
                                  _itens.add(item);
                                });
                                Navigator.pop(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Adicionar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _removerItem(int index) {
    setState(() {
      _itens.removeAt(index);
    });
  }

  void _adicionarAdicional() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildModalAdicionarAdicional(),
      ),
    );
  }

  Widget _buildModalAdicionarAdicional() {
    final descricaoController = TextEditingController(text: 'Adicional');
    final valorController = TextEditingController();
    TipoAdicional tipoSelecionado = TipoAdicional.taxa_servico;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '💰 Adicionar Adicional',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: context.adaptiveTextPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Tipo de adicional
              DropdownButtonFormField<TipoAdicional>(
                value: tipoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Adicional',
                  border: OutlineInputBorder(),
                ),
                items: TipoAdicional.values.map((tipo) {
                  return DropdownMenuItem<TipoAdicional>(
                    value: tipo,
                    child: Row(
                      children: [
                        Icon(_getIconeAdicional(tipo)),
                        const SizedBox(width: 8),
                        Text(_getTipoAdicionalText(tipo)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (TipoAdicional? tipo) {
                  setState(() {
                    tipoSelecionado = tipo!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: descricaoController,
                decoration: InputDecoration(
                  labelText: tipoSelecionado == TipoAdicional.taxa_servico 
                      ? 'Descrição da taxa de serviço' 
                      : 'Descrição do empréstimo',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Valor
              TextFormField(
                controller: valorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.adaptiveTextPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Valor (R\$)',
                  labelStyle: TextStyle(color: context.adaptiveTextSecondary),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: context.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: context.surfaceColor,
                  hintText: 'Ex: 0.50',
                ),
                onChanged: (value) {
                  setState(() {
                    // Validação em tempo real
                    if (value.isNotEmpty) {
                      final valor = double.tryParse(value);
                      if (valor == null || valor < 0) {
                        // Não resetar o valor, apenas permitir edição
                        // O usuário pode estar digitando
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        print('🔍 Botão Adicionar clicado');
                        final descricao = descricaoController.text.trim();
                        final valor = double.tryParse(valorController.text);
                        
                        print('🔍 Descrição: "$descricao"');
                        print('🔍 Valor: $valor');
                        print('🔍 Tipo: $tipoSelecionado');
                        
                        if (descricao.isEmpty) {
                          print('❌ Descrição vazia');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Digite uma descrição!')),
                          );
                          return;
                        }
                        
                        if (valor == null || valor <= 0) {
                          print('❌ Valor inválido: $valor');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Digite um valor válido!')),
                          );
                          return;
                        }
                        
                        print('✅ Criando adicional...');
                        final adicional = Adicional(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          tipo: tipoSelecionado,
                          descricao: descricao,
                          valor: valor,
                          data: DateTime.now(),
                        );
                        
                        print('✅ Adicionando à lista...');
                        this.setState(() {
                          _adicionais.add(adicional);
                        });
                        print('✅ Adicional adicionado. Total: ${_adicionais.length}');
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Adicionar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _removerAdicional(int index) {
    setState(() {
      _adicionais.removeAt(index);
    });
  }

  Future<void> _finalizarVenda() async {
    if (_itens.isEmpty) return;

    // ✅ CONFIRMAÇÃO ANTES DE FINALIZAR
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🛒 Confirmar Venda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: R\$ ${_total.toStringAsFixed(2)}'),
            if (_subtotal > 0) Text('Subtotal: R\$ ${_subtotal.toStringAsFixed(2)}'),
            if (_totalAdicionais > 0) Text('Adicionais: R\$ ${_totalAdicionais.toStringAsFixed(2)}'),
            if (_clienteSelecionado != null)
              Text('Cliente: ${_clienteSelecionado!.nome}'),
            Text('Pagamento: ${_getFormaPagamentoText(_formaPagamento)}'),
            const SizedBox(height: 10),
            Text('${_itens.length} produto(s) na venda'),
            if (_adicionais.isNotEmpty) Text('${_adicionais.length} adicional(is) na venda'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final venda = Venda(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itens: List.from(_itens),
        adicionais: List.from(_adicionais),
        cliente: _clienteSelecionado,
        formaPagamento: _formaPagamento,
        dataVenda: DateTime.now(),
      );

      // Salvar venda no banco de dados
      await _db.inserirVenda(venda);

      // Se for fiado, criar também o registro na tabela fiados
      if (_formaPagamento == FormaPagamento.fiado && _clienteSelecionado != null) {
        final fiado = Fiado(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          cliente: _clienteSelecionado!,
          valorTotal: venda.total,
          valorPago: 0.0,
          dataFiado: venda.dataVenda,
          dataVencimento: null, // Pode ser ajustado para permitir escolher vencimento
          observacao: null,
        );
        await _db.inserirFiado(fiado);
      }

      // Mostrar resumo da venda
      String mensagem = 'Venda finalizada! Total: R\$ ${venda.total.toStringAsFixed(2)}';
      if (_adicionais.isNotEmpty) {
        mensagem += '\nAdicionais: R\$ ${_totalAdicionais.toStringAsFixed(2)}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Limpa a tela
      setState(() {
        _itens.clear();
        _adicionais.clear();
        _clienteSelecionado = null;
        _formaPagamento = FormaPagamento.dinheiro;
      });

      // Volta para a tela principal
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao finalizar venda: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

