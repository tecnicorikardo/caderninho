import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/compromisso.dart';
import '../services/agenda_service.dart';

class TelaResumoAgenda extends StatefulWidget {
  const TelaResumoAgenda({Key? key}) : super(key: key);

  @override
  _TelaResumoAgendaState createState() => _TelaResumoAgendaState();
}

class _TelaResumoAgendaState extends State<TelaResumoAgenda> {
  final AgendaService _agendaService = AgendaService();
  
  Map<String, int> _estatisticas = {};
  List<Compromisso> _compromissosHoje = [];
  List<Compromisso> _compromissosProximos = [];
  List<Compromisso> _compromissosAtrasados = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    setState(() => _carregando = true);
    
    try {
      // Carregar dados em paralelo
      final futures = await Future.wait([
        _agendaService.obterEstatisticas(),
        _agendaService.buscarCompromissosHoje(),
        _agendaService.buscarCompromissosProximos(7),
        _agendaService.buscarCompromissosAtrasados(),
      ]);

      setState(() {
        _estatisticas = futures[0] as Map<String, int>;
        _compromissosHoje = futures[1] as List<Compromisso>;
        _compromissosProximos = futures[2] as List<Compromisso>;
        _compromissosAtrasados = futures[3] as List<Compromisso>;
      });
    } catch (e) {
      print('❌ Erro ao carregar resumo: $e');
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📊 Resumo da Agenda'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarResumo,
          ),
        ],
      ),
      body: _carregando
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarResumo,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEstatisticas(),
                    SizedBox(height: 20),
                    _buildCompromissosHoje(),
                    SizedBox(height: 20),
                    _buildCompromissosAtrasados(),
                    SizedBox(height: 20),
                    _buildCompromissosProximos(),
                    SizedBox(height: 20),
                    _buildAcoesRapidas(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEstatisticas() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Estatísticas Gerais',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEstatistica(
                    'Total',
                    _estatisticas['total'] ?? 0,
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildEstatistica(
                    'Pendentes',
                    _estatisticas['pendentes'] ?? 0,
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEstatistica(
                    'Concluídos',
                    _estatisticas['concluidos'] ?? 0,
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildEstatistica(
                    'Atrasados',
                    _estatisticas['atrasados'] ?? 0,
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatistica(String titulo, int valor, IconData icone, Color cor) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 24),
          SizedBox(height: 8),
          Text(
            valor.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(fontSize: 12, color: cor),
          ),
        ],
      ),
    );
  }

  Widget _buildCompromissosHoje() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Compromissos de Hoje',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Chip(
                  label: Text(_compromissosHoje.length.toString()),
                  backgroundColor: Colors.green.withValues(alpha: 0.2),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (_compromissosHoje.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_available, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Nenhum compromisso para hoje',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ..._compromissosHoje.map((compromisso) => 
                _buildCompromissoItem(compromisso)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompromissosAtrasados() {
    if (_compromissosAtrasados.isEmpty) return Container();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Compromissos Atrasados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Chip(
                  label: Text(_compromissosAtrasados.length.toString()),
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                ),
              ],
            ),
            SizedBox(height: 12),
            ..._compromissosAtrasados.map((compromisso) => 
              _buildCompromissoItem(compromisso, isAtrasado: true)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompromissosProximos() {
    final proximosLimitados = _compromissosProximos.take(5).toList();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upcoming, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Próximos 7 Dias',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Chip(
                  label: Text(_compromissosProximos.length.toString()),
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (proximosLimitados.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_available, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Nenhum compromisso nos próximos 7 dias',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else ...[
              ...proximosLimitados.map((compromisso) => 
                _buildCompromissoItem(compromisso)).toList(),
              if (_compromissosProximos.length > 5)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      'E mais ${_compromissosProximos.length - 5} compromissos...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompromissoItem(Compromisso compromisso, {bool isAtrasado = false}) {
    Color cor = isAtrasado ? Colors.red : 
               compromisso.status == StatusCompromisso.concluido ? Colors.green : 
               compromisso.isHoje ? Colors.orange : Colors.blue;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: BorderDirectional(
          start: BorderSide(
            width: 4,
            color: cor,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cor,
            child: Text(
              compromisso.icone,
              style: TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compromisso.descricao,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: compromisso.status == StatusCompromisso.concluido 
                        ? TextDecoration.lineThrough 
                        : null,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  compromisso.hora != null
                      ? '${compromisso.dataFormatada} às ${compromisso.hora}'
                      : compromisso.dataFormatada,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isAtrasado)
            Icon(Icons.error, color: Colors.red, size: 20),
        ],
      ),
    );
  }

  Widget _buildAcoesRapidas() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Ações Rápidas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Volta para agenda do dia atual
                    },
                    icon: Icon(Icons.add),
                    label: Text('Novo Compromisso'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Volta para agenda
                    },
                    icon: Icon(Icons.calendar_today),
                    label: Text('Ver Agenda'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
