import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData build() {
    final base = ThemeData.dark();
    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        letterSpacing: 0.08,
        color: Colors.white,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.55,
        color: Colors.white,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.08,
        height: 1.6,
        color: Colors.white70,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.12,
        color: Colors.white,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: Colors.white70,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: Colors.white,
      ),
    );

    return base.copyWith(
      primaryColor: Colors.blueGrey,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          letterSpacing: 0.75,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
