import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';
import '../models/cliente.dart';
import '../models/produto.dart';
import '../models/venda.dart';
import '../models/fiado.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  static ExportService get instance => _instance;

  /// Exporta todos os dados para CSV
  Future<String> exportarParaCSV() async {
    try {
      final db = DatabaseService.instance;
      
      // Buscar todos os dados
      final clientes = await db.getClientes();
      final produtos = await db.getProdutos();
      final vendas = await db.getVendas();
      final fiados = await db.getFiados();

      // Criar conteúdo CSV
      final csvContent = _criarCSVContent(clientes, produtos, vendas, fiados);

      // Salvar arquivo
      final directory = await _getExportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'export_caderninho_$timestamp.csv';
      final file = File(path.join(directory.path, fileName));

      await file.writeAsString(csvContent, encoding: utf8);

      return file.path;
    } catch (e) {
      throw Exception('Erro ao exportar dados: $e');
    }
  }

  String _criarCSVContent(List<Cliente> clientes, List<Produto> produtos, List<Venda> vendas, List<Fiado> fiados) {
    final buffer = StringBuffer();

    // Cabeçalho com informações gerais
    buffer.writeln('CADERNINHO DO COMERCIANTE - EXPORTAÇÃO DE DADOS');
    buffer.writeln('Data da exportação: ${DateTime.now().toString()}');
    buffer.writeln('');

    // Seção de Clientes
    buffer.writeln('=== CLIENTES ===');
    buffer.writeln('ID,Nome,Telefone,Endereço,Data de Cadastro');
    for (final cliente in clientes) {
      buffer.writeln('${cliente.id},"${cliente.nome}","${cliente.telefone ?? ''}","${cliente.endereco ?? ''}","${cliente.dataCadastro}"');
    }
    buffer.writeln('');

    // Seção de Produtos
    buffer.writeln('=== PRODUTOS ===');
    buffer.writeln('ID,Nome,Preço,Unidade,Quantidade em Estoque');
    for (final produto in produtos) {
      buffer.writeln('${produto.id},"${produto.nome}",${produto.preco},${produto.unidade},${produto.quantidadeEstoque}');
    }
    buffer.writeln('');

    // Seção de Vendas
    buffer.writeln('=== VENDAS ===');
    buffer.writeln('ID,Cliente,Data,Forma de Pagamento,Total,Itens');
    for (final venda in vendas) {
      final itensStr = venda.itens.map((item) => 
        '${item.produto.nome} ${item.quantidade}${item.produto.unidade}'
      ).join('; ');
      
      buffer.writeln('${venda.id},"${venda.cliente?.nome ?? 'Sem cliente'}","${venda.dataVenda}","${_getFormaPagamentoText(venda.formaPagamento)}",${venda.total},"$itensStr"');
    }
    buffer.writeln('');

    // Seção de Fiados
    buffer.writeln('=== FIADOS ===');
    buffer.writeln('ID,Cliente,Valor Total,Valor Pago,Valor Restante,Data do Fiado,Data de Vencimento,Status,Observação');
    for (final fiado in fiados) {
      buffer.writeln('${fiado.id},"${fiado.cliente.nome}",${fiado.valorTotal},${fiado.valorPago},${fiado.valorRestante},"${fiado.dataFiado}","${fiado.dataVencimento ?? ''}","${_getStatusFiadoText(fiado)}","${fiado.observacao ?? ''}"');
    }
    buffer.writeln('');

    // Resumo
    buffer.writeln('=== RESUMO ===');
    buffer.writeln('Total de Clientes,${clientes.length}');
    buffer.writeln('Total de Produtos,${produtos.length}');
    buffer.writeln('Total de Vendas,${vendas.length}');
    buffer.writeln('Total de Fiados,${fiados.length}');
    
    final totalVendas = vendas.fold(0.0, (sum, v) => sum + v.total);
    final totalFiadosPendentes = fiados.where((f) => f.status != StatusFiado.pago)
        .fold(0.0, (sum, f) => sum + f.valorRestante);
    
    buffer.writeln('Total em Vendas,R\$ ${totalVendas.toStringAsFixed(2)}');
    buffer.writeln('Total em Fiados Pendentes,R\$ ${totalFiadosPendentes.toStringAsFixed(2)}');

    return buffer.toString();
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

  String _getStatusFiadoText(Fiado fiado) {
    if (fiado.status == StatusFiado.pago) return 'Pago';
    if (fiado.estaVencido) return 'Vencido';
    if (fiado.status == StatusFiado.parcial) return 'Parcial';
    return 'Pendente';
  }

  /// Obtém o diretório de exportação
  Future<Directory> _getExportDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(path.join(appDir.path, 'exports'));
    
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    
    return exportDir;
  }
} 