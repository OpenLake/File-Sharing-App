import 'package:flutter/material.dart';

/// Defines the light theme for the application.
///
/// This theme is characterized by a light color scheme, primarily using blue
/// and white, with the 'Inter' font family.
/// It's designed for optimal readability
/// and a clean, modern look in well-lit environments.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Inter',
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF0065FF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD4E3FF),
    onPrimaryContainer: Color(0xFF001D36),
    secondary: Color(0xFF00A8E8),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFB9E9FF),
    onSecondaryContainer: Color(0xFF001F2A),
    surface: Color(0xFFFDFBFF),
    onSurface: Color(0xFF1B1B1B),
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    outline: Color(0xFF74777F),
  ),
  scaffoldBackgroundColor: const Color(0xFFF7F7F7),
  cardColor: const Color(0xFFFFFFFF),
  dividerColor: const Color(0xFFDDDDDD),
  hintColor: const Color(0xFF757575),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: Color(0xFF212121),
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      color: Color(0xFF212121),
      fontWeight: FontWeight.bold,
    ),
    displaySmall: TextStyle(
      color: Color(0xFF212121),
      fontWeight: FontWeight.bold,
    ),
    headlineLarge: TextStyle(
      color: Color(0xFF212121),
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      color: Color(0xFF212121),
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      color: Color(0xFF212121),
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: Color(0xD9212121),
      fontWeight: FontWeight.w500,
    ),
    titleMedium: TextStyle(color: Color(0xD9212121)),
    titleSmall: TextStyle(color: Color(0xD9212121)),
    bodyLarge: TextStyle(color: Color(0xCC212121), height: 1.5),
    bodyMedium: TextStyle(color: Color(0xCC212121), height: 1.5),
    bodySmall: TextStyle(color: Color(0xB3212121)),
    labelLarge: TextStyle(
      color: Color(0xFF212121),
      fontWeight: FontWeight.bold,
    ),
    labelMedium: TextStyle(color: Color(0xFF757575)),
    labelSmall: TextStyle(color: Color(0xFF757575)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFFFFFF),
    elevation: 1,
    shadowColor: Color(0xFFE0E0E0),
    centerTitle: true,
    iconTheme: IconThemeData(color: Color(0xFF000000)),
    titleTextStyle: TextStyle(
      color: Color(0xFF000000),
      fontSize: 20,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 1,
    shadowColor: const Color(0xFFF5F5F5),
    color: const Color(0xFFFFFFFF),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF5F5F5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF0065FF), width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0065FF),
      foregroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF3A86FF),
      side: const BorderSide(color: Color(0xFF3A86FF), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF0065FF),
    foregroundColor: Color(0xFFFFFFFF),
    elevation: 4,
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

/// Defines the dark theme for the application.
///
/// This theme uses a dark color palette with shades of grey and blue accents
/// to reduce eye strain in low-light conditions. It maintains the 'Inter' font
/// family for consistency with the light theme.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Inter',
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF3A86FF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF00458E),
    onPrimaryContainer: Color(0xFFD4E3FF),
    secondary: Color(0xFF00A8E8),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF004D66),
    onSecondaryContainer: Color(0xFFB9E9FF),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFE3E2E6),
    error: Color(0xFFD32F2F),
    onError: Color(0xFFFFFFFF),
    outline: Color(0xFF8E9099),
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  cardColor: const Color(0xFF1E1E1E),
  dividerColor: const Color(0xFF424242),
  hintColor: const Color(0xFF9E9E9E),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: Color(0xE6FFFFFF),
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      color: Color(0xE6FFFFFF),
      fontWeight: FontWeight.bold,
    ),
    displaySmall: TextStyle(
      color: Color(0xE6FFFFFF),
      fontWeight: FontWeight.bold,
    ),
    headlineLarge: TextStyle(
      color: Color(0xE6FFFFFF),
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      color: Color(0xE6FFFFFF),
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      color: Color(0xE6FFFFFF),
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: Color(0xD9FFFFFF),
      fontWeight: FontWeight.w500,
    ),
    titleMedium: TextStyle(color: Color(0xD9FFFFFF)),
    titleSmall: TextStyle(color: Color(0xD9FFFFFF)),
    bodyLarge: TextStyle(color: Color(0xCCFFFFFF), height: 1.5),
    bodyMedium: TextStyle(color: Color(0xCCFFFFFF), height: 1.5),
    bodySmall: TextStyle(color: Color(0xB3FFFFFF)),
    labelLarge: TextStyle(
      color: Color(0xFFFFFFFF),
      fontWeight: FontWeight.bold,
    ),
    labelMedium: TextStyle(color: Color(0xFFBDBDBD)),
    labelSmall: TextStyle(color: Color(0xFFBDBDBD)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF181818),
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
    titleTextStyle: TextStyle(
      color: Color(0xE6FFFFFF),
      fontSize: 20,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    color: const Color(0xFF1E1E1E),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2A2A2A),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.transparent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF3A86FF), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD32F2F)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
    ),
    labelStyle: const TextStyle(color: Color(0xFFBDBDBD)),
    hintStyle: const TextStyle(color: Color(0xFF757575)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3A86FF),
      foregroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF3A86FF),
      side: const BorderSide(color: Color(0xFF3A86FF), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF3A86FF),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF3A86FF),
    foregroundColor: Color(0xFFFFFFFF),
    elevation: 4,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF1E1E1E),
    selectedItemColor: Color(0xFF3A86FF),
    unselectedItemColor: Color(0xFF9E9E9E),
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
