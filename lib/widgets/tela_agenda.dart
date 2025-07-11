import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/compromisso.dart';
import '../services/agenda_service.dart';
import 'tela_resumo_agenda.dart';

class TelaAgenda extends StatefulWidget {
  const TelaAgenda({Key? key}) : super(key: key);

  @override
  _TelaAgendaState createState() => _TelaAgendaState();
}

class _TelaAgendaState extends State<TelaAgenda> {
  final AgendaService _agendaService = AgendaService();
  DateTime _dataSelecionada = DateTime.now();
  List<Compromisso> _compromissos = [];
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _inicializarAgenda();
  }

  Future<void> _inicializarAgenda() async {
    setState(() => _carregando = true);
    
    try {
      // Primeiro verificar se a tabela existe
      await _agendaService.verificarTabelaCompromissos();
      
      // Depois carregar os dados
      await _carregarDados();
    } catch (e) {
      print('❌ Erro na inicialização da agenda: $e');
      setState(() => _erro = 'Erro ao inicializar: $e');
    } finally {
      setState(() => _carregando = false);
    }
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    
    try {
      print('🔄 Carregando compromissos para: ${_dataSelecionada.day}/${_dataSelecionada.month}/${_dataSelecionada.year}');
      
      final compromissos = await _agendaService.buscarCompromissosPorData(_dataSelecionada);
      
      print('📋 Compromissos carregados: ${compromissos.length}');
      for (var comp in compromissos) {
        print('  - ${comp.descricao} (${comp.dataFormatada})');
      }
      
      setState(() => _compromissos = compromissos);
    } catch (e) {
      print('❌ Erro ao carregar compromissos: $e');
      setState(() => _erro = 'Erro ao carregar compromissos: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar compromissos: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📅 Agenda'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _dataSelecionada,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _dataSelecionada = picked);
                _carregarDados();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.dashboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TelaResumoAgenda(),
                ),
              );
            },
            tooltip: 'Resumo da Agenda',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _carregando
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando compromissos...'),
                ],
              ),
            )
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Erro na agenda',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _erro!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _inicializarAgenda,
                        child: Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.deepPurple,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              setState(() => _dataSelecionada = _dataSelecionada.subtract(Duration(days: 1)));
                              _carregarDados();
                            },
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_dataSelecionada),
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward, color: Colors.white),
                            onPressed: () {
                              setState(() => _dataSelecionada = _dataSelecionada.add(Duration(days: 1)));
                              _carregarDados();
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _compromissos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_available, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('Nenhum compromisso para este dia'),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => _mostrarFormulario(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Adicionar Compromisso'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: _compromissos.length,
                              itemBuilder: (context, index) {
                                final compromisso = _compromissos[index];
                                final cor = compromisso.status == StatusCompromisso.pendente
                                    ? Colors.orange
                                    : compromisso.status == StatusCompromisso.concluido
                                        ? Colors.green
                                        : Colors.grey;

                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: cor,
                                      child: Text(compromisso.icone),
                                    ),
                                    title: Text(compromisso.descricao),
                                    subtitle: Text(compromisso.hora != null
                                        ? '${compromisso.dataFormatada} às ${compromisso.hora}'
                                        : compromisso.dataFormatada),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) => _executarAcao(compromisso, value),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                                        if (compromisso.status == StatusCompromisso.pendente)
                                          PopupMenuItem(value: 'concluir', child: Text('Concluir')),
                                        PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormulario,
        child: Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  Future<void> _executarAcao(Compromisso compromisso, String acao) async {
    try {
      switch (acao) {
        case 'editar':
          _mostrarFormulario(compromisso: compromisso);
          break;
        case 'concluir':
          await _agendaService.marcarComoConcluido(compromisso.id);
          _carregarDados();
          break;
        case 'excluir':
          final confirma = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Confirmar'),
              content: Text('Excluir "${compromisso.descricao}"?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Excluir')),
              ],
            ),
          );
          if (confirma == true) {
            await _agendaService.excluirCompromisso(compromisso.id);
            _carregarDados();
          }
          break;
      }
    } catch (e) {
      print('❌ Erro ao executar ação: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao executar ação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarFormulario({Compromisso? compromisso}) {
    final descricaoController = TextEditingController(text: compromisso?.descricao ?? '');
    final horaController = TextEditingController(text: compromisso?.hora ?? '');
    DateTime dataForm = compromisso?.data ?? _dataSelecionada;
    bool alerta = compromisso?.alertaUmDiaAntes ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(compromisso == null ? 'Novo Compromisso' : 'Editar Compromisso'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descricaoController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dataForm,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => dataForm = picked);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(DateFormat('dd/MM/yyyy').format(dataForm)),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: horaController,
                        decoration: InputDecoration(
                          labelText: 'Hora',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => horaController.text = picked.format(context));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: alerta,
                      onChanged: (value) => setDialogState(() => alerta = value ?? false),
                    ),
                    Text('Lembrar um dia antes'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (descricaoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Descrição é obrigatória'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final novoCompromisso = Compromisso(
                    id: compromisso?.id,
                    data: dataForm,
                    hora: horaController.text.isNotEmpty ? horaController.text : null,
                    descricao: descricaoController.text.trim(),
                    alertaUmDiaAntes: alerta,
                    dataCriacao: compromisso?.dataCriacao,
                  );

                  print('💾 Tentando salvar compromisso: ${novoCompromisso.descricao}');

                  if (compromisso == null) {
                    await _agendaService.adicionarCompromisso(novoCompromisso);
                  } else {
                    await _agendaService.atualizarCompromisso(novoCompromisso);
                  }

                  Navigator.pop(context);
                  _carregarDados();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Compromisso salvo com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Erro ao salvar compromisso: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao salvar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
} 