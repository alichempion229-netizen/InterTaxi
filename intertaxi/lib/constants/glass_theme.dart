import 'package:flutter/material.dart';

/// InterTaxi Glassmorphism Design System
///
/// РџР°Р»РёС‚Р°Рё СЏРіРѕРЅР°Рё РєР°Р±СѓРґ-СЃР°С„РµРґ Р±Р°СЂРѕРё С‚Р°РјРѕРјРё СЃР°ТіРёС„Р°ТіРѕРё Р±Р°СЂРЅРѕРјР°:
/// Р·Р°РјРёРЅР°Рё РєР°Р±СѓРґРё С‚РёСЂР° + С€РёС€Р°Рё СЃР°С„РµРґРё С€Р°С„С„РѕС„ + Р°РєСЃРµРЅС‚ТіРѕРё РєР°Р±СѓРґРё СЂР°РІС€Р°РЅ.
class GlassColors {
  // ---------------------------------------------------------------------------
  // 1. Р—Р°РјРёРЅР°Рё РіСЂР°РґРё РµРЅС‚ (deep blue background)
  // ---------------------------------------------------------------------------
  static const Color bgDeep = Color(0xFF0A1930);
  static const Color bgMid = Color(0xFF123B6B);

  /// Р’Р°СЂРёР°РЅС‚Рё РґСѓСЋРјРё Р·Р°РјРёРЅР° (Р±Р°СЂРѕРё РЅР°РІР±Р°С‚УЈ/СЌРєСЂР°РЅТіРѕРё РёР»РѕРІР°РіУЈ)
  static const Color bgAltDeep = Color(0xFF0F172A);
  static const Color bgAltMid = Color(0xFF1E3A5F);

  // ---------------------------------------------------------------------------
  // 2. Р Р°РЅРіТіРѕРё Р°РєСЃРµРЅС‚ (accent blues)
  // ---------------------------------------------------------------------------
  /// Р Р°РЅРіРё Р°РєСЃРµРЅС‚ 1 — РєР°Р±СѓРґРё СЂР°РІС€Р°РЅ
  static const Color accentSky = Color(0xFF38BDF8);

  /// Р Р°РЅРіРё Р°РєСЃРµРЅС‚ 2 — РєР°Р±СѓРґРё С‚РёСЂР° / РёРЅРґРёРіРѕ
  static const Color accentBlue = Color(0xFF3B82F6);

  /// Р Р°РЅРіРё Р°РєСЃРµРЅС‚ 3 — РєР°Р±СѓРґРё СЂР°РІС€Р°РЅРё РёР»РѕРІР°РіУЈ (Р±Р°СЂРѕРё glow blob)
  static const Color accentLight = Color(0xFF60A5FA);

  // ---------------------------------------------------------------------------
  // 3. РЁРёС€Р°Рё СЃР°С„РµРґ (white glass layers)
  // ---------------------------------------------------------------------------
  /// 8% СЃР°С„РµРґ — С€РёС€Р°Рё СЃР°Р±СѓРє
  static const Color glassSoft = Color(0x14FFFFFF);

  /// 12% СЃР°С„РµРґ — С€РёС€Р°Рё Р°СЃРѕСЃУЈ (РєР°СЂС‚ТіРѕ РІР° РїР°РЅРµР»ТіРѕ)
  static const Color glassFill = Color(0x1FFFFFFF);

  /// 15% СЃР°С„РµРґ — С€РёС€Р°Рё Т›Р°РІРёС‚Р°СЂ (РјР°Р№РґРѕРЅТіРѕРё РІРѕСЂРёРґРѕС‚, С‡РёРїТіРѕ)
  static const Color glassStrong = Color(0x26FFFFFF);

  /// 25% СЃР°С„РµРґ — РєР°РЅРѕСЂРё С€РёС€Р°
  static const Color glassBorder = Color(0x40FFFFFF);

  /// 35% СЃР°С„РµРґ — РєР°РЅРѕСЂРё С€РёС€Р°Рё С„Р°СЉРѕР» / Р°РєСЃРµРЅС‚
  static const Color glassBorderStrong = Color(0x59FFFFFF);

  // ---------------------------------------------------------------------------
  // 4. РњР°С‚РЅ
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xBFFFFFFF); // 75% СЃР°С„РµРґ
  static const Color textMuted = Color(0x99FFFFFF); // 60% СЃР°С„РµРґ

  // ---------------------------------------------------------------------------
  // 5. Р Р°РЅРіТіРѕРё ТіРѕР»Р°С‚ (semantic)
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = accentSky;

  /// РЎРѕСЏРё РєР°Р±СѓРґ Р±Р°СЂРѕРё С‚СѓРіРјР°ТіРѕ РІР° РєР°СЂС‚ТіРѕРё С„Р°СЉРѕР»
  static Color accentShadow([double opacity = 0.35]) =>
      accentBlue.withValues(alpha: opacity);

  static Color skyShadow([double opacity = 0.30]) =>
      accentSky.withValues(alpha: opacity);

  // Prevent instantiation
  GlassColors._();
}

/// Р“СЂР°РґРё РµРЅС‚ТіРѕРё СЏРіРѕРЅР°Рё Р±Р°СЂРЅРѕРјР°
class GlassGradients {
  /// Р“СЂР°РґРё РµРЅС‚Рё Р°СЃРѕСЃРёРё Р·Р°РјРёРЅР°: #0A1930 в†’ #123B6B в†’ #0A1930
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF09182F), Color(0xFF174B80), Color(0xFF0A1930)],
  );

  /// Р“СЂР°РґРё РµРЅС‚Рё Р°Р»С‚РµСЂРЅР°С‚РёРІРёРё Р·Р°РјРёРЅР°: #0F172A в†’ #1E3A5F в†’ #0A1930
  static const LinearGradient backgroundAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1B33), Color(0xFF1D4775), Color(0xFF0A1930)],
  );

  /// Р“СЂР°РґРё РµРЅС‚Рё С‚СѓРіРјР°Рё Р°СЃРѕСЃУЈ: #38BDF8 в†’ #3B82F6
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [GlassColors.accentSky, GlassColors.accentBlue],
  );

  /// Р“СЂР°РґРё РµРЅС‚Рё СЃР°Р±СѓРєРё Р°РєСЃРµРЅС‚ (Р±Р°СЂРѕРё РёРєРѕРЅТіРѕ РІР° С‡РёРїТіРѕРё С„Р°СЉРѕР»)
  static const LinearGradient accentSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [GlassColors.accentLight, GlassColors.accentBlue],
  );

  /// Р“СЂР°РґРё РµРЅС‚ Р±Р°СЂРѕРё ТіРѕР»Р°С‚Рё С…РѕРјУЇС€ (disabled)
  static const LinearGradient disabled = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [GlassColors.glassSoft, GlassColors.glassSoft],
  );

  // Prevent instantiation
  GlassGradients._();
}

/// Р Р°РґРёСѓСЃТіРѕРё СЏРіРѕРЅР°Рё С€РёС€Р°
class GlassRadius {
  static const double card = 22.0;
  static const double panel = 26.0;
  static const double field = 14.0;
  static const double button = 16.0;

  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get panelRadius => BorderRadius.circular(panel);
  static BorderRadius get fieldRadius => BorderRadius.circular(field);
  static BorderRadius get buttonRadius => BorderRadius.circular(button);

  // Prevent instantiation
  GlassRadius._();
}

/// РћСЂРѕРёС€Рё (decoration) СЏРіРѕРЅР°Рё С€РёС€Р° Р±Р°СЂРѕРё РєР°СЂС‚ТіРѕ, РїР°РЅРµР»ТіРѕ РІР° РјР°Р№РґРѕРЅТіРѕ.
BoxDecoration glassDecoration({
  double radius = GlassRadius.card,
  double fillOpacity = 0.12,
  double borderOpacity = 0.28,
  Color? color,
  Gradient? gradient,
  double borderWidth = 1.2,
  List<BoxShadow>? boxShadow,
}) {
  return BoxDecoration(
    color: gradient != null
        ? null
        : Color.lerp(
            GlassColors.bgDeep,
            color ?? Colors.white,
            color?.opacity ?? fillOpacity,
          ),
    gradient: gradient,
    borderRadius: BorderRadius.circular(radius),
    border: borderWidth <= 0
        ? null
        : Border.all(
            color: Colors.white.withValues(alpha: borderOpacity),
            width: borderWidth,
          ),
    boxShadow:
        boxShadow ??
        [
          BoxShadow(
            color: GlassColors.bgDeep.withValues(alpha: 0.16),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
  );
}

/// РћСЂРѕРёС€Рё РјР°Р№РґРѕРЅРё РІРѕСЂРёРґРѕС‚Рё С€РёС€Р°РіУЈ (InputDecoration СЏРіРѕРЅР°).
///
/// [borderless] — Р±Р°СЂРѕРё РјР°Р№РґРѕРЅТіРѕРµ, РєРё С…СѓРґР°С€РѕРЅ РґР°СЂ РґРѕС…РёР»Рё РєР°СЂС‚РѕС‡РєР°Рё С€РёС€Р°РіУЈ
/// Т·РѕР№РіРёСЂР°РЅРґ (InputBorder.none, С‚Р°РЅТіРѕ Р·Р°РјРёРЅР°Рё СЃР°С„РµРґРё С€Р°С„С„РѕС„).
InputDecoration glassInputDecoration({
  String? hintText,
  String? labelText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  Widget? counter,
  bool borderless = false,
  bool dense = false,
  double radius = GlassRadius.field,
  EdgeInsetsGeometry? contentPadding,
  Color? fillColor,
}) {
  final Color fill = Color.lerp(
    GlassColors.bgMid,
    fillColor ?? Colors.white,
    fillColor?.opacity ?? 0.14,
  )!;
  final textStyle = TextStyle(
    fontSize: dense ? 14 : 15,
    color: GlassColors.textPrimary,
    fontWeight: FontWeight.w500,
  );

  OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: width <= 0
        ? BorderSide.none
        : BorderSide(color: color, width: width),
  );

  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    hintStyle: textStyle.copyWith(
      color: Colors.white.withValues(alpha: 0.55),
      fontWeight: FontWeight.w400,
    ),
    labelStyle: textStyle.copyWith(
      color: Colors.white.withValues(alpha: 0.65),
      fontWeight: FontWeight.w400,
    ),
    floatingLabelStyle: textStyle.copyWith(color: GlassColors.accentSky),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    counter: counter,
    prefixIconColor: Colors.white.withValues(alpha: 0.75),
    suffixIconColor: Colors.white.withValues(alpha: 0.65),
    filled: true,
    fillColor: fill,
    isDense: dense,
    border: borderless
        ? InputBorder.none
        : outline(Colors.white.withValues(alpha: 0.25), 1),
    enabledBorder: borderless
        ? InputBorder.none
        : outline(Colors.white.withValues(alpha: 0.28), 1),
    focusedBorder: borderless
        ? InputBorder.none
        : outline(GlassColors.accentSky, 1.4),
    errorBorder: borderless ? InputBorder.none : outline(GlassColors.danger, 1),
    focusedErrorBorder: borderless
        ? InputBorder.none
        : outline(GlassColors.danger, 1.4),
    errorStyle: const TextStyle(color: GlassColors.danger, fontSize: 12),
    contentPadding:
        contentPadding ??
        (dense
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
  );
}

/// РўРµРјР°Рё СѓРјСѓРјРёРё Р±Р°СЂРЅРѕРјР°: СЂР°РЅРіТіРѕРё Material-СЂРѕ Р±Рѕ С€РёС€Р° ТіР°РјРѕТіР°РЅРі РјРµРєСѓРЅР°Рґ
/// (РґРёР°Р»РѕРіТіРѕ, SnackBar, InputDecoration, AppBar РІР° Т“Р°Р№СЂР°).
ThemeData buildGlassTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.white,
  );

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: GlassColors.accentSky,
      onPrimary: GlassColors.textPrimary,
      secondary: GlassColors.accentBlue,
      onSecondary: GlassColors.textPrimary,
      surface: GlassColors.bgMid,
      onSurface: GlassColors.textPrimary,
      error: GlassColors.danger,
      onError: GlassColors.textPrimary,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: GlassColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: GlassColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: GlassColors.textPrimary),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: GlassColors.bgMid,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlassRadius.panel),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      titleTextStyle: const TextStyle(
        color: GlassColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(
        color: GlassColors.textSecondary,
        fontSize: 14,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: Colors.transparent,
      modalBarrierColor: GlassColors.bgDeep.withValues(alpha: 0.65),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GlassRadius.panel),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: GlassColors.bgMid,
      contentTextStyle: const TextStyle(
        color: GlassColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlassRadius.field),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: GlassColors.accentSky,
      selectionColor: Color(0x5538BDF8),
      selectionHandleColor: GlassColors.accentSky,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.18),
      thickness: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: GlassColors.accentSky,
      linearTrackColor: Color(0x33FFFFFF),
      circularTrackColor: Color(0x33FFFFFF),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: GlassColors.accentSky),
    ),
    iconTheme: const IconThemeData(color: GlassColors.textPrimary),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: GlassColors.textPrimary),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: GlassColors.accentSky,
      textColor: GlassColors.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlassRadius.field),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: GlassColors.textPrimary,
      displayColor: GlassColors.textPrimary,
    ),
  );
}
