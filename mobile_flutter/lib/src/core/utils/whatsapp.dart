import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'formatters.dart';

enum LancamentoTipo { fiado, pagamento }

class Lancamento {
  const Lancamento({
    required this.data,
    required this.valor,
    required this.tipo,
    this.observacao,
  });

  final DateTime data;
  final double valor;
  final LancamentoTipo tipo;
  final String? observacao;
}

String buildMensagemCobranca({
  required String nome,
  required double saldo,
  required double totalFiado,
  required double totalPago,
  required List<Lancamento> itens,
  required bool incluirHistorico,
  String? msgExtra,
  bool incluirPix = false,
  String? pixKey,
}) {
  final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final historicoOrdenado = [...itens]
    ..sort((a, b) => b.data.compareTo(a.data));
  final ultimosItens = historicoOrdenado.take(10).toList();

  final linhas = <String>[
    'Oi, $nome! Tudo bem?',
    '',
    'Estou passando para lembrar do seu fiado:',
    'Saldo pendente: ${currency.format(saldo)}',
    '',
    'Resumo',
    '- Total fiado: ${currency.format(totalFiado)}',
    '- Total pago: ${currency.format(totalPago)}',
    '- Lancamentos: ${itens.length}',
  ];

  if (incluirHistorico) {
    linhas.add('');
    linhas.add('Historico (ultimos ${ultimosItens.length})');
    if (ultimosItens.isEmpty) {
      linhas.add('- Sem lancamentos para exibir.');
    } else {
      for (final item in ultimosItens) {
        final tipo = item.tipo == LancamentoTipo.fiado ? 'FIADO' : 'PAGAMENTO';
        final obs = (item.observacao ?? '').trim();
        final obsPart = obs.isEmpty ? '' : ' (${truncateText(obs)})';
        linhas.add(
          '${formatShortDate(item.data)} - $tipo: ${currency.format(item.valor)}$obsPart',
        );
      }
    }
  }

  final extra = (msgExtra ?? '').trim();
  if (extra.isNotEmpty) {
    linhas..add('')..add(extra);
  }

  final pix = (pixKey ?? '').trim();
  if (incluirPix && pix.isNotEmpty) {
    linhas
      ..add('')
      ..add('PIX para pagamento: $pix');
  }

  linhas
    ..add('')
    ..add('Qualquer duvida me avise \u{1F60A}');
  return linhas.join('\n');
}

Future<void> openWhatsApp({
  required String phoneRaw,
  required String message,
}) async {
  final phone = normalizeWhatsappPhone(phoneRaw);
  if (phone.isEmpty) {
    throw StateError('Telefone invalido para WhatsApp.');
  }
  final url = Uri.parse(
    'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
  );
  final launched = await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
  if (!launched) {
    throw StateError('Nao foi possivel abrir o WhatsApp.');
  }
}
