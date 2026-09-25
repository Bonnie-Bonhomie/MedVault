import 'package:flutter/material.dart';

/// Colour tokens for the pharmacy inventory app.
/// The identity is built on a deep pharmacy green with a single
/// brighter green reserved for actions and healthy stock states.
class AppColors {
  static const Color deepGreen = Color(0xFF0B3D2E); // headers, app bar
  static const Color primary = Color(0xFF14603F); // buttons, primary surfaces
  static const Color primaryLight = Color(0xFF1E7A52);
  static const Color accent = Color(0xFF2E9E6B); // highlights, healthy stock
  static const Color mist = Color(0xFFE8F1EC); // tinted cards / chips
  static const Color surface = Color(0xFFF6F9F7); // screen background
  static const Color ink = Color(0xFF11221B); // primary text
  static const Color inkSoft = Color(0xFF5A6B63); // secondary text
  static const Color warning = Color(0xFFB8860B); // expiring soon
  static const Color danger = Color(0xFFA32C2C); // out of stock / expired
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.surface,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFDCE7E1)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.primary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDCE7E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDCE7E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        labelStyle: const TextStyle(color: AppColors.inkSoft),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mist,
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.mist,
        labelStyle: TextStyle(color: AppColors.primary),
        side: BorderSide.none,
      ),
      dividerColor: const Color(0xFFDCE7E1),
    );
  }
}
