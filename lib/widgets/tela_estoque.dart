import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../services/database_service.dart';
import '../core/app_colors.dart';
import 'package:intl/intl.dart';

class TelaEstoque extends StatefulWidget {
  const TelaEstoque({super.key});

  @override
  State<TelaEstoque> createState() => _TelaEstoqueState();
}

class _TelaEstoqueState extends State<TelaEstoque> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService.instance;
  List<Produto> _produtos = [];
  bool _carregando = true;
  String _filtro = '';
  
  // ✅ NOVOS CAMPOS PARA RELATÓRIO DE LUCRO
  late TabController _tabController;
  List<Map<String, dynamic>> _relatorioLucro = [];
  bool _carregandoRelatorio = false;
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dataFim = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarProdutos();
    _carregarRelatorioLucro();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarProdutos() async {
    setState(() => _carregando = true);
    try {
      final produtos = await _db.getProdutos();
      setState(() {
        _produtos = produtos;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar produtos: $e');
      setState(() => _carregando = false);
    }
  }

  // ✅ NOVO MÉTODO PARA CARREGAR RELATÓRIO DE LUCRO
  Future<void> _carregarRelatorioLucro() async {
    setState(() => _carregandoRelatorio = true);
    try {
      final relatorio = await _db.getRelatorioLucroPorProduto(_dataInicio, _dataFim);
      setState(() {
        _relatorioLucro = relatorio;
        _carregandoRelatorio = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar relatório de lucro: $e');
      setState(() => _carregandoRelatorio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Produtos'),
            Tab(text: 'Relatório de Lucro'),
            Tab(text: 'Análise'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTelaProdutos(),
          _buildRelatorioLucro(),
          _buildAnalise(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarProduto,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTelaProdutos() {
    final produtosFiltrados = _produtos.where((produto) {
      return produto.nome.toLowerCase().contains(_filtro.toLowerCase());
    }).toList();

    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar produto',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _filtro = value),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: produtosFiltrados.length,
            itemBuilder: (context, index) {
              final produto = produtosFiltrados[index];
              return _buildCardProduto(produto);
            },
          ),
        ),
      ],
    );
  }

  // ✅ NOVA TELA DE RELATÓRIO DE LUCRO
  Widget _buildRelatorioLucro() {
    return Column(
      children: [
        // Seletor de período
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selecionarPeriodo(),
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    '${DateFormat('dd/MM').format(_dataInicio)} - ${DateFormat('dd/MM').format(_dataFim)}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _carregarRelatorioLucro,
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar',
              ),
            ],
          ),
        ),
        
        // Resumo do período
        _buildResumoPeriodo(),
        
        // Lista de produtos com lucro
        Expanded(
          child: _carregandoRelatorio
              ? const Center(child: CircularProgressIndicator())
              : _relatorioLucro.isEmpty
                  ? const Center(
                      child: Text('Nenhuma venda encontrada no período'),
                    )
                  : ListView.builder(
                      itemCount: _relatorioLucro.length,
                      itemBuilder: (context, index) {
                        final item = _relatorioLucro[index];
                        return _buildCardRelatorioLucro(item);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildResumoPeriodo() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
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
          const Text(
            'Resumo do Período',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<double>(
            future: _db.getLucroTotal(_dataInicio, _dataFim),
            builder: (context, snapshot) {
              final lucroTotal = snapshot.data ?? 0.0;
              return Row(
                children: [
                  Expanded(
                    child: _buildItemResumo(
                      'Lucro Total',
                      'R\$ ${lucroTotal.toStringAsFixed(2)}',
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FutureBuilder<double>(
                      future: _db.getMargemLucroMedia(_dataInicio, _dataFim),
                      builder: (context, snapshot) {
                        final margem = snapshot.data ?? 0.0;
                        return _buildItemResumo(
                          'Margem Média',
                          '${margem.toStringAsFixed(1)}%',
                          AppColors.info,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemResumo(String titulo, String valor, Color cor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }

  Widget _buildCardRelatorioLucro(Map<String, dynamic> item) {
    final produto = item['produto'] as String;
    final categoria = item['categoria'] as String? ?? 'Sem Categoria';
    final quantidadeVendida = item['quantidadeVendida'] as int? ?? 0;
    final totalVendas = (item['totalVendas'] as num?)?.toDouble() ?? 0.0;
    final totalCustos = (item['totalCustos'] as num?)?.toDouble() ?? 0.0;
    final totalLucro = (item['totalLucro'] as num?)?.toDouble() ?? 0.0;
    final lucroMedio = (item['lucroMedio'] as num?)?.toDouble() ?? 0.0;
    
    final margemLucro = totalVendas > 0 ? (totalLucro / totalVendas) * 100 : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        categoria,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: totalLucro >= 0 ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'R\$ ${totalLucro.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetalheRelatorio(
                    'Qtd Vendida',
                    quantidadeVendida.toString(),
                  ),
                ),
                Expanded(
                  child: _buildDetalheRelatorio(
                    'Vendas',
                    'R\$ ${totalVendas.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _buildDetalheRelatorio(
                    'Custos',
                    'R\$ ${totalCustos.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetalheRelatorio(
                    'Lucro Médio',
                    'R\$ ${lucroMedio.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _buildDetalheRelatorio(
                    'Margem',
                    '${margemLucro.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalheRelatorio(String titulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ✅ NOVA TELA DE ANÁLISE
  Widget _buildAnalise() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          child: const Text(
            'Análise de Rentabilidade',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCardAnalise(
                  'Produtos Mais Lucrativos',
                  Icons.trending_up,
                  AppColors.success,
                  () => _mostrarProdutosMaisLucrativos(),
                ),
                const SizedBox(height: 12),
                _buildCardAnalise(
                  'Produtos com Problemas',
                  Icons.trending_down,
                  AppColors.error,
                  () => _mostrarProdutosMenosLucrativos(),
                ),
                const SizedBox(height: 12),
                _buildCardAnalise(
                  'Análise por Categoria',
                  Icons.category,
                  AppColors.info,
                  () => _mostrarAnalisePorCategoria(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardAnalise(String titulo, IconData icone, Color cor, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: cor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardProduto(Produto produto) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        title: Text(produto.nome),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preço: R\$ ${produto.preco.toStringAsFixed(2)}'),
            Text('Estoque: ${produto.quantidadeEstoque} ${produto.unidade}'),
            if (produto.temCustoDefinido) ...[
              Text('Custo: R\$ ${produto.custoUnitario!.toStringAsFixed(2)}'),
              Text(
                'Lucro: R\$ ${produto.lucroUnitario.toStringAsFixed(2)} (${produto.margemLucro.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: produto.lucroUnitario >= 0 ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'editar',
              child: Text('Editar'),
            ),
            const PopupMenuItem(
              value: 'excluir',
              child: Text('Excluir'),
            ),
          ],
          onSelected: (value) {
            if (value == 'editar') {
              _editarProduto(produto);
            } else if (value == 'excluir') {
              _excluirProduto(produto);
            }
          },
        ),
      ),
    );
  }

  void _adicionarProduto() {
    _mostrarFormularioProduto();
  }

  void _editarProduto(Produto produto) {
    _mostrarFormularioProduto(produto: produto);
  }

  void _excluirProduto(Produto produto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o produto "${produto.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmarExclusao(produto);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarExclusao(Produto produto) async {
    try {
      await _db.deletarProduto(produto.id);
      _carregarProdutos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produto "${produto.nome}" excluído com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir produto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _mostrarFormularioProduto({Produto? produto}) {
    final isEditando = produto != null;
    final nomeController = TextEditingController(text: produto?.nome ?? '');
    final precoController = TextEditingController(text: produto?.preco.toString() ?? '');
    final unidadeController = TextEditingController(text: produto?.unidade ?? '');
    final quantidadeController = TextEditingController(text: produto?.quantidadeEstoque.toString() ?? '');
    final custoController = TextEditingController(text: produto?.custoUnitario?.toString() ?? '');
    final categoriaController = TextEditingController(text: produto?.categoria ?? '');
    final fornecedorController = TextEditingController(text: produto?.fornecedor ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditando ? 'Editar Produto' : 'Adicionar Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: precoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Preço',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: unidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Unidade',
                        hintText: 'kg, L, un',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantidadeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade em Estoque',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Informações de Custo (Opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: custoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Custo Unitário',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: categoriaController,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        hintText: 'Ex: Alimentos, Bebidas',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: fornecedorController,
                      decoration: const InputDecoration(
                        labelText: 'Fornecedor',
                        hintText: 'Nome do fornecedor',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
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
              await _salvarProduto(
                nomeController.text,
                precoController.text,
                unidadeController.text,
                quantidadeController.text,
                custoController.text,
                categoriaController.text,
                fornecedorController.text,
                produto,
              );
              Navigator.pop(context);
            },
            child: Text(isEditando ? 'Salvar' : 'Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _salvarProduto(
    String nome,
    String preco,
    String unidade,
    String quantidade,
    String custo,
    String categoria,
    String fornecedor,
    Produto? produtoExistente,
  ) async {
    try {
      // Validações
      if (nome.trim().isEmpty) {
        throw Exception('Nome do produto é obrigatório');
      }
      
      final precoValue = double.tryParse(preco);
      if (precoValue == null || precoValue <= 0) {
        throw Exception('Preço deve ser um valor válido maior que zero');
      }
      
      final quantidadeValue = int.tryParse(quantidade);
      if (quantidadeValue == null || quantidadeValue < 0) {
        throw Exception('Quantidade deve ser um número válido');
      }
      
      final custoValue = custo.trim().isEmpty ? null : double.tryParse(custo);
      if (custo != null && custoValue != null && custoValue < 0) {
        throw Exception('Custo deve ser um valor válido');
      }

      final produto = Produto(
        id: produtoExistente?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nome: nome.trim(),
        preco: precoValue,
        unidade: unidade.trim(),
        quantidadeEstoque: quantidadeValue,
        custoUnitario: custoValue,
        categoria: categoria.trim().isEmpty ? null : categoria.trim(),
        fornecedor: fornecedor.trim().isEmpty ? null : fornecedor.trim(),
      );

      if (produtoExistente != null) {
        await _db.atualizarProduto(produto);
      } else {
        await _db.inserirProduto(produto);
      }

      _carregarProdutos();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              produtoExistente != null 
                ? 'Produto "${produto.nome}" atualizado com sucesso!'
                : 'Produto "${produto.nome}" adicionado com sucesso!'
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ✅ NOVOS MÉTODOS PARA ANÁLISE
  Future<void> _selecionarPeriodo() async {
    final DateTimeRange? periodo = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _dataInicio,
        end: _dataFim,
      ),
    );

    if (periodo != null) {
      setState(() {
        _dataInicio = periodo.start;
        _dataFim = periodo.end;
      });
      _carregarRelatorioLucro();
    }
  }

  Future<void> _mostrarProdutosMaisLucrativos() async {
    final produtos = await _db.getProdutosMaisLucrativos(_dataInicio, _dataFim);
    if (!mounted) return;
    
    _mostrarDialogoProdutos(
      'Produtos Mais Lucrativos',
      produtos,
      AppColors.success,
    );
  }

  Future<void> _mostrarProdutosMenosLucrativos() async {
    final produtos = await _db.getProdutosMenosLucrativos(_dataInicio, _dataFim);
    if (!mounted) return;
    
    _mostrarDialogoProdutos(
      'Produtos com Menor Lucro',
      produtos,
      AppColors.error,
    );
  }

  Future<void> _mostrarAnalisePorCategoria() async {
    final categorias = await _db.getRelatorioLucroPorCategoria(_dataInicio, _dataFim);
    if (!mounted) return;
    
    _mostrarDialogoCategorias(categorias);
  }

  void _mostrarDialogoProdutos(String titulo, List<Map<String, dynamic>> produtos, Color cor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final item = produtos[index];
              return ListTile(
                title: Text(item['produto']),
                subtitle: Text(item['categoria'] ?? 'Sem Categoria'),
                trailing: Text(
                  'R\$ ${(item['totalLucro'] as num).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCategorias(List<Map<String, dynamic>> categorias) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Análise por Categoria'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final item = categorias[index];
              final totalLucro = (item['totalLucro'] as num).toDouble();
              final totalVendas = (item['totalVendas'] as num).toDouble();
              final margem = totalVendas > 0 ? (totalLucro / totalVendas) * 100 : 0.0;
              
              return ListTile(
                title: Text(item['categoria']),
                subtitle: Text('${item['totalProdutos']} produtos'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${totalLucro.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: totalLucro >= 0 ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${margem.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
} 