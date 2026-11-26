import 'package:flutter/material.dart';

/// SMART GUARDIAN EGYPT design system.
/// Deep navy base, primary blue + electric cyan accents, clear status colors.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF071426);
  static const Color surface = Color(0xFF0B1D32);
  static const Color surfaceAlt = Color(0xFF10243B);
  static const Color cardBorder = Color(0xFF1E3252);

  static const Color electricBlue = Color(0xFF1677FF);
  static const Color electricBlueDim = Color(0xFF0E4DA8);
  static const Color cyan = Color(0xFF00D4FF);

  static const Color safe = Color(0xFF16C784); // green
  static const Color medium = Color(0xFFFACC15); // yellow
  static const Color high = Color(0xFFF97316); // orange
  static const Color critical = Color(0xFFEF4444); // red

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA9BDD2);
  static const Color textMuted = Color(0xFF5F748F);

  static Color forRiskLevel(String level) {
    switch (level) {
      case 'MEDIUM':
        return medium;
      case 'HIGH':
        return high;
      case 'CRITICAL':
        return critical;
      case 'SAFE':
      default:
        return safe;
    }
  }
}

class AppGradients {
  AppGradients._();

  static const LinearGradient backgroundGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B1D32), Color(0xFF071426)],
  );

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1677FF), Color(0xFF00D4FF)],
  );

  static LinearGradient card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.surfaceAlt.withOpacity(0.9),
      AppColors.surface.withOpacity(0.9),
    ],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricBlue,
        secondary: AppColors.cyan,
        surface: AppColors.surface,
        error: AppColors.critical,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          )
          .copyWith(
            headlineSmall: const TextStyle(
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 1.2,
            ),
            titleLarge: const TextStyle(
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 1.4,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.electricBlue,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerColor: AppColors.cardBorder,
    );
  }

  /// Smooth built-in page transition used across the app.
  static Route<T> pageRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
