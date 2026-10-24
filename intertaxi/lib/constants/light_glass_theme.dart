import 'package:flutter/material.dart';

/// InterTaxi Light Glassmorphism Design System (White & Blue Theme)
class LightGlassColors {
  static const Color bgLight1 = Color(0xFFF4F8FF);
  static const Color bgLight2 = Color(0xFFE2EDFF);
  static const Color bgLight3 = Color(0xFFFAFBFF);

  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color skyBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFFE6F0FF);

  static const Color glassFill = Color(0xE6FFFFFF); // 90% white glass
  static const Color glassSoft = Color(0xB3FFFFFF); // 70% white glass
  static const Color glassBorder = Color(0xFFFFFFFF);
  static const Color glassBorderSubtle = Color(0xFFD8E6FF);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Shared surface and interaction colors used across the premium UI.
  static const Color surface = Color(0xF7FFFFFF);
  static const Color surfaceTint = Color(0xFFF1F6FF);
  static const Color divider = Color(0xFFDCE7F6);
  static const Color shadow = Color(0x180B3475);
  static const Color focus = Color(0xFF4C91FF);
}

/// Central layout rhythm for screens and reusable components.
abstract final class LightGlassSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class LightGlassRadius {
  static const double card = 22;
  static const double panel = 28;
  static const double field = 16;
  static const double button = 16;
  static const double pill = 999;
}

class LightGlassGradients {
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      LightGlassColors.bgLight1,
      LightGlassColors.bgLight2,
      LightGlassColors.bgLight3,
    ],
  );

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0066FF), Color(0xFF3B82F6)],
  );
}

ThemeData buildLightGlassTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: LightGlassColors.bgLight1,
  );

  final textTheme = base.textTheme.apply(
    fontFamily: 'Manrope',
    bodyColor: LightGlassColors.textPrimary,
    displayColor: LightGlassColors.textPrimary,
  );

  return base.copyWith(
    textTheme: textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      displayMedium: textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      displaySmall: textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      bodySmall: textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelMedium: textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w400,
      ),
      labelSmall: textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w400,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: InterTaxiPageTransitionsBuilder(),
        TargetPlatform.iOS: InterTaxiPageTransitionsBuilder(),
        TargetPlatform.linux: InterTaxiPageTransitionsBuilder(),
        TargetPlatform.macOS: InterTaxiPageTransitionsBuilder(),
        TargetPlatform.windows: InterTaxiPageTransitionsBuilder(),
      },
    ),
    colorScheme: base.colorScheme.copyWith(
      primary: LightGlassColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: LightGlassColors.skyBlue,
      surface: Colors.white,
      onSurface: LightGlassColors.textPrimary,
    ),
    scaffoldBackgroundColor: LightGlassColors.bgLight1,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: LightGlassColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: LightGlassColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: LightGlassColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: LightGlassColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LightGlassRadius.card),
        side: const BorderSide(color: LightGlassColors.glassBorderSubtle),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 50),
        elevation: 0,
        backgroundColor: LightGlassColors.primaryBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFD9E7FB),
        disabledForegroundColor: LightGlassColors.textMuted,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LightGlassRadius.button),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        foregroundColor: LightGlassColors.primaryBlue,
        side: const BorderSide(color: LightGlassColors.glassBorderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LightGlassRadius.button),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LightGlassColors.surfaceTint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: const TextStyle(
        color: LightGlassColors.textMuted,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(color: LightGlassColors.textSecondary),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LightGlassRadius.field),
        borderSide: const BorderSide(color: LightGlassColors.focus, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LightGlassRadius.field),
        borderSide: const BorderSide(color: LightGlassColors.glassBorderSubtle),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LightGlassRadius.field),
        borderSide: const BorderSide(color: LightGlassColors.danger),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: LightGlassColors.surface,
      indicatorColor: LightGlassColors.lightBlue,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? LightGlassColors.primaryBlue
              : LightGlassColors.textMuted,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: LightGlassColors.textMuted,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: LightGlassColors.textPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}

/// Reusable fade-through transition used by every Material route in the app.
/// Matching [Hero] tags on source and destination widgets add Flutter's shared
/// element flight on top of this page transition.
class InterTaxiPageTransitionsBuilder extends PageTransitionsBuilder {
  const InterTaxiPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // `disableAnimations` follows the platform's Reduce Motion preference.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return FadeTransition(opacity: animation, child: child);
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}
