// lib/modules/ui/styles.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import '../utils.dart';

class AppColors {
  // Slate + Teal Palette
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color sapphireBlue = Color(0xFF2563EB);
  
  // Light Mode Colors
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color textLight = Color(0xFF0F172A);
  static const Color cardLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textMutedLight = Color(0xFF64748B);

  // Dark Mode Colors
  static const Color bgDark = Color(0xFF090D1A);
  static const Color textDark = Color(0xFFF8FAFC);
  static const Color cardDark = Color(0xFF131B2E);
  static const Color borderDark = Color(0xFF1E293B);
  static const Color textMutedDark = Color(0xFF94A3B8);
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _enableTransparency = true;

  ThemeMode get themeMode => _themeMode;
  bool get enableTransparency => _enableTransparency;
  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeProvider({ThemeMode initialMode = ThemeMode.dark, bool initialTransparency = true}) {
    _themeMode = initialMode;
    _enableTransparency = initialTransparency;
    _updateSystemTitlebar();
  }

  void updateTheme(ThemeMode mode, bool transparency) {
    _themeMode = mode;
    _enableTransparency = transparency;
    notifyListeners();
    _updateSystemTitlebar();
  }

  void _updateSystemTitlebar() {
    if (Platform.isWindows) {
      final isDarkTheme = _themeMode == ThemeMode.dark;
      const MethodChannel('ja_translate/theme')
          .invokeMethod('setTheme', isDarkTheme ? 'dark' : 'light')
          .catchError((_) {});

      // Áp dụng hiệu ứng kính mờ động
      try {
        if (_enableTransparency) {
          if (isWindows11OrNewer()) {
            flutter_acrylic.Window.setEffect(
              effect: flutter_acrylic.WindowEffect.mica,
              color: Colors.transparent,
            ).catchError((_) {});
          } else {
            flutter_acrylic.Window.setEffect(
              effect: flutter_acrylic.WindowEffect.acrylic,
              color: isDarkTheme ? const Color(0x1F000000) : const Color(0x1FFFFFFF),
            ).catchError((_) {});
          }
        } else {
          flutter_acrylic.Window.setEffect(
            effect: flutter_acrylic.WindowEffect.disabled,
          ).catchError((_) {});
        }
      } catch (_) {}
    }
  }

  // Styles Helpers
  BoxDecoration glassDecoration(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    // On Windows 10 or when transparency is disabled, draw fully opaque containers
    final showSolid = !Platform.isWindows || !isWindows11OrNewer() || !_enableTransparency;

    return BoxDecoration(
      color: showSolid
          ? (isDarkTheme ? AppColors.cardDark : AppColors.cardLight)
          : (isDarkTheme 
              ? AppColors.cardDark.withOpacity(0.65) 
              : AppColors.cardLight.withOpacity(0.75)),
      borderRadius: isWindows11OrNewer() ? BorderRadius.circular(16) : BorderRadius.zero,
      border: Border.all(
        color: isDarkTheme ? AppColors.borderDark : AppColors.borderLight,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDarkTheme ? 0.3 : 0.05),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryTeal,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryTeal,
        secondary: AppColors.sapphireBlue,
        surface: AppColors.cardLight,
        background: AppColors.bgLight,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textLight, fontFamily: 'Segoe UI'),
        bodyMedium: TextStyle(color: AppColors.textLight, fontFamily: 'Segoe UI'),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
        ),
      ),
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.accentTeal,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentTeal,
        secondary: AppColors.sapphireBlue,
        surface: AppColors.cardDark,
        background: AppColors.bgDark,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textDark, fontFamily: 'Segoe UI'),
        bodyMedium: TextStyle(color: AppColors.textDark, fontFamily: 'Segoe UI'),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentTeal, width: 2),
        ),
      ),
    );
  }
}
