import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/glass_theme.dart';

/// Р—Р°РјРёРЅР°Рё СѓРјСѓРјРёРё glassmorphism Р±Р°СЂРѕРё ТіР°РјР°Рё СЃР°ТіРёС„Р°ТіРѕ:
/// РіСЂР°РґРё РµРЅС‚Рё РєР°Р±СѓРґРё С‚РёСЂР° (#0A1930 в†’ #123B6B в†’ #0A1930) + blob-ТіРѕРё РЅСѓСЂУЈ.
class GlassBackground extends StatelessWidget {
  final Widget child;

  /// РќРёС€РѕРЅ РґРѕРґР°РЅРё blob-ТіРѕРё РЅСѓСЂУЈ (glow blobs)
  final bool showBlobs;

  /// Blob-ТіРѕРё С„Р°СЂРјРѕРёС€УЈ (Р±Р° Т·РѕРё blob-ТіРѕРё РїРµС€С„Р°СЂР·)
  final List<Widget>? blobs;

  /// Р“СЂР°РґРё РµРЅС‚Рё С„Р°СЂРјРѕРёС€УЈ
  final Gradient? gradient;

  const GlassBackground({
    super.key,
    required this.child,
    this.showBlobs = true,
    this.blobs,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // 1. Р“СЂР°РґРё РµРЅС‚Рё РєР°Р±СѓРґРё С‚РёСЂР°
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient:
                  gradient ??
                  const LinearGradient(colors: [Colors.white, Colors.white]),
            ),
          ),
        ),

        // 2. Blob-ТіРѕРё РЅСѓСЂУЈ РґР°СЂ РєСѓРЅТ·ТіРѕ

        // 3. РљРѕРЅС‚РµРЅС‚Рё СЃР°ТіРёС„Р°
        child,
      ],
    );
  }

  static const List<Widget> _defaultBlobs = [
    Positioned(
      top: -90,
      right: -70,
      child: GlowBlob(size: 240, color: GlassColors.accentSky, opacity: 0.52),
    ),
    Positioned(
      top: 250,
      left: -110,
      child: GlowBlob(size: 230, color: GlassColors.accentLight, opacity: 0.46),
    ),
    Positioned(
      bottom: -120,
      right: -60,
      child: GlowBlob(size: 260, color: GlassColors.accentBlue, opacity: 0.42),
    ),
  ];
}

/// Р”РѕРёСЂР°Рё РєР°Р»РѕРЅРё РЅСѓСЂУЈ (glow blob) Р±Рѕ blur-Рё 80px.
class GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  final double blur;

  const GlowBlob({
    super.key,
    this.size = 220,
    this.color = GlassColors.accentSky,
    this.opacity = 0.5,
    this.blur = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}

/// РљР°СЂС‚РѕС‡РєР°Рё С€РёС€Р°РіРёРё glassmorphism:
/// ClipRRect в†’ BackdropFilter(blur) в†’ С€РёС€Р°Рё СЃР°С„РµРґРё С€Р°С„С„РѕС„ + РєР°РЅРѕСЂРё СЃР°С„РµРґ.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double radius;
  final double blur;

  /// РЁР°С„С„РѕС„РёСЏС‚Рё С€РёС€Р°Рё СЃР°С„РµРґ (0.08 – 0.15)
  final double fillOpacity;

  /// РЁР°С„С„РѕС„РёСЏС‚Рё РєР°РЅРѕСЂРё СЃР°С„РµРґ (0.25 – 0.35)
  final double borderOpacity;

  final Color? fillColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;

  /// РЎРѕСЏРё РєР°Р±СѓРґРё Р°РєСЃРµРЅС‚ (Р±Р°СЂРѕРё ТіРѕР»Р°С‚Рё С„Р°СЉРѕР»)
  final bool glow;

  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.width,
    this.height,
    this.radius = GlassRadius.card,
    this.blur = 14,
    this.fillOpacity = 1,
    this.borderOpacity = 0.28,
    this.fillColor,
    this.gradient,
    this.boxShadow,
    this.glow = false,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = borderRadius ?? BorderRadius.circular(radius);

    Widget surface = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient != null
            ? null
            : Color.lerp(
                GlassColors.bgMid,
                fillColor ?? Colors.white,
                fillColor?.opacity ?? fillOpacity,
              ),
        gradient: gradient,
        borderRadius: br,
        border: Border.all(
          color: Colors.white.withValues(alpha: borderOpacity * 0.55),
          width: 1.2,
        ),
        boxShadow:
            boxShadow ??
            (glow
                ? [
                    BoxShadow(
                      color: GlassColors.accentBlue.withValues(alpha: 0.16),
                      blurRadius: 12,
                      spreadRadius: -2,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: GlassColors.bgDeep.withValues(alpha: 0.18),
                      blurRadius: 12,
                      spreadRadius: -4,
                      offset: const Offset(0, 10),
                    ),
                  ]),
      ),
      child: child,
    );

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: surface,
        ),
      );
    }

    return RepaintBoundary(
      child: Padding(
        padding: margin ?? EdgeInsets.zero,
        child: ClipRRect(borderRadius: br, child: surface),
      ),
    );
  }
}

/// РџР°РЅРµР»Рё С€РёС€Р°РіРёРё СЃР°Р±СѓРє (Р±Рµ blur) — Р±Р°СЂРѕРё СЂУЇР№С…Р°С‚ТіРѕРё РґР°СЂРѕР· РІР° С‡РёРїТіРѕ,
/// С‚Рѕ РєРё СЃР°ТіРёС„Р° С‚РµР· РєРѕСЂ РєСѓРЅР°Рґ.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double radius;
  final double fillOpacity;
  final double borderOpacity;
  final Color? fillColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
    this.radius = GlassRadius.card,
    this.fillOpacity = 0.10,
    this.borderOpacity = 0.26,
    this.fillColor,
    this.gradient,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = BorderRadius.circular(radius);

    final Widget surface = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient != null
            ? null
            : (fillColor ?? Colors.white.withValues(alpha: fillOpacity)),
        gradient: gradient,
        borderRadius: br,
        border: Border.all(
          color: Colors.white.withValues(alpha: borderOpacity),
          width: 1.2,
        ),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: onTap == null
          ? surface
          : Material(
              color: Colors.transparent,
              borderRadius: br,
              child: InkWell(onTap: onTap, borderRadius: br, child: surface),
            ),
    );
  }
}

/// РўСѓРіРјР°Рё Р°СЃРѕСЃРёРё С€РёС€Р°РіУЈ: РіСЂР°РґРё РµРЅС‚ [#38BDF8, #3B82F6], РєР°РЅРѕСЂРё СЃР°С„РµРґ,
/// СЃРѕСЏРё РєР°Р±СѓРґ. Р‘Р°СЂРѕРё ТіРѕР»Р°С‚Рё РґСѓСЋРјРґР°СЂР°Т·Р° — outlined: true.
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool enabled;
  final bool outlined;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final double? fontSize;

  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
    this.outlined = false,
    this.height = 54,
    this.radius = GlassRadius.button,
    this.margin,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = enabled && onPressed != null && !isLoading;
    final BorderRadius br = BorderRadius.circular(radius);

    final Gradient? gradient = outlined || !isActive
        ? null
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563D9), Color(0xFF3478E5)],
          );
    final Color fill = outlined
        ? const Color(0xFF17385F)
        : (isActive ? const Color(0xFF2563D9) : const Color(0xFF29405E));

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: br,
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? fill : null,
              borderRadius: br,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: GlassColors.accentBlue.withValues(
                          alpha: outlined ? 0.10 : 0.16,
                        ),
                        blurRadius: 12,
                        spreadRadius: -2,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isActive ? onPressed : null,
                borderRadius: br,
                splashColor: Colors.white.withValues(alpha: 0.14),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(
                              GlassColors.textPrimary,
                            ),
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icon != null) ...[
                                Icon(
                                  icon,
                                  size: 20,
                                  color: isActive
                                      ? GlassColors.textPrimary
                                      : GlassColors.textMuted,
                                ),
                                const SizedBox(width: 10),
                              ],
                              Text(
                                text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isActive
                                      ? GlassColors.textPrimary
                                      : GlassColors.textMuted,
                                  fontSize: fontSize ?? 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// РўСѓРіРјР°Рё РёРєРѕРЅР°Рё С€РёС€Р°РіУЈ (РґРѕРёСЂР° С‘ РєРІР°РґСЂР°С‚Рё РјСѓРґР°РІРІР°СЂ).
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final bool round;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.iconSize = 20,
    this.iconColor,
    this.round = true,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius br = round
        ? BorderRadius.circular(size)
        : BorderRadius.circular(GlassRadius.field);

    return ClipRRect(
      borderRadius: br,
      child: Material(
        color: GlassColors.bgMid,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.2,
              ),
              borderRadius: br,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor ?? GlassColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Р§РёРїРё С€РёС€Р°РіРёРё ТіРѕР»Р°С‚ (badge/pill) Р±Рѕ РёРјРєРѕРЅРё СЂР°РЅРіРё С„Р°СЂРјРѕРёС€УЈ.
class GlassChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color accent;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.accent = GlassColors.accentSky,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: accent),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: GlassColors.textPrimary,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// РњР°Р№РґРѕРЅРё РІРѕСЂРёРґРѕС‚Рё С€РёС€Р°РіУЈ (TextField/TextFormField Р±Рѕ Р·Р°РјРёРЅР°Рё СЃР°С„РµРґРё С€Р°С„С„РѕС„,
/// РєР°РЅРѕСЂРё СЃР°С„РµРґ РІР° hint-Рё СЃР°С„РµРґРё РЅРёРјС€Р°С„С„РѕС„).
class GlassTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? counter;

  /// РњР°Р№РґРѕРЅ РґР°СЂ РґРѕС…РёР»Рё РєР°СЂС‚РѕС‡РєР°Рё С€РёС€Р°РіУЈ Т·РѕР№РіРёСЂ С€СѓРґР°Р°СЃС‚ (InputBorder.none)
  final bool borderless;

  final double radius;
  final bool dense;

  const GlassTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onTap,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.counter,
    this.borderless = false,
    this.radius = GlassRadius.field,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      autofocus: autofocus,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontSize: dense ? 14 : 15,
        color: GlassColors.textPrimary,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      cursorColor: GlassColors.accentSky,
      decoration: glassInputDecoration(
        hintText: hintText,
        borderless: borderless,
        dense: dense,
        radius: radius,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        counter: counter,
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: GlassColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}
