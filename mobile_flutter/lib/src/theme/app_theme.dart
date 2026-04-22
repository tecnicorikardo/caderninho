import 'package:flutter/material.dart';

class AppTheme {
  // Cores principais
  static const primary = Color(0xFF1E3A8A); // Azul forte
  static const accent = Color(0xFF2563EB); // Azul destaque
  static const medium = Color(0xFF3B82F6); // Azul médio
  static const lightBlue = Color(0xFF60A5FA); // Azul claro
  static const base = Color(0xFF0F172A);

  static ThemeData lightTheme() {
    final colors = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: accent,
      tertiary: medium,
      onSurface: base,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
    );

    final textTheme = baseTheme.textTheme.copyWith(
      titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: baseTheme.textTheme.titleSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        elevation: 1,
        shadowColor: Color(0x141E3A8A),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: base,
          letterSpacing: -0.2,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 180),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return accent.withOpacity(0.4);
            }
            if (states.contains(WidgetState.pressed)) {
              return Colors.white;
            }
            return primary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return accent;
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0x122563EB);
            }
            return Colors.transparent;
          }),
          overlayColor: WidgetStateProperty.all(const Color(0x112563EB)),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const BorderSide(color: Color(0x222563EB), width: 1.2);
            }
            return BorderSide.none;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        helperStyle: const TextStyle(fontSize: 14),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: lightBlue, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: lightBlue, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: accent, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x161E3A8A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBlue, width: 1),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: base,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: base,
          height: 1.35,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: const Color(0x1F1E3A8A),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          side: BorderSide(color: lightBlue.withOpacity(0.3), width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x121E3A8A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: lightBlue.withOpacity(0.2), width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 220),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return accent.withOpacity(0.42);
            }
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFF1E40AF);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFF3B82F6);
            }
            if (states.contains(WidgetState.focused)) {
              return const Color(0xFF2563EB);
            }
            return accent;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) return 1;
            if (states.contains(WidgetState.hovered)) return 8;
            if (states.contains(WidgetState.focused)) return 7;
            return 5;
          }),
          shadowColor: WidgetStateProperty.all(const Color(0x3D1D4ED8)),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const Color(0x30FFFFFF);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0x14FFFFFF);
            }
            return const Color(0x10FFFFFF);
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide.none;
            }
            if (states.contains(WidgetState.pressed)) {
              return const BorderSide(color: Color(0x33FFFFFF), width: 1.4);
            }
            if (states.contains(WidgetState.hovered)) {
              return const BorderSide(color: Color(0x29FFFFFF), width: 1.2);
            }
            return const BorderSide(color: Color(0x1FFFFFFF), width: 1);
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 220),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return accent.withOpacity(0.45);
            }
            if (states.contains(WidgetState.pressed)) {
              return accent;
            }
            return primary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const Color(0x1A2563EB);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0x0D2563EB);
            }
            if (states.contains(WidgetState.focused)) {
              return const Color(0x0A2563EB);
            }
            return Colors.transparent;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const BorderSide(color: accent, width: 1.8);
            }
            if (states.contains(WidgetState.hovered)) {
              return const BorderSide(color: accent, width: 1.5);
            }
            return BorderSide(color: lightBlue.withOpacity(0.85), width: 1.2);
          }),
          overlayColor: WidgetStateProperty.all(const Color(0x112563EB)),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return 1;
            return 0;
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 200),
          foregroundColor: WidgetStateProperty.all(primary),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const Color(0x182563EB);
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0x0D2563EB);
            }
            return Colors.transparent;
          }),
          overlayColor: WidgetStateProperty.all(const Color(0x112563EB)),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: primary,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: base,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF475569),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 6,
        hoverElevation: 10,
        focusElevation: 8,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // Método legado para compatibilidade
  static ThemeData light() => lightTheme();

  // Gradiente para containers e cards especiais
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient accentGradient = const LinearGradient(
    colors: [accent, medium],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient lightGradient = const LinearGradient(
    colors: [medium, lightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradiente para bordas
  static LinearGradient borderGradient = const LinearGradient(
    colors: [accent, lightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
