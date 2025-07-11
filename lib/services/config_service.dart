import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ConfigService extends ChangeNotifier {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  static ConfigService get instance => _instance;

  // Chaves para SharedPreferences
  static const String _keyNomeComerciante = 'nome_comerciante';
  static const String _keyTelefoneComerciante = 'telefone_comerciante';
  static const String _keyEnderecoComerciante = 'endereco_comerciante';
  static const String _keyTema = 'tema';
  static const String _keyNotificacoesFiado = 'notificacoes_fiado';

  // Dados do comerciante
  String _nomeComerciante = '';
  String _telefoneComerciante = '';
  String _enderecoComerciante = '';

  // Preferências
  String _tema = 'system'; // 'light', 'dark', 'system'
  bool _notificacoesFiado = true;

  // Getters
  String get nomeComerciante => _nomeComerciante;
  String get telefoneComerciante => _telefoneComerciante;
  String get enderecoComerciante => _enderecoComerciante;
  String get tema => _tema;
  bool get notificacoesFiado => _notificacoesFiado;

  /// Carrega todas as configurações
  Future<void> carregarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    
    _nomeComerciante = prefs.getString(_keyNomeComerciante) ?? '';
    _telefoneComerciante = prefs.getString(_keyTelefoneComerciante) ?? '';
    _enderecoComerciante = prefs.getString(_keyEnderecoComerciante) ?? '';
    _tema = prefs.getString(_keyTema) ?? 'system';
    _notificacoesFiado = prefs.getBool(_keyNotificacoesFiado) ?? true;
  }

  /// Salva dados do comerciante
  Future<void> salvarDadosComerciante({
    required String nome,
    required String telefone,
    required String endereco,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_keyNomeComerciante, nome);
    await prefs.setString(_keyTelefoneComerciante, telefone);
    await prefs.setString(_keyEnderecoComerciante, endereco);
    
    _nomeComerciante = nome;
    _telefoneComerciante = telefone;
    _enderecoComerciante = endereco;
  }

  /// Salva tema
  Future<void> salvarTema(String tema) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTema, tema);
    _tema = tema;
    notifyListeners(); // Notifica os listeners sobre a mudança
  }

  /// Salva configuração de notificações
  Future<void> salvarNotificacoesFiado(bool ativo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificacoesFiado, ativo);
    _notificacoesFiado = ativo;
  }

  /// Converte tema string para ThemeMode
  ThemeMode getThemeMode() {
    switch (_tema) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Converte ThemeMode para string
  String themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
} 