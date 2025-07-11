import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/cliente.dart';
import '../models/venda.dart';
import '../models/fiado.dart';
import '../models/conta.dart';
import 'dados_service.dart';

class WhatsAppService {
  static Future<void> compartilharHistoricoCliente(Cliente cliente, List<Venda> vendas) async {
    final mensagem = _formatarMensagemHistorico(cliente, vendas);
    final url = _criarUrlWhatsApp(mensagem);
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw Exception('Não foi possível abrir o WhatsApp');
    }
  }

  static Future<void> compartilharHistoricoCompleto(Cliente cliente) async {
    try {
      final dadosService = DadosService();
      
      // Buscar todos os dados do cliente
      final vendas = await dadosService.obterVendasPorCliente(cliente.id);
      final fiados = await dadosService.obterFiadosPorCliente(cliente.id);
      final contas = await dadosService.obterContasPorCliente(cliente.id);
      
      final mensagem = _formatarMensagemHistoricoCompleto(cliente, vendas, fiados, contas);
      final url = _criarUrlWhatsApp(mensagem);
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw Exception('Não foi possível abrir o WhatsApp');
      }
    } catch (e) {
      throw Exception('Erro ao compartilhar histórico: $e');
    }
  }

  static Future<void> enviarCobranca(Fiado fiado) async {
    final mensagem = _formatarMensagemCobranca(fiado);
    final url = _criarUrlWhatsApp(mensagem);
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw Exception('Não foi possível abrir o WhatsApp');
    }
  }

  static String _formatarMensagemCobranca(Fiado fiado) {
    final formatter = DateFormat('dd/MM/yyyy');
    
    String mensagem = '''
🏪 *CADERNINHO DO COMERCIANTE*

💰 *COBRANÇA DE FIADO*

👤 *Cliente:* ${fiado.cliente.nome}
📅 *Data do Fiado:* ${formatter.format(fiado.dataFiado)}
💰 *Valor Total:* R\$ ${fiado.valorTotal.toStringAsFixed(2)}
💳 *Valor Pago:* R\$ ${fiado.valorPago.toStringAsFixed(2)}
📊 *Valor Restante:* R\$ ${fiado.valorRestante.toStringAsFixed(2)}
''';

    if (fiado.dataVencimento != null) {
      mensagem += '📅 *Vencimento:* ${formatter.format(fiado.dataVencimento!)}\n';
    }

    mensagem += '''
    
📱 *Por favor, entre em contato para acertar o pagamento.*
*Obrigado pela preferência!*
''';

    return mensagem;
  }

  static String _formatarMensagemHistoricoCompleto(Cliente cliente, List<Venda> vendas, List<Fiado> fiados, List<Conta> contas) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final dateFormatter = DateFormat('dd/MM/yyyy');
    
    final totalVendas = vendas.fold(0.0, (sum, venda) => sum + venda.total);
    final totalFiados = fiados.fold(0.0, (sum, fiado) => sum + fiado.valorTotal);
    final totalRecebido = fiados.fold(0.0, (sum, fiado) => sum + fiado.valorPago);
    final totalPendente = fiados.fold(0.0, (sum, fiado) => sum + fiado.valorRestante);
    final totalContas = contas.fold(0.0, (sum, conta) => sum + conta.valor);
    
    String mensagem = '''
🏪 *CADERNINHO DO COMERCIANTE*

👤 *HISTÓRICO COMPLETO DO CLIENTE*
📞 *Nome:* ${cliente.nome}
📱 *Telefone:* ${cliente.telefone ?? 'Não informado'}
🏠 *Endereço:* ${cliente.endereco ?? 'Não informado'}
📅 *Cliente desde:* ${dateFormatter.format(cliente.dataCadastro)}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 *RESUMO FINANCEIRO*
💰 *Total em Vendas:* R\$ ${totalVendas.toStringAsFixed(2)}
🔄 *Total em Fiados:* R\$ ${totalFiados.toStringAsFixed(2)}
✅ *Valor Recebido:* R\$ ${totalRecebido.toStringAsFixed(2)}
⏰ *Valor Pendente:* R\$ ${totalPendente.toStringAsFixed(2)}
📋 *Total em Contas:* R\$ ${totalContas.toStringAsFixed(2)}
💯 *Total Geral:* R\$ ${(totalVendas + totalFiados + totalContas).toStringAsFixed(2)}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';

    // VENDAS
    if (vendas.isNotEmpty) {
      mensagem += '''
🛒 *HISTÓRICO DE VENDAS* (${vendas.length} vendas)
''';
      
      for (int i = 0; i < vendas.length && i < 10; i++) {
        final venda = vendas[i];
        final numeroVenda = (i + 1).toString().padLeft(3, '0');
        
        mensagem += '''
        
🛍️ *Venda #$numeroVenda* - ${formatter.format(venda.dataVenda)}
''';
        
        for (final item in venda.itens) {
          mensagem += '   • ${item.produto.nome} ${item.quantidade}${item.produto.unidade} - R\$ ${item.precoUnitario.toStringAsFixed(2)}\n';
        }
        
        mensagem += '   💰 *Total:* R\$ ${venda.total.toStringAsFixed(2)}\n';
        mensagem += '   💳 *Pagamento:* ${_getFormaPagamentoText(venda.formaPagamento)}';
      }
      
      if (vendas.length > 10) {
        mensagem += '\n\n... e mais ${vendas.length - 10} vendas';
      }
    }

    // FIADOS
    if (fiados.isNotEmpty) {
      mensagem += '''
      
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 *HISTÓRICO DE FIADOS* (${fiados.length} fiados)
''';
      
      for (int i = 0; i < fiados.length && i < 5; i++) {
        final fiado = fiados[i];
        final numeroFiado = (i + 1).toString().padLeft(3, '0');
        
        mensagem += '''
        
📝 *Fiado #$numeroFiado* - ${dateFormatter.format(fiado.dataFiado)}
   💰 *Total:* R\$ ${fiado.valorTotal.toStringAsFixed(2)}
   ✅ *Pago:* R\$ ${fiado.valorPago.toStringAsFixed(2)}
   ⏰ *Pendente:* R\$ ${fiado.valorRestante.toStringAsFixed(2)}
''';
        
        if (fiado.dataVencimento != null) {
          mensagem += '   📅 *Vencimento:* ${dateFormatter.format(fiado.dataVencimento!)}\n';
        }
        
                 mensagem += '   📋 *Observações:* ${fiado.observacao ?? 'Nenhuma'}';
      }
      
      if (fiados.length > 5) {
        mensagem += '\n\n... e mais ${fiados.length - 5} fiados';
      }
    }

    // CONTAS
    if (contas.isNotEmpty) {
      mensagem += '''
      
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 *HISTÓRICO DE CONTAS* (${contas.length} contas)
''';
      
      for (int i = 0; i < contas.length && i < 5; i++) {
        final conta = contas[i];
        final numeroConta = (i + 1).toString().padLeft(3, '0');
        
                 mensagem += '''
         
📄 *Conta #$numeroConta* - ${dateFormatter.format(conta.vencimento)}
   💰 *Valor:* R\$ ${conta.valor.toStringAsFixed(2)}
   📝 *Descrição:* ${conta.nome}
   ✅ *Status:* ${conta.status == StatusConta.pago ? 'Pago' : 'Pendente'}
''';
         
         if (conta.status == StatusConta.pago && conta.dataPagamento != null) {
           mensagem += '   💳 *Pago em:* ${dateFormatter.format(conta.dataPagamento!)}\n';
         }
      }
      
      if (contas.length > 5) {
        mensagem += '\n\n... e mais ${contas.length - 5} contas';
      }
    }

    mensagem += '''
    
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
📱 *Relatório gerado pelo Caderninho do Comerciante*
📅 *Data:* ${formatter.format(DateTime.now())}
🎯 *Obrigado pela preferência!*
''';

    return mensagem;
  }

  static String _formatarMensagemHistorico(Cliente cliente, List<Venda> vendas) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final totalGeral = vendas.fold(0.0, (sum, venda) => sum + venda.total);
    
    String mensagem = '''
🏪 *CADERNINHO DO COMERCIANTE*

👤 *Cliente:* ${cliente.nome}
📅 *Histórico de Compras*
''';

    if (vendas.isEmpty) {
      mensagem += '\n📝 Nenhuma compra registrada ainda.';
    } else {
      for (int i = 0; i < vendas.length; i++) {
        final venda = vendas[i];
        final numeroVenda = (i + 1).toString().padLeft(3, '0');
        
        mensagem += '''
        
🛒 *Compra #$numeroVenda* - ${formatter.format(venda.dataVenda)}
''';
        
        for (final item in venda.itens) {
          mensagem += '   • ${item.produto.nome} ${item.quantidade}${item.produto.unidade} - R\$ ${item.precoUnitario.toStringAsFixed(2)}\n';
        }
        
        mensagem += '   💰 *Total:* R\$ ${venda.total.toStringAsFixed(2)}\n';
        mensagem += '   💳 *Pagamento:* ${_getFormaPagamentoText(venda.formaPagamento)}';
      }
      
      mensagem += '''
      
💰 *Total Geral:* R\$ ${totalGeral.toStringAsFixed(2)}
📱 *Gerado pelo Caderninho do Comerciante*
''';
    }

    return mensagem;
  }

  static String _getFormaPagamentoText(FormaPagamento forma) {
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

  static String _criarUrlWhatsApp(String mensagem) {
    final mensagemCodificada = Uri.encodeComponent(mensagem);
    return 'https://wa.me/?text=$mensagemCodificada';
  }
} 