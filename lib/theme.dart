import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Platform-aware font configuration
String? get appFontFamily => 'Delight';
const List<String> appFontFallback = ['Roboto', 'Noto Sans', 'Arial', 'Helvetica'];

class LightModeColors {
  static const lightPrimary = Color(0xFFFF5722);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFBBDEFB);
  static const lightOnPrimaryContainer = Color(0xFF0D47A1);
  static const lightSecondary = Color(0xFF1976D2);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = Color(0xFF42A5F5);
  static const lightOnTertiary = Color(0xFF000000);
  static const lightError = Color(0xFFD32F2F);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFEBEE);
  static const lightOnErrorContainer = Color(0xFFB71C1C);
  static const lightInversePrimary = Color(0xFF64B5F6);
  static const lightShadow = Color(0xFF000000);
  static const lightSurface = Color(0xFFFAFBFF);
  static const lightOnSurface = Color(0xFF1A1C1E);
  static const lightAppBarBackground = Color(0xFFFF5722);
  
  // Content type colors
  static const tutorial = Color(0xFFBBDEFB);
  static const comparative = Color(0xFFFFC107);
  static const conceptual = Color(0xFFFFEB3B);
  static const blueprint = Color(0xFF2196F3);
  static const debug = Color(0xFFFFCDD2);
}

class DarkModeColors {
  static const darkPrimary = Color(0xFFFF5722);
  static const darkOnPrimary = Color(0xFF0D47A1);
  static const darkPrimaryContainer = Color(0xFF1565C0);
  static const darkOnPrimaryContainer = Color(0xFFE3F2FD);
  static const darkSecondary = Color(0xFF90CAF9);
  static const darkOnSecondary = Color(0xFF1565C0);
  static const darkTertiary = Color(0xFF42A5F5);
  static const darkOnTertiary = Color(0xFF0D47A1);
  static const darkError = Color(0xFFEF5350);
  static const darkOnError = Color(0xFFB71C1C);
  static const darkErrorContainer = Color(0xFFD32F2F);
  static const darkOnErrorContainer = Color(0xFFFFEBEE);
  static const darkInversePrimary = Color(0xFF1565C0);
  static const darkShadow = Color(0xFF000000);
  static const darkSurface = Color(0xFF0D1117);
  static const darkOnSurface = Color(0xFFE1E6EA);
  static const darkAppBarBackground = Color(0xFFFF5722);
  
  // Content type colors (darker variants for dark mode)
  static const tutorial = Color(0xFF673AB7);
  static const comparative = Color(0xFFFFB74D);
  static const conceptual = Color(0xFF1B5E20);
  static const blueprint = Color(0xFF2196F3);
  static const debug = Color(0xFFEF5350);
}

class ContentTypeColors {
  static Color getColor(String contentType, bool isDark) {
    if (isDark) {
      switch (contentType) {
        case 'featureCentricTutorial':
          return DarkModeColors.tutorial;
        case 'comparative':
          return DarkModeColors.comparative;
        case 'conceptualRedefinition':
          return DarkModeColors.conceptual;
        case 'blueprintSeries':
          return DarkModeColors.blueprint;
        case 'debugForensics':
          return DarkModeColors.debug;
        default:
          return DarkModeColors.tutorial;
      }
    } else {
      switch (contentType) {
        case 'featureCentricTutorial':
          return LightModeColors.tutorial;
        case 'comparative':
          return LightModeColors.comparative;
        case 'conceptualRedefinition':
          return LightModeColors.conceptual;
        case 'blueprintSeries':
          return LightModeColors.blueprint;
        case 'debugForensics':
          return LightModeColors.debug;
        default:
          return LightModeColors.tutorial;
      }
    }
  }
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    inversePrimary: LightModeColors.lightInversePrimary,
    shadow: LightModeColors.lightShadow,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
  ),
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    backgroundColor: LightModeColors.lightAppBarBackground,
    foregroundColor: LightModeColors.lightOnPrimaryContainer,
    elevation: 0,
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.displayLarge, fontWeight: FontWeight.w900),
    displayMedium: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.displayMedium, fontWeight: FontWeight.w800),
    displaySmall: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.displaySmall, fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.headlineLarge, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.headlineMedium, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.headlineSmall, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.titleLarge, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.titleMedium, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.titleSmall, fontWeight: FontWeight.w500),
    labelLarge: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.labelLarge, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.labelMedium, fontWeight: FontWeight.w400),
    labelSmall: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.labelSmall, fontWeight: FontWeight.w400),
    bodyLarge: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.bodyLarge, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.bodyMedium, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.bodySmall, fontWeight: FontWeight.w300),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    inversePrimary: DarkModeColors.darkInversePrimary,
    shadow: DarkModeColors.darkShadow,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
  ),
  brightness: Brightness.dark,
  appBarTheme: const AppBarTheme(
    backgroundColor: DarkModeColors.darkAppBarBackground,
    foregroundColor: DarkModeColors.darkOnPrimaryContainer,
    elevation: 0,
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.displayLarge, fontWeight: FontWeight.w900),
    displayMedium: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.displayMedium, fontWeight: FontWeight.w800),
    displaySmall: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.displaySmall, fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.headlineLarge, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.headlineMedium, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.headlineSmall, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.titleLarge, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.titleMedium, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.titleSmall, fontWeight: FontWeight.w500),
    labelLarge: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.labelLarge, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.labelMedium, fontWeight: FontWeight.w400),
    labelSmall: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.labelSmall, fontWeight: FontWeight.w400),
    bodyLarge: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.bodyLarge, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.bodyMedium, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontFamily: appFontFamily, fontFamilyFallback: appFontFallback, fontSize: FontSizes.bodySmall, fontWeight: FontWeight.w300),
  ),
);
