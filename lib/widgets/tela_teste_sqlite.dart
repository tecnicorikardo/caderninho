import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/produto.dart';
import '../models/cliente.dart';
import '../models/venda.dart';
import '../models/fiado.dart';
import '../services/agenda_service.dart';
import '../models/compromisso.dart';

class TelaTesteSQLite extends StatefulWidget {
  const TelaTesteSQLite({super.key});

  @override
  State<TelaTesteSQLite> createState() => _TelaTesteSQLiteState();
}

class _TelaTesteSQLiteState extends State<TelaTesteSQLite> {
  final DatabaseService _db = DatabaseService.instance;
  bool _isLoading = true;
  String _status = 'Inicializando...';
  
  List<Produto> _produtos = [];
  List<Cliente> _clientes = [];
  List<Venda> _vendas = [];
  List<Fiado> _fiados = [];
  
  double _vendasHoje = 0.0;
  double _fiadosPendentes = 0.0;
  int _estoqueBaixo = 0;

  @override
  void initState() {
    super.initState();
    _testarSQLite();
  }

  Future<void> _testarSQLite() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Conectando ao banco...';
      });

      // Testar conexão e carregar dados
      await _db.database;
      
      setState(() {
        _status = 'Carregando produtos...';
      });
      _produtos = await _db.getProdutos();
      
      setState(() {
        _status = 'Carregando clientes...';
      });
      _clientes = await _db.getClientes();
      
      setState(() {
        _status = 'Carregando vendas...';
      });
      _vendas = await _db.getVendas();
      
      setState(() {
        _status = 'Carregando fiados...';
      });
      _fiados = await _db.getFiados();
      
      setState(() {
        _status = 'Calculando estatísticas...';
      });
      _vendasHoje = await _db.getVendasHoje();
      _fiadosPendentes = await _db.getFiadosPendentes();
      _estoqueBaixo = await _db.getEstoqueBaixo();
      
      setState(() {
        _isLoading = false;
        _status = 'Teste concluído com sucesso!';
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Erro: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste SQLite'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testarSQLite,
          ),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_status),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _status.contains('Erro') ? Icons.error : Icons.check_circle,
                              color: _status.contains('Erro') ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _status,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Estatísticas
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estatísticas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildStatItem('Vendas Hoje', 'R\$ ${_vendasHoje.toStringAsFixed(2)}', Icons.shopping_cart),
                        _buildStatItem('Fiados Pendentes', 'R\$ ${_fiadosPendentes.toStringAsFixed(2)}', Icons.credit_card),
                        _buildStatItem('Produtos com Estoque Baixo', '$_estoqueBaixo itens', Icons.warning),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botão de backup do banco de dados
                ElevatedButton.icon(
                  icon: const Icon(Icons.backup),
                  label: const Text('Fazer Backup do Banco'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Realizando backup...')),
                    );
                    try {
                      String backupPath = await _db.backupDatabase();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Backup realizado em: $backupPath')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao fazer backup: $e')),
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Botão de resetar banco de dados
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Resetar Banco'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await DatabaseService().resetarBanco();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Banco resetado com sucesso!')),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Resumo dos dados
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dados Carregados',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildDataItem('Produtos', _produtos.length, Icons.inventory),
                        _buildDataItem('Clientes', _clientes.length, Icons.people),
                        _buildDataItem('Vendas', _vendas.length, Icons.receipt),
                        _buildDataItem('Fiados', _fiados.length, Icons.credit_card),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Lista de produtos
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Produtos (Primeiros 5)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ..._produtos.take(5).map((produto) => 
                          ListTile(
                            leading: const Icon(Icons.inventory),
                            title: Text(produto.nome),
                            subtitle: Text('R\$ ${produto.preco.toStringAsFixed(2)} - ${produto.quantidadeEstoque} ${produto.unidade}'),
                            trailing: Text(
                              produto.quantidadeEstoque <= 10 ? 'Baixo' : 'OK',
                              style: TextStyle(
                                color: produto.quantidadeEstoque <= 10 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Lista de clientes
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clientes (Primeiros 5)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ..._clientes.take(5).map((cliente) => 
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(cliente.nome),
                            subtitle: Text(cliente.telefone ?? 'Sem telefone'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botões de teste
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Testes Adicionais',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _testarInserirProduto,
                          icon: const Icon(Icons.add),
                          label: const Text('Inserir Produto Teste'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _testarInserirCliente,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Inserir Cliente Teste'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _testarBackup,
                          icon: const Icon(Icons.backup),
                          label: const Text('Testar Backup'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _testarAgenda,
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Testar Agenda'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(String label, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _testarInserirProduto() async {
    try {
      final produto = Produto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nome: 'Produto Teste ${DateTime.now().second}',
        preco: 10.0 + DateTime.now().second.toDouble(),
        unidade: 'un',
        quantidadeEstoque: 100,
      );
      
      await _db.inserirProduto(produto);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto inserido com sucesso!')),
      );
      _testarSQLite(); // Recarregar dados
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao inserir produto: $e')),
      );
    }
  }

  Future<void> _testarInserirCliente() async {
    try {
      final cliente = Cliente(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nome: 'Cliente Teste ${DateTime.now().second}',
        telefone: '11999999999',
        endereco: 'Rua Teste, 123',
        dataCadastro: DateTime.now(),
      );
      
      await _db.inserirCliente(cliente);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente inserido com sucesso!')),
      );
      _testarSQLite(); // Recarregar dados
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao inserir cliente: $e')),
      );
    }
  }

  Future<void> _testarBackup() async {
    try {
      final dados = await _db.exportarDados();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup criado com ${dados['produtos'].length} produtos, ${dados['clientes'].length} clientes, ${dados['vendas'].length} vendas e ${dados['fiados'].length} fiados'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar backup: $e')),
      );
    }
  }

  Future<void> _testarAgenda() async {
    setState(() => _isLoading = true);
    
    try {
      _status = '🔄 Testando sistema de Agenda...';
      
      // Verificar se a tabela existe
      await AgendaService().verificarTabelaCompromissos();
      _status = '✅ Tabela de compromissos verificada';
      
      // Testar inserção de compromisso
      final compromisso = Compromisso(
        data: DateTime.now().add(Duration(days: 1)),
        hora: '14:30',
        descricao: 'Compromisso de teste',
        alertaUmDiaAntes: true,
      );
      
      await AgendaService().adicionarCompromisso(compromisso);
      _status = '✅ Compromisso de teste inserido';
      
      // Testar busca de compromissos
      final compromissos = await AgendaService().buscarCompromissos();
      _status = '✅ Compromissos encontrados: ${compromissos.length}';
      
      // Testar busca por data
      final compromissosHoje = await AgendaService().buscarCompromissosPorData(DateTime.now());
      _status = '✅ Compromissos hoje: ${compromissosHoje.length}';
      
      // Testar exclusão do compromisso de teste
      await AgendaService().excluirCompromisso(compromisso.id);
      _status = '✅ Compromisso de teste excluído';
      
      _status = '🎉 Teste da Agenda CONCLUÍDO COM SUCESSO!';
      
    } catch (e) {
      _status = '❌ Erro no teste da agenda: $e';
      print('❌ Erro detalhado: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
} 