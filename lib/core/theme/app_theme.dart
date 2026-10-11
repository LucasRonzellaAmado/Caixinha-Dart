import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const seedColor = Color(0xFF00796B);

  static ThemeData light() => _build(ColorScheme.fromSeed(seedColor: seedColor));

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
      );

  static ThemeData _build(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
      );
}

extension FinanceColors on ColorScheme {
  bool get _isLight => brightness == Brightness.light;

  Color get income =>
      _isLight ? const Color(0xFF1B5E20) : const Color(0xFF81C784);

  Color get expense =>
      _isLight ? const Color(0xFFB71C1C) : const Color(0xFFEF9A9A);

  Color get warning =>
      _isLight ? const Color(0xFFE65100) : const Color(0xFFFFB74D);

  Color get proLabore =>
      _isLight ? const Color(0xFF4527A0) : const Color(0xFFB39DDB);
}
