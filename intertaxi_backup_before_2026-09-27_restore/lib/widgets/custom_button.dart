import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:intertaxi/l10n/app_localizations.dart';
import '../constants/app_constants.dart';
import '../constants/glass_theme.dart';

/// InterTaxi Custom Button (glassmorphism)
/// РўСѓРіРјР°Рё Р°СЃРѕСЃУЈ: РіСЂР°РґРё РµРЅС‚ [#38BDF8, #3B82F6] + РєР°РЅРѕСЂРё СЃР°С„РµРґ + СЃРѕСЏРё РєР°Р±СѓРґ
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = enabled && onPressed != null && !isLoading;
    final BorderRadius radius = BorderRadius.circular(
      AppConstants.buttonBorderRadius,
    );
    final Color fillColor =
        backgroundColor ??
        (isActive ? const Color(0xFF2563D9) : const Color(0xFF29405E));

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          height: AppConstants.buttonHeight,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: GlassColors.accentBlue.withValues(alpha: 0.15),
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
              borderRadius: radius,
              splashColor: Colors.white.withValues(alpha: 0.14),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            textColor ?? GlassColors.textPrimary,
                          ),
                        ),
                      )
                    : Text(
                        AppLocalizations.translate(text),
                        style: TextStyle(
                          fontSize: AppConstants.buttonTextSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: isActive
                              ? textColor ?? GlassColors.textPrimary
                              : GlassColors.textMuted,
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
