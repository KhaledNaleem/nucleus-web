import 'package:flutter/material.dart';

class AppTheme {
  // ---- Core palette ----
  static const _brand = Color.fromARGB(255, 215, 100, 58);

  // Light
  static final light = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _brand,
      brightness: Brightness.light,
      primary: _brand,
      secondary: const Color(0xFF2D6AE3),
      surface: const Color(0xFFF6F7FB),
    ),
    scaffoldBackgroundColor: const Color(0xFFF6F7FB),
    canvasColor: Colors.white,
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Colors.black45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    chipTheme: const ChipThemeData(
      side: BorderSide.none,
      backgroundColor: Color(0xFFF0F2F7),
      labelStyle: TextStyle(color: Colors.black87),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _brand),
    ),

    // Force black filled buttons in light theme (handles disabled via resolver)
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(120, 44)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
          (states) => states.contains(MaterialState.disabled)
              ? Colors.black.withOpacity(.35)
              : Colors.black,
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color?>(
          (states) => states.contains(MaterialState.disabled)
              ? Colors.white70
              : Colors.white,
        ),
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (states) => states.contains(MaterialState.pressed)
              ? Colors.white.withOpacity(.08)
              : null,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(120, 44),
      ),
    ),
  );

  // Dark — styled like your screenshot (deep navy surfaces + soft pills)
  static final dark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _brand,
      brightness: Brightness.dark,
      primary: _brand,
      secondary: const Color(0xFF39D2C0),
      background: const Color(0xFF0E1720),
      surface: const Color(0xFF101A24),
    ),
    scaffoldBackgroundColor: const Color(0xFF0E1720),
    canvasColor: const Color(0xFF0E1720),
    cardColor: const Color(0xFF101A24),
    dividerColor: const Color(0xFF1C2630),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Color(0xFF0E1720),
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
      bodyLarge: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF101A24),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withOpacity(.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF14202A), // dark field like mock
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      prefixIconColor: Colors.white54,
    ),
    chipTheme: const ChipThemeData(
      side: BorderSide(color: Color(0xFF1E2A34)),
      backgroundColor: Color(0xFF14202A),
      labelStyle: TextStyle(color: Colors.white70),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.white),
    ),

    // Soft “pill” on dark with disabled handled via resolver
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(120, 44)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
          (states) => states.contains(MaterialState.disabled)
              ? const Color(0xFFEDEFF2).withOpacity(.6)
              : const Color(0xFFEDEFF2),
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color?>(
          (states) => states.contains(MaterialState.disabled)
              ? const Color(0xFF0E1720).withOpacity(.6)
              : const Color(0xFF0E1720),
        ),
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (states) => states.contains(MaterialState.pressed)
              ? const Color(0xFF0E1720).withOpacity(.08)
              : null,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF2A3540)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(120, 44),
      ),
    ),
  );
}

// -------- Tiny controller (no packages) --------
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  void setMode(ThemeMode m) {
    if (_mode == m) return;
    _mode = m;
    notifyListeners();
  }

  void toggle(bool isDark) => setMode(isDark ? ThemeMode.dark : ThemeMode.light);
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  final ThemeController controller;
  const ThemeControllerScope({
    super.key,
    required this.controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeControllerScope>()!.controller;
}
