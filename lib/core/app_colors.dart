import 'package:flutter/material.dart';

/// Classe centralizada para gerenciar todas as cores do aplicativo
class AppColors {
  AppColors._(); // Construtor privado

  // ============ CORES PRIMÁRIAS ============
  static const Color primary = Color(0xFF2E7D32);       // Verde principal
  static const Color primaryDark = Color(0xFF1B5E20);   // Verde escuro
  static const Color primaryLight = Color(0xFF4CAF50);  // Verde claro
  
  // ============ CORES DE FUNDO ============
  static const Color background = Color(0xFFF8F9FA);    // Fundo claro
  static const Color surface = Colors.white;            // Superfície
  static const Color surfaceDark = Color(0xFF2E2E2E);   // Superfície escura
  
  // ============ CORES DE TEXTO MELHORADAS ============
  static const Color textPrimary = Color(0xFF1A1A1A);    // Texto principal mais escuro
  static const Color textSecondary = Color(0xFF424242);  // Texto secundário mais escuro
  static const Color textHint = Color(0xFF757575);       // Texto de dica
  static const Color textOnPrimary = Colors.white;       // Texto sobre cor primária
  
  // ============ CORES DE STATUS ============
  static const Color success = Color(0xFF4CAF50);        // Sucesso/Pago
  static const Color error = Color(0xFFE53935);          // Erro/Vencido
  static const Color warning = Color(0xFFFF9800);        // Aviso/Parcial
  static const Color info = Color(0xFF2196F3);           // Informação/Pendente
  
  // ============ CORES NEUTRAS MELHORADAS ============
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // ============ CORES COM TRANSPARÊNCIA ============
  static Color get primaryWithOpacity => primary.withValues(alpha: 0.1);
  static Color get successWithOpacity => success.withValues(alpha: 0.1);
  static Color get errorWithOpacity => error.withValues(alpha: 0.1);
  static Color get warningWithOpacity => warning.withValues(alpha: 0.1);
  static Color get infoWithOpacity => info.withValues(alpha: 0.1);
  
  // ============ GRADIENTES ============
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFE53935)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Extensão para facilitar o acesso às cores baseadas no tema
extension ThemeColors on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get onPrimaryColor => Theme.of(this).colorScheme.onPrimary;
  Color get backgroundColor => AppColors.background;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  
  // Cores adaptáveis ao tema MELHORADAS
  Color get adaptiveTextPrimary => Theme.of(this).brightness == Brightness.dark 
      ? Colors.white 
      : AppColors.textPrimary;
      
  Color get adaptiveTextSecondary => Theme.of(this).brightness == Brightness.dark 
      ? AppColors.grey300 
      : AppColors.textSecondary;
      
  Color get adaptiveBackground => Theme.of(this).brightness == Brightness.dark 
      ? AppColors.surfaceDark 
      : AppColors.background;
      
  // NOVAS CORES PARA MELHOR CONTRASTE
  Color get adaptiveCardColor => Theme.of(this).brightness == Brightness.dark 
      ? AppColors.surfaceDark 
      : Colors.white;
      
  Color get adaptiveBorderColor => Theme.of(this).brightness == Brightness.dark 
      ? AppColors.grey600 
      : AppColors.grey300;
      
  Color get adaptiveDividerColor => Theme.of(this).brightness == Brightness.dark 
      ? AppColors.grey600 
      : AppColors.grey300;
}

/// Cores específicas para status de fiado
class FiadoColors {
  static const Color pago = AppColors.success;
  static const Color pendente = AppColors.info;
  static const Color vencido = AppColors.error;
  static const Color parcial = AppColors.warning;
  
  static Color getStatusColor(String status, {bool isOverdue = false}) {
    if (isOverdue) return vencido;
    
    switch (status.toLowerCase()) {
      case 'pago':
        return pago;
      case 'parcial':
        return parcial;
      case 'pendente':
      default:
        return pendente;
    }
  }
}

/// Cores para diferentes categorias
class CategoryColors {
  static const List<Color> chartColors = [
    AppColors.primary,
    AppColors.info,
    AppColors.warning,
    AppColors.success,
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];
  
  static Color getChartColor(int index) {
    return chartColors[index % chartColors.length];
  }
} 