import 'package:flutter/material.dart';

import '../../../core/utils/whatsapp.dart';

Future<void> showCobrancaWhatsappSheet({
  required BuildContext context,
  required String nomeCliente,
  required double saldo,
  required double totalFiado,
  required double totalPago,
  required List<Lancamento> lancamentos,
  String? telefoneInicial,
  String? pixKey,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CobrancaWhatsappSheet(
      nomeCliente: nomeCliente,
      saldo: saldo,
      totalFiado: totalFiado,
      totalPago: totalPago,
      lancamentos: lancamentos,
      telefoneInicial: telefoneInicial,
      pixKey: pixKey,
    ),
  );
}

class _CobrancaWhatsappSheet extends StatefulWidget {
  const _CobrancaWhatsappSheet({
    required this.nomeCliente,
    required this.saldo,
    required this.totalFiado,
    required this.totalPago,
    required this.lancamentos,
    this.telefoneInicial,
    this.pixKey,
  });

  final String nomeCliente;
  final double saldo;
  final double totalFiado;
  final double totalPago;
  final List<Lancamento> lancamentos;
  final String? telefoneInicial;
  final String? pixKey;

  @override
  State<_CobrancaWhatsappSheet> createState() => _CobrancaWhatsappSheetState();
}

class _CobrancaWhatsappSheetState extends State<_CobrancaWhatsappSheet> {
  late final TextEditingController _phoneController;
  late final TextEditingController _extraController;
  bool _incluirHistorico = true;
  bool _incluirPix = false;
  bool _submitting = false;

  bool get _temPixKey => (widget.pixKey ?? '').trim().isNotEmpty;

  String get _preview {
    return buildMensagemCobranca(
      nome: widget.nomeCliente,
      saldo: widget.saldo,
      totalFiado: widget.totalFiado,
      totalPago: widget.totalPago,
      itens: widget.lancamentos,
      incluirHistorico: _incluirHistorico,
      msgExtra: _extraController.text,
      incluirPix: _incluirPix,
      pixKey: widget.pixKey,
    );
  }

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.telefoneInicial ?? '');
    _extraController = TextEditingController();
    _extraController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _extraController.removeListener(_onChanged);
    _phoneController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _handleOpenWhatsApp() async {
    if (widget.saldo <= 0 || _submitting) return;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o telefone do WhatsApp.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });
    try {
      await openWhatsApp(phoneRaw: phone, message: _preview);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel abrir o WhatsApp.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final canOpen = widget.saldo > 0 && !_submitting;
    final maxHeight = media.size.height * 0.9;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cobrar no WhatsApp',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                widget.nomeCliente,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone WhatsApp',
                  hintText: 'Ex.: (11) 99999-9999',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _extraController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mensagem extra (opcional)',
                ),
              ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _incluirHistorico,
                onChanged: (value) {
                  setState(() {
                    _incluirHistorico = value;
                  });
                },
                title: const Text('Incluir historico detalhado'),
              ),
              if (_temPixKey)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _incluirPix,
                  onChanged: (value) {
                    setState(() {
                      _incluirPix = value;
                    });
                  },
                  title: const Text('Incluir PIX'),
                ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview da mensagem',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(_preview),
                    ],
                  ),
                ),
              ),
              if (widget.saldo <= 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Cliente sem saldo pendente.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: canOpen ? _handleOpenWhatsApp : null,
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Abrir WhatsApp'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
