import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intertaxi/l10n/app_localizations.dart';
import '../constants/app_constants.dart';
import '../constants/glass_theme.dart';

/// InterTaxi Custom Text Field (glassmorphism)
/// РњР°Р№РґРѕРЅРё РІРѕСЂРёРґРѕС‚ Р±Рѕ Р·Р°РјРёРЅР°Рё СЃР°С„РµРґРё С€Р°С„С„РѕС„, РєР°РЅРѕСЂРё СЃР°С„РµРґ РІР° hint-Рё СЃР°С„РµРґРё
/// РЅРёРјС€Р°С„С„РѕС„ вЂ” РјСѓРІРѕС„РёТ›Рё СѓСЃР»СѓР±Рё С€РёС€Р°РіРёРё Р±Р°СЂРЅРѕРјР°.
class CustomTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final bool enabled;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.label,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.controller,
    this.enabled = true,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;

  void _handleFocusChange(bool focused) {
    setState(() {
      _isFocused = focused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool multiline = widget.maxLines != null && widget.maxLines! > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          AppLocalizations.translate(widget.label),
          style: TextStyle(
            fontSize: AppConstants.fieldLabelSize,
            fontWeight: FontWeight.w600,
            color: _isFocused
                ? GlassColors.accentSky
                : GlassColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        // Text Field (glass)
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.fieldBorderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              decoration: BoxDecoration(
                color: GlassColors.bgMid,
                borderRadius: BorderRadius.circular(
                  AppConstants.fieldBorderRadius,
                ),
                border: Border.all(
                  color: _isFocused
                      ? GlassColors.accentSky.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.28),
                  width: AppConstants.fieldBorderWidth,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: GlassColors.accentSky.withValues(alpha: 0.14),
                          blurRadius: 10,
                          spreadRadius: -4,
                        ),
                      ]
                    : null,
              ),
              child: SizedBox(
                height: multiline ? null : AppConstants.fieldHeight,
                child: Focus(
                  onFocusChange: _handleFocusChange,
                  child: TextFormField(
                    controller: widget.controller,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    obscureText: widget.obscureText,
                    validator: widget.validator,
                    onChanged: widget.onChanged,
                    enabled: widget.enabled,
                    maxLines: widget.maxLines,
                    inputFormatters: widget.inputFormatters,
                    cursorColor: GlassColors.accentSky,
                    style: const TextStyle(
                      fontSize: AppConstants.fieldTextSize,
                      fontWeight: FontWeight.w500,
                      color: GlassColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                    decoration: glassInputDecoration(
                      hintText: widget.hintText == null
                          ? null
                          : AppLocalizations.translate(widget.hintText!),
                      borderless: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
