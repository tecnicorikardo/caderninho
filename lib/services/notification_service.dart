import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import '../models/fiado.dart';
import 'database_service.dart';
import '../services/agenda_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Inicializa o serviço de notificações
  Future<void> inicializar() async {
    try {
      // Inicializar timezone
      tz.initializeTimeZones();

      // Configurações para Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configurações para iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Configurações iniciais
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Inicializar plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Solicitar permissões
      await _solicitarPermissoes();
      
      print('🔔 Serviço de notificações inicializado com sucesso');
    } catch (e) {
      print('❌ Erro ao inicializar notificações: $e');
    }
  }

  /// Solicita permissões para notificações
  Future<void> _solicitarPermissoes() async {
    try {
      // Para Android, solicitar permissão
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        
        // Para Android 12+ (API 31+), verificar permissão de alarmes exatos
        try {
          final exactAlarmsPermitted = await androidPlugin.requestExactAlarmsPermission();
          print('🔔 Permissão para alarmes exatos: $exactAlarmsPermitted');
        } catch (e) {
          print('⚠️ Não foi possível solicitar permissão para alarmes exatos: $e');
        }
      }
      
      // Para iOS, solicitar permissões
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      print('❌ Erro ao solicitar permissões: $e');
    }
  }

  /// Agenda notificação para fiado vencido
  Future<void> agendarNotificacaoFiado(Fiado fiado) async {
    if (fiado.dataVencimento == null) return;

    final id = int.parse(fiado.id.replaceAll(RegExp(r'[^0-9]'), ''));
    
    // Notificação para o dia do vencimento
    await _agendarNotificacao(
      id: id,
      titulo: 'Fiado Vencido!',
      corpo: 'O fiado de ${fiado.cliente.nome} venceu hoje. Valor: R\$ ${fiado.valorTotal.toStringAsFixed(2)}',
      data: fiado.dataVencimento!,
    );

    // Notificação 3 dias antes do vencimento
    final dataAviso = fiado.dataVencimento!.subtract(const Duration(days: 3));
    if (dataAviso.isAfter(DateTime.now())) {
      await _agendarNotificacao(
        id: id + 1000, // ID diferente para não conflitar
        titulo: 'Fiado Vence em 3 dias',
        corpo: 'O fiado de ${fiado.cliente.nome} vence em 3 dias. Valor: R\$ ${fiado.valorTotal.toStringAsFixed(2)}',
        data: dataAviso,
      );
    }
  }

  /// Agenda uma notificação específica
  Future<void> _agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'fiados_vencidos',
      'Fiados Vencidos',
      channelDescription: 'Notificações sobre fiados vencidos',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFFE74C3C),
      enableLights: true,
      enableVibration: true,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _agendarNotificacaoSegura(id, titulo, corpo, data, details);
  }

  /// Método seguro para agendar notificações (lida com permissões Android 13+)
  Future<void> _agendarNotificacaoSegura(
    int id, 
    String titulo, 
    String corpo, 
    DateTime data, 
    NotificationDetails details
  ) async {
    try {
      await _notifications.zonedSchedule(
        id,
        titulo,
        corpo,
        tz.TZDateTime.from(data, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('🔔 Notificação agendada (exata): $titulo para ${data.toString()}');
    } catch (e) {
      print('⚠️ Erro ao agendar notificação exata, tentando modo aproximado: $e');
      try {
        // Fallback para modo aproximado se alarmes exatos não estiverem disponíveis
        await _notifications.zonedSchedule(
          id,
          titulo,
          corpo,
          tz.TZDateTime.from(data, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('🔔 Notificação agendada (aproximada): $titulo');
      } catch (e2) {
        print('❌ Erro ao agendar notificação: $e2');
        
        // Último fallback: mostrar notificação imediata
        try {
          await _notifications.show(
            id,
            '⚠️ $titulo',
            'Agendamento: $corpo',
            details,
          );
          print('🔔 Notificação mostrada imediatamente devido a erro de agendamento');
        } catch (e3) {
          print('❌ Falha completa ao mostrar notificação: $e3');
          rethrow;
        }
      }
    }
  }

  /// Cancela notificação de um fiado específico
  Future<void> cancelarNotificacaoFiado(String fiadoId) async {
    try {
      final id = int.parse(fiadoId.replaceAll(RegExp(r'[^0-9]'), ''));
      await _notifications.cancel(id);
      await _notifications.cancel(id + 1000); // Cancela também o aviso antecipado
      print('🔔 Notificações do fiado $fiadoId canceladas');
    } catch (e) {
      print('⚠️ Erro ao cancelar notificações do fiado: $e');
      // Não relança o erro para não interromper o fluxo
    }
  }

  /// Cancela todas as notificações
  Future<void> cancelarTodasNotificacoes() async {
    try {
      await _notifications.cancelAll();
      print('🔔 Todas as notificações canceladas');
    } catch (e) {
      print('⚠️ Erro ao cancelar todas as notificações: $e');
      // Não relança o erro para não interromper o fluxo
    }
  }

  /// Agenda notificações para todos os fiados pendentes
  Future<void> agendarNotificacoesFiados() async {
    try {
      final db = DatabaseService.instance;
      final fiados = await db.getFiados();
      
      // Cancela notificações antigas
      await cancelarTodasNotificacoes();
      
      // Agenda novas notificações
      for (final fiado in fiados) {
        if (fiado.dataVencimento != null && 
            fiado.dataVencimento!.isAfter(DateTime.now())) {
          await agendarNotificacaoFiado(fiado);
        }
      }
    } catch (e) {
      print('Erro ao agendar notificações: $e');
    }
  }

  /// Mostra notificação imediata (para testes)
  Future<void> mostrarNotificacaoTeste() async {
    const androidDetails = AndroidNotificationDetails(
      'teste',
      'Teste',
      channelDescription: 'Canal de teste',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '🔔 Teste de Notificação',
      'Esta é uma notificação de teste do Caderninho! As notificações estão funcionando corretamente.',
      details,
    );
  }

  /// Agenda notificação recorrente da agenda
  Future<void> agendarNotificacaoRecorrenteAgenda(int intervaloHoras) async {
    await _notifications.cancel(777);
    final compromissos = await AgendaService().buscarCompromissosPendentes();
    if (compromissos.isEmpty) return;
    final corpo = compromissos.length == 1
      ? 'Você tem 1 compromisso pendente na agenda.'
      : 'Você tem ${compromissos.length} compromissos pendentes na agenda.';
    final androidDetails = AndroidNotificationDetails(
      'agenda_recorrente',
      'Agenda Recorrente',
      channelDescription: 'Notificações recorrentes da agenda',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF1976D2),
      enableLights: true,
      enableVibration: true,
    );
    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    if (intervaloHoras == 24) {
      await _notifications.periodicallyShow(
        777,
        '⏰ Lembrete da Agenda',
        corpo,
        RepeatInterval.daily,
        details,
        androidAllowWhileIdle: true,
      );
    } else {
      // Para todos os outros intervalos, usar zonedSchedule e reagendar manualmente
      final agora = DateTime.now();
      final proxima = agora.add(Duration(hours: intervaloHoras));
      await _notifications.zonedSchedule(
        777,
        '⏰ Lembrete da Agenda',
        corpo,
        tz.TZDateTime.from(proxima, tz.local),
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
        payload: 'recorrente',
      );
    }
  }

  /// Callback quando notificação é tocada
  void _onNotificationTapped(NotificationResponse response) {
    // Aqui você pode adicionar navegação para a tela de fiados
    print('Notificação tocada: ${response.payload}');
  }

  /// ========== NOTIFICAÇÕES DE COMPROMISSOS (AGENDA) ==========
  
  /// Agenda notificação para compromisso específico
  Future<void> agendarNotificacaoCompromisso(dynamic compromisso) async {
    if (!compromisso.alertaUmDiaAntes) return;
    
    final id = compromisso.id.hashCode % 100000 + 2000; // IDs de 2000-102000
    
    // Notificação no dia anterior (às 20h)
    final dataNotificacao = DateTime(
      compromisso.data.year,
      compromisso.data.month,
      compromisso.data.day - 1,
      20, // 20h
      0,
    );
    
    if (dataNotificacao.isAfter(DateTime.now())) {
      await _agendarNotificacaoCompromisso(
        id: id,
        titulo: '📅 Lembrete de Compromisso',
        corpo: 'Amanhã: ${compromisso.descricao}${compromisso.hora != null ? ' às ${compromisso.hora}' : ''}',
        data: dataNotificacao,
      );
    }
    
    // Notificação no dia do compromisso (1h antes ou às 8h se não tiver hora)
    DateTime dataCompromisso;
    if (compromisso.hora != null) {
      // 1 hora antes do horário marcado
      final horaPartes = compromisso.hora!.split(':');
      final hora = int.parse(horaPartes[0]);
      final minuto = int.parse(horaPartes[1]);
      dataCompromisso = DateTime(
        compromisso.data.year,
        compromisso.data.month,
        compromisso.data.day,
        hora - 1, // 1 hora antes
        minuto,
      );
    } else {
      // Às 8h do dia
      dataCompromisso = DateTime(
        compromisso.data.year,
        compromisso.data.month,
        compromisso.data.day,
        8,
        0,
      );
    }
    
    if (dataCompromisso.isAfter(DateTime.now())) {
      await _agendarNotificacaoCompromisso(
        id: id + 1,
        titulo: '🔥 Compromisso Hoje!',
        corpo: '${compromisso.descricao}${compromisso.hora != null ? ' às ${compromisso.hora}' : ''}',
        data: dataCompromisso,
      );
    }
  }
  
  /// Agenda notificação específica para compromisso
  Future<void> _agendarNotificacaoCompromisso({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'compromissos',
      'Compromissos',
      channelDescription: 'Notificações de compromissos da agenda',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF1976D2),
      enableLights: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _agendarNotificacaoSegura(id, titulo, corpo, data, details);
  }
  
  /// Cancela notificações de um compromisso específico
  Future<void> cancelarNotificacaoCompromisso(String compromissoId) async {
    try {
      final id = compromissoId.hashCode % 100000 + 2000;
      await _notifications.cancel(id);
      await _notifications.cancel(id + 1);
      print('🔔 Notificações do compromisso $compromissoId canceladas');
    } catch (e) {
      print('⚠️ Erro ao cancelar notificações do compromisso: $e');
      // Não relança o erro para não interromper o fluxo
    }
  }
  
  /// ========== NOTIFICAÇÕES DE CONTAS ==========
  
  /// Agenda notificação para conta específica
  Future<void> agendarNotificacaoConta(dynamic conta) async {
    final id = conta.id.hashCode % 100000 + 3000; // IDs de 3000-103000
    
    // Notificação 3 dias antes do vencimento
    final dataAviso3Dias = conta.vencimento.subtract(const Duration(days: 3));
    if (dataAviso3Dias.isAfter(DateTime.now())) {
      await _agendarNotificacaoConta(
        id: id,
        titulo: '⚠️ Conta Vence em 3 dias',
        corpo: '${conta.nome} - R\$ ${conta.valor.toStringAsFixed(2)}',
        data: DateTime(dataAviso3Dias.year, dataAviso3Dias.month, dataAviso3Dias.day, 9, 0),
      );
    }
    
    // Notificação 1 dia antes do vencimento
    final dataAviso1Dia = conta.vencimento.subtract(const Duration(days: 1));
    if (dataAviso1Dia.isAfter(DateTime.now())) {
      await _agendarNotificacaoConta(
        id: id + 1,
        titulo: '🔔 Conta Vence Amanhã!',
        corpo: '${conta.nome} - R\$ ${conta.valor.toStringAsFixed(2)}',
        data: DateTime(dataAviso1Dia.year, dataAviso1Dia.month, dataAviso1Dia.day, 18, 0), // 18h
      );
    }
    
    // Notificação no dia do vencimento
    if (conta.vencimento.isAfter(DateTime.now())) {
      await _agendarNotificacaoConta(
        id: id + 2,
        titulo: '🚨 Conta Vence Hoje!',
        corpo: '${conta.nome} - R\$ ${conta.valor.toStringAsFixed(2)}',
        data: DateTime(conta.vencimento.year, conta.vencimento.month, conta.vencimento.day, 8, 0), // 8h
      );
    }
  }
  
  /// Agenda notificação específica para conta
  Future<void> _agendarNotificacaoConta({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'contas_vencimento',
      'Contas a Pagar',
      channelDescription: 'Notificações de vencimento de contas',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFFFF9800),
      enableLights: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _agendarNotificacaoSegura(id, titulo, corpo, data, details);
  }
  
  /// Cancela notificações de uma conta específica
  Future<void> cancelarNotificacaoConta(String contaId) async {
    try {
      final id = contaId.hashCode % 100000 + 3000;
      await _notifications.cancel(id);
      await _notifications.cancel(id + 1);
      await _notifications.cancel(id + 2);
      print('🔔 Notificações da conta $contaId canceladas');
    } catch (e) {
      print('⚠️ Erro ao cancelar notificações da conta: $e');
      // Não relança o erro para não interromper o fluxo
    }
  }
  
  /// ========== REAGENDAMENTO COMPLETO ==========
  
  /// Reagenda todas as notificações (fiados, compromissos e contas)
  Future<void> reagendarTodasNotificacoes() async {
    try {
      print('🔔 Iniciando reagendamento de todas as notificações...');
      
      // Cancela todas as notificações existentes
      await cancelarTodasNotificacoes();
      
      final db = DatabaseService.instance;
      
      // Reagendar fiados
      final fiados = await db.getFiados();
      for (final fiado in fiados) {
        if (fiado.dataVencimento != null && 
            fiado.dataVencimento!.isAfter(DateTime.now()) &&
            fiado.valorPago < fiado.valorTotal) {
          await agendarNotificacaoFiado(fiado);
        }
      }
      print('🔔 Reagendados ${fiados.length} fiados');
      
      // Reagendar compromissos
      final compromissosQuery = await (await db.database).query('compromissos');
      int compromissosCount = 0;
      for (final compMap in compromissosQuery) {
        final compromisso = _createCompromissoFromMap(compMap);
        if (compromisso.alertaUmDiaAntes && 
            compromisso.data.isAfter(DateTime.now()) &&
            compromisso.status == 0) { // StatusCompromisso.pendente
          await agendarNotificacaoCompromisso(compromisso);
          compromissosCount++;
        }
      }
      print('🔔 Reagendados $compromissosCount compromissos');
      
      // Reagendar contas
      final contasQuery = await (await db.database).query('contas');
      int contasCount = 0;
      for (final contaMap in contasQuery) {
        final conta = _createContaFromMap(contaMap);
        if (conta.vencimento.isAfter(DateTime.now()) &&
            conta.status == 0) { // StatusConta.pendente
          await agendarNotificacaoConta(conta);
          contasCount++;
        }
      }
      print('🔔 Reagendadas $contasCount contas');
      
      print('🔔 Reagendamento completo finalizado!');
    } catch (e) {
      print('❌ Erro ao reagendar notificações: $e');
    }
  }
  
  /// Helpers para criar objetos a partir de mapas
  dynamic _createCompromissoFromMap(Map<String, dynamic> map) {
    return _CompromissoHelper(
      id: map['id'],
      data: DateTime.fromMillisecondsSinceEpoch(map['data']),
      hora: map['hora'],
      descricao: map['descricao'],
      status: map['status'] ?? 0,
      alertaUmDiaAntes: map['alertaUmDiaAntes'] == 1,
    );
  }
  
  dynamic _createContaFromMap(Map<String, dynamic> map) {
    return _ContaHelper(
      id: map['id'],
      nome: map['nome'],
      valor: (map['valor'] as num).toDouble(),
      vencimento: DateTime.fromMillisecondsSinceEpoch(map['vencimento']),
      status: map['status'] ?? 0,
    );
  }

  /// Verifica se as notificações estão habilitadas
  Future<bool> notificacoesHabilitadas() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    
    return true; // Assume que está habilitado se não conseguir verificar
  }
}

/// Helper classes para evitar dependências circulares
class _CompromissoHelper {
  final String id;
  final DateTime data;
  final String? hora;
  final String descricao;
  final int status;
  final bool alertaUmDiaAntes;
  
  _CompromissoHelper({
    required this.id,
    required this.data,
    this.hora,
    required this.descricao,
    required this.status,
    required this.alertaUmDiaAntes,
  });
}

class _ContaHelper {
  final String id;
  final String nome;
  final double valor;
  final DateTime vencimento;
  final int status;
  
  _ContaHelper({
    required this.id,
    required this.nome,
    required this.valor,
    required this.vencimento,
    required this.status,
  });
} 