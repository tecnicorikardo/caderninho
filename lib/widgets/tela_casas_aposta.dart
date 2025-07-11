import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/casa_aposta.dart';
import '../core/app_colors.dart';

class TelaCasasAposta extends StatefulWidget {
  const TelaCasasAposta({super.key});

  @override
  State<TelaCasasAposta> createState() => _TelaCasasApostaState();
}

class _TelaCasasApostaState extends State<TelaCasasAposta> {
  final DatabaseService _db = DatabaseService.instance;
  List<CasaAposta> _casas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarCasas();
  }

  Future<void> _carregarCasas() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final casas = await _db.getCasasAposta();
      setState(() {
        _casas = casas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar casas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏢 Casas de Aposta'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _casas.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _casas.length,
                  itemBuilder: (context, index) {
                    final casa = _casas[index];
                    return _buildCasaCard(casa);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarCasa,
        backgroundColor: AppColors.primary,
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
            Icons.business_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma casa de aposta cadastrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para adicionar uma casa',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasaCard(CasaAposta casa) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            Icons.business,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          casa.nome,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (casa.categoria != null) ...[
              const SizedBox(height: 4),
              Text(
                'Categoria: ${casa.categoria}',
                style: TextStyle(
                  color: context.adaptiveTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            if (casa.url != null) ...[
              const SizedBox(height: 4),
              Text(
                'URL: ${casa.url}',
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
                  casa.ativo ? Icons.check_circle : Icons.cancel,
                  color: casa.ativo ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  casa.ativo ? 'Ativa' : 'Inativa',
                  style: TextStyle(
                    color: casa.ativo ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, casa),
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
              value: casa.ativo ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(
                    casa.ativo ? Icons.block : Icons.check_circle,
                    color: casa.ativo ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(casa.ativo ? 'Desativar' : 'Ativar'),
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

  void _handleMenuAction(String action, CasaAposta casa) {
    switch (action) {
      case 'edit':
        _editarCasa(casa);
        break;
      case 'activate':
      case 'deactivate':
        _alterarStatus(casa);
        break;
      case 'delete':
        _excluirCasa(casa);
        break;
    }
  }

  void _adicionarCasa() {
    _mostrarDialogoCasa();
  }

  void _editarCasa(CasaAposta casa) {
    _mostrarDialogoCasa(casa: casa);
  }

  void _mostrarDialogoCasa({CasaAposta? casa}) {
    final nomeController = TextEditingController(text: casa?.nome ?? '');
    final urlController = TextEditingController(text: casa?.url ?? '');
    final categoriaController = TextEditingController(text: casa?.categoria ?? '');
    final observacoesController = TextEditingController(text: casa?.observacoes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(casa == null ? 'Nova Casa de Aposta' : 'Editar Casa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Casa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoriaController,
                decoration: const InputDecoration(
                  labelText: 'Categoria (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Esportes, Cassino, Poker',
                ),
              ),
              const SizedBox(height: 16),
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
              final nome = nomeController.text.trim();
              if (nome.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nome é obrigatório!')),
                );
                return;
              }

              try {
                final novaCasa = CasaAposta(
                  id: casa?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  nome: nome,
                  url: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
                  categoria: categoriaController.text.trim().isEmpty ? null : categoriaController.text.trim(),
                  observacoes: observacoesController.text.trim().isEmpty ? null : observacoesController.text.trim(),
                  dataCadastro: casa?.dataCadastro ?? DateTime.now(),
                  ativo: casa?.ativo ?? true,
                );

                if (casa == null) {
                  await _db.inserirCasaAposta(novaCasa);
                } else {
                  await _db.atualizarCasaAposta(novaCasa);
                }

                Navigator.pop(context);
                _carregarCasas();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(casa == null ? 'Casa adicionada!' : 'Casa atualizada!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e')),
                );
              }
            },
            child: Text(casa == null ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  void _alterarStatus(CasaAposta casa) async {
    try {
      final novaCasa = casa.copyWith(ativo: !casa.ativo);
      await _db.atualizarCasaAposta(novaCasa);
      _carregarCasas();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(casa.ativo ? 'Casa desativada!' : 'Casa ativada!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  void _excluirCasa(CasaAposta casa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir "${casa.nome}"?'),
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
        await _db.deletarCasaAposta(casa.id);
        _carregarCasas();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Casa excluída!'),
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