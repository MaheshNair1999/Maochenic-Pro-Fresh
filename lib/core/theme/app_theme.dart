import 'package:flutter/material.dart';

/// maochanicProFresh design system.
/// Uses a deep steel-blue primary with amber accents — industrial but clean.
class AppTheme {
  AppTheme._();

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _primarySeed = Color(0xFF1B4F72);   // Deep steel blue
  static const Color _accentAmber = Color(0xFFF39C12);   // Amber / warning
  static const Color _successGreen = Color(0xFF1E8449);
  static const Color _errorRed = Color(0xFFC0392B);

  // Light surface tones
  static const Color _surfaceLight = Color(0xFFF5F7FA);
  static const Color _cardLight = Color(0xFFFFFFFF);

  // Dark surface tones
  static const Color _surfaceDark = Color(0xFF0D1117);
  static const Color _cardDark = Color(0xFF161B22);
  static const Color _elevatedDark = Color(0xFF1C2333);

  // ── Text Styles ───────────────────────────────────────────────────────────
  static const String _fontFamily = 'Roboto';

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor.withValues(alpha: 0.7),
      ),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.1,
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.light,
      primary: _primarySeed,
      secondary: _accentAmber,
      error: _errorRed,
      surface: _surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(const Color(0xFF1A1A2E)),
      scaffoldBackgroundColor: _surfaceLight,
      fontFamily: _fontFamily,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: _primarySeed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: _cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primarySeed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primarySeed,
          side: const BorderSide(color: _primarySeed, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primarySeed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _errorRed),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primarySeed,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // BottomNav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primarySeed,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: _primarySeed.withValues(alpha: 0.1),
        labelStyle: const TextStyle(
          color: _primarySeed,
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),

      // Extension colours exposed via Theme.of(context).extension
      extensions: [
        AppColors(
          accent: _accentAmber,
          success: _successGreen,
          cardBackground: _cardLight,
          inputBackground: Colors.grey.shade50,
        ),
      ],
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.dark,
      primary: const Color(0xFF4A9FD5),
      secondary: _accentAmber,
      error: const Color(0xFFE57373),
      surface: _surfaceDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(const Color(0xFFE6EDF3)),
      scaffoldBackgroundColor: _surfaceDark,
      fontFamily: _fontFamily,

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161B22),
        foregroundColor: Color(0xFFE6EDF3),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE6EDF3),
        ),
        iconTheme: IconThemeData(color: Color(0xFFE6EDF3)),
      ),

      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF30363D)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A9FD5),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4A9FD5),
          side: const BorderSide(color: Color(0xFF4A9FD5), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _elevatedDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A9FD5), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: Color(0xFF8B949E)),
        hintStyle: const TextStyle(color: Color(0xFF6E7681)),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF4A9FD5),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF161B22),
        selectedItemColor: Color(0xFF4A9FD5),
        unselectedItemColor: Color(0xFF6E7681),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF4A9FD5).withValues(alpha: 0.2),
        labelStyle: const TextStyle(
          color: Color(0xFF4A9FD5),
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF30363D),
        thickness: 1,
      ),

      extensions: const [
        AppColors(
          accent: _accentAmber,
          success: Color(0xFF3FB950),
          cardBackground: _cardDark,
          inputBackground: _elevatedDark,
        ),
      ],
    );
  }
}

/// Custom theme extension for colours not in ColorScheme.
class AppColors extends ThemeExtension<AppColors> {
  final Color accent;
  final Color success;
  final Color cardBackground;
  final Color inputBackground;

  const AppColors({
    required this.accent,
    required this.success,
    required this.cardBackground,
    required this.inputBackground,
  });

  @override
  ThemeExtension<AppColors> copyWith({
    Color? accent,
    Color? success,
    Color? cardBackground,
    Color? inputBackground,
  }) {
    return AppColors(
      accent: accent ?? this.accent,
      success: success ?? this.success,
      cardBackground: cardBackground ?? this.cardBackground,
      inputBackground: inputBackground ?? this.inputBackground,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(
    ThemeExtension<AppColors>? other,
    double t,
  ) {
    if (other is! AppColors) return this;
    return AppColors(
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
    );
  }
}
