import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      secondary: Colors.amber,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primarySwatch: Colors.indigo,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: _textTheme(colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(),
      cardTheme: _cardTheme(),
      inputDecorationTheme: _inputDecorationTheme(),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      secondary: Colors.amber,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primarySwatch: Colors.indigo,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: _textTheme(colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(),
      cardTheme: _cardTheme(),
      inputDecorationTheme: _inputDecorationTheme(),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    return TextTheme(
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: colorScheme.primary.withOpacity(0.8),
      ),
      bodyLarge: TextStyle(
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        color: colorScheme.onSurface.withOpacity(0.8),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static CardTheme _cardTheme() {
    return CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme() {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
