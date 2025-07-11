import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/compromisso.dart';
import 'database_service.dart';
import 'notification_service.dart';

class AgendaService {
  static final AgendaService _instance = AgendaService._internal();
  factory AgendaService() => _instance;
  AgendaService._internal();

  // Verificar e enviar notificações pendentes
  Future<void> verificarNotificacoesPendentes() async {
    try {
      final compromissos = await buscarCompromissos();
      
      for (final compromisso in compromissos) {
        if (compromisso.precisaNotificacao) {
          await _enviarNotificacao(compromisso);
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar notificações: $e');
    }
  }

  // Enviar notificação
  Future<void> _enviarNotificacao(Compromisso compromisso) async {
    try {
      await NotificationService.instance.agendarNotificacaoCompromisso(compromisso);
      
      // Marcar que a notificação foi enviada
      await atualizarDataNotificacao(compromisso.id, DateTime.now());
      
    } catch (e) {
      debugPrint('Erro ao enviar notificação: $e');
    }
  }

  // Buscar todos os compromissos
  Future<List<Compromisso>> buscarCompromissos() async {
    try {
      final db = await DatabaseService.instance.database;
      final maps = await db.query('compromissos', orderBy: 'data ASC');
      return maps.map((map) => Compromisso.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar compromissos: $e');
      return [];
    }
  }

  // Método para backup - buscar todos os compromissos
  Future<List<Compromisso>> getCompromissos() async {
    return await buscarCompromissos();
  }

  // Buscar compromissos por data
  Future<List<Compromisso>> buscarCompromissosPorData(DateTime data) async {
    try {
      final db = await DatabaseService.instance.database;
      final inicioDia = DateTime(data.year, data.month, data.day);
      final fimDia = DateTime(data.year, data.month, data.day, 23, 59, 59);
      
      debugPrint('🔍 Buscando compromissos para: ${data.day}/${data.month}/${data.year}');
      debugPrint('🔍 Período: ${inicioDia.millisecondsSinceEpoch} - ${fimDia.millisecondsSinceEpoch}');
      
      final maps = await db.query(
        'compromissos',
        where: 'data >= ? AND data <= ?',
        whereArgs: [inicioDia.millisecondsSinceEpoch, fimDia.millisecondsSinceEpoch],
        orderBy: 'data ASC',
      );
      
      debugPrint('🔍 Encontrados ${maps.length} compromissos');
      return maps.map((map) => Compromisso.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar compromissos por data: $e');
      return [];
    }
  }

  // Buscar compromissos por mês
  Future<List<Compromisso>> buscarCompromissosPorMes(int ano, int mes) async {
    try {
      final db = await DatabaseService.instance.database;
      final inicioMes = DateTime(ano, mes, 1);
      final fimMes = DateTime(ano, mes + 1, 0, 23, 59, 59);
      
      final maps = await db.query(
        'compromissos',
        where: 'data >= ? AND data <= ?',
        whereArgs: [inicioMes.millisecondsSinceEpoch, fimMes.millisecondsSinceEpoch],
        orderBy: 'data ASC',
      );
      
      return maps.map((map) => Compromisso.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar compromissos por mês: $e');
      return [];
    }
  }

  // Buscar compromissos de hoje
  Future<List<Compromisso>> buscarCompromissosHoje() async {
    return await buscarCompromissosPorData(DateTime.now());
  }

  // Buscar compromissos pendentes
  Future<List<Compromisso>> buscarCompromissosPendentes() async {
    try {
      final db = await DatabaseService.instance.database;
      final maps = await db.query(
        'compromissos',
        where: 'status = ?',
        whereArgs: [StatusCompromisso.pendente.index],
        orderBy: 'data ASC',
      );
      return maps.map((map) => Compromisso.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar compromissos pendentes: $e');
      return [];
    }
  }

  // Buscar compromissos atrasados
  Future<List<Compromisso>> buscarCompromissosAtrasados() async {
    final pendentes = await buscarCompromissosPendentes();
    return pendentes.where((c) => c.isAtrasado).toList();
  }

  // Buscar compromissos dos próximos dias
  Future<List<Compromisso>> buscarCompromissosProximos(int dias) async {
    try {
      final db = await DatabaseService.instance.database;
      final hoje = DateTime.now();
      final futuro = hoje.add(Duration(days: dias));
      
      final maps = await db.query(
        'compromissos',
        where: 'data >= ? AND data <= ? AND status = ?',
        whereArgs: [
          hoje.millisecondsSinceEpoch,
          futuro.millisecondsSinceEpoch,
          StatusCompromisso.pendente.index,
        ],
        orderBy: 'data ASC',
      );
      
      return maps.map((map) => Compromisso.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar compromissos próximos: $e');
      return [];
    }
  }

  // Adicionar compromisso
  Future<void> adicionarCompromisso(Compromisso compromisso) async {
    try {
      final db = await DatabaseService.instance.database;
      debugPrint('💾 Salvando compromisso: ${compromisso.descricao}');
      debugPrint('💾 Data: ${compromisso.data}');
      debugPrint('💾 Dados: ${compromisso.toMap()}');
      
      await db.insert('compromissos', compromisso.toMap());
      
      // Agendar notificação se necessário (não interrompe se falhar)
      if (compromisso.alertaUmDiaAntes) {
        try {
          await NotificationService.instance.agendarNotificacaoCompromisso(compromisso);
        } catch (e) {
          debugPrint('⚠️ Erro ao agendar notificação: $e');
        }
      }
      
      debugPrint('✅ Compromisso salvo com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao adicionar compromisso: $e');
      rethrow;
    }
  }

  // Atualizar compromisso
  Future<void> atualizarCompromisso(Compromisso compromisso) async {
    try {
      final db = await DatabaseService.instance.database;
      debugPrint('🔄 Atualizando compromisso: ${compromisso.id}');
      
      // Cancela notificação antiga (não interrompe se falhar)
      try {
        await NotificationService.instance.cancelarNotificacaoCompromisso(compromisso.id);
      } catch (e) {
        debugPrint('⚠️ Erro ao cancelar notificação antiga: $e');
      }
      
      await db.update(
        'compromissos',
        compromisso.toMap(),
        where: 'id = ?',
        whereArgs: [compromisso.id],
      );
      
      // Reagenda notificação se necessário (não interrompe se falhar)
      if (compromisso.alertaUmDiaAntes && compromisso.status == StatusCompromisso.pendente) {
        try {
          await NotificationService.instance.agendarNotificacaoCompromisso(compromisso);
        } catch (e) {
          debugPrint('⚠️ Erro ao reagendar notificação: $e');
        }
      }
      
      debugPrint('✅ Compromisso atualizado com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar compromisso: $e');
      rethrow;
    }
  }

  // Atualizar apenas o status
  Future<void> atualizarStatusCompromisso(String id, StatusCompromisso status) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.update(
        'compromissos',
        {'status': status.index},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('❌ Erro ao atualizar status: $e');
      rethrow;
    }
  }

  // Atualizar data de notificação
  Future<void> atualizarDataNotificacao(String id, DateTime dataNotificacao) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.update(
        'compromissos',
        {'dataNotificacao': dataNotificacao.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('❌ Erro ao atualizar data notificação: $e');
    }
  }

  // Excluir compromisso
  Future<void> excluirCompromisso(String id) async {
    try {
      final db = await DatabaseService.instance.database;
      debugPrint('🗑️ Excluindo compromisso: $id');
      
      // Cancela notificação (não interrompe se falhar)
      try {
        await NotificationService.instance.cancelarNotificacaoCompromisso(id);
      } catch (e) {
        debugPrint('⚠️ Erro ao cancelar notificação: $e');
      }
      
      await db.delete(
        'compromissos',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('✅ Compromisso excluído com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao excluir compromisso: $e');
      rethrow;
    }
  }

  // Buscar compromisso por ID
  Future<Compromisso?> buscarCompromissoPorId(String id) async {
    try {
      final db = await DatabaseService.instance.database;
      final maps = await db.query(
        'compromissos',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return Compromisso.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao buscar compromisso por ID: $e');
      return null;
    }
  }

  // Marcar como concluído
  Future<void> marcarComoConcluido(String id) async {
    await atualizarStatusCompromisso(id, StatusCompromisso.concluido);
  }

  // Marcar como pendente
  Future<void> marcarComoPendente(String id) async {
    await atualizarStatusCompromisso(id, StatusCompromisso.pendente);
  }

  // Marcar como cancelado
  Future<void> marcarComoCancelado(String id) async {
    await atualizarStatusCompromisso(id, StatusCompromisso.cancelado);
  }

  // Estatísticas
  Future<Map<String, int>> obterEstatisticas() async {
    try {
      final todos = await buscarCompromissos();
      final hoje = await buscarCompromissosHoje();
      final pendentes = await buscarCompromissosPendentes();
      final atrasados = await buscarCompromissosAtrasados();
      final proximos = await buscarCompromissosProximos(7);
      
      return {
        'total': todos.length,
        'hoje': hoje.length,
        'pendentes': pendentes.length,
        'atrasados': atrasados.length,
        'proximos': proximos.length,
        'concluidos': todos.where((c) => c.status == StatusCompromisso.concluido).length,
      };
    } catch (e) {
      debugPrint('❌ Erro ao obter estatísticas: $e');
      return {
        'total': 0,
        'hoje': 0,
        'pendentes': 0,
        'atrasados': 0,
        'proximos': 0,
        'concluidos': 0,
      };
    }
  }

  // Método para verificar se tabela existe e criar se necessário
  Future<void> verificarTabelaCompromissos() async {
    try {
      final db = await DatabaseService.instance.database;
      
      // Verificar se a tabela existe
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='compromissos'"
      );
      
      if (result.isEmpty) {
        debugPrint('⚠️ Tabela compromissos não existe, criando...');
        await db.execute('''
          CREATE TABLE compromissos (
            id TEXT PRIMARY KEY,
            data INTEGER NOT NULL,
            hora TEXT,
            descricao TEXT NOT NULL,
            status INTEGER NOT NULL,
            alertaUmDiaAntes INTEGER NOT NULL,
            dataCriacao INTEGER NOT NULL,
            dataNotificacao INTEGER
          )
        ''');
        debugPrint('✅ Tabela compromissos criada!');
      } else {
        debugPrint('✅ Tabela compromissos já existe');
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar tabela: $e');
    }
  }
}