import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intertaxi/l10n/app_localizations.dart';
import '../constants/light_glass_theme.dart';

/// Light Glassmorphism Background with soft blue glow blobs
class LightGlassBackground extends StatelessWidget {
  final Widget child;

  const LightGlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LightGlassGradients.background,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Light Frosted White Glass Card
class LightGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double radius;
  final VoidCallback? onTap;

  const LightGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.width,
    this.height,
    this.radius = LightGlassRadius.card,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget surface = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: LightGlassColors.glassBorderSubtle,
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100B3475),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: LightGlassColors.primaryBlue.withValues(alpha: 0.08),
          child: surface,
        ),
      );
    }

    return margin != null ? Padding(padding: margin!, child: surface) : surface;
  }
}

/// Light Glass Button
class LightGlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final double height;
  final double fontSize;
  final IconData? icon;

  const LightGlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.fontSize = 15,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LightGlassGradients.primary,
        borderRadius: BorderRadius.circular(LightGlassRadius.button),
        boxShadow: [
          BoxShadow(
            color: LightGlassColors.primaryBlue.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(LightGlassRadius.button),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        AppLocalizations.translate(text),
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Light Glass Text Field
class LightGlassTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final bool dense;

  const LightGlassTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            AppLocalizations.translate(label!),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: LightGlassColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(LightGlassRadius.field),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(LightGlassRadius.field),
              border: Border.all(
                color: LightGlassColors.glassBorderSubtle,
                width: 1.2,
              ),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              obscureText: obscureText,
              validator: validator,
              onChanged: onChanged,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                color: LightGlassColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: LightGlassColors.primaryBlue,
              decoration: InputDecoration(
                hintText: hintText == null
                    ? null
                    : AppLocalizations.translate(hintText!),
                hintStyle: TextStyle(
                  color: LightGlassColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: dense ? 12 : 15,
                ),
                errorStyle: const TextStyle(
                  color: LightGlassColors.danger,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Consistent section heading with an optional compact action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: LightGlassColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      if (actionLabel != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: LightGlassColors.primaryBlue,
          ),
          child: Text(actionLabel!),
        ),
    ],
  );
}

/// Small semantic status label with a readable tinted background.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    this.color = LightGlassColors.primaryBlue,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(LightGlassRadius.pill),
      border: Border.all(color: color.withValues(alpha: 0.18)),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

/// Calm, consistent empty state for lists and search results.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      vertical: LightGlassSpacing.xxl,
      horizontal: LightGlassSpacing.xl,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: LightGlassColors.lightBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: LightGlassColors.primaryBlue, size: 26),
        ),
        const SizedBox(height: LightGlassSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LightGlassColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: LightGlassSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LightGlassColors.textSecondary,
            height: 1.45,
            fontSize: 13,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: LightGlassSpacing.lg),
          action!,
        ],
      ],
    ),
  );
}

/// Compact press feedback for icon actions in headers and cards.
class AnimatedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      foregroundColor: LightGlassColors.primaryBlue,
      backgroundColor: LightGlassColors.surface,
      side: const BorderSide(color: LightGlassColors.glassBorderSubtle),
      fixedSize: const Size(44, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Icon(icon, key: ValueKey(icon), size: 20),
    ),
  );
}
