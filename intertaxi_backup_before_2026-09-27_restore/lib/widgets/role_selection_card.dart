import 'package:intertaxi/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intertaxi/l10n/app_localizations.dart';
import '../constants/app_constants.dart';
import '../constants/glass_theme.dart';
import 'glass_widgets.dart';

enum UserRole { passenger, driver }

class RoleSelectionCard extends StatefulWidget {
  final UserRole role;
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<UserRole>? onTap;

  const RoleSelectionCard({
    super.key,
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<RoleSelectionCard> createState() => _RoleSelectionCardState();
}

class _RoleSelectionCardState extends State<RoleSelectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.cardSelectionAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppConstants.cardSelectionCurve,
      ),
    );

    if (widget.isSelected) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(RoleSelectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call(widget.role);
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              radius: GlassRadius.card,
              fillOpacity: isSelected ? 0.22 : 0.12,
              borderOpacity: isSelected ? 0.60 : 0.25,
              glow: isSelected,
              child: Stack(
                children: [
                  if (isSelected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          gradient: GlassGradients.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          AppIcons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: isSelected ? GlassGradients.accent : null,
                          color: isSelected
                              ? null
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? GlassColors.accentSky
                                : Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 30,
                          color: isSelected
                              ? Colors.white
                              : GlassColors.accentSky,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        AppLocalizations.translate(widget.title),
                        style: const TextStyle(
                          fontSize: AppConstants.roleCardTitleSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.translate(widget.description),
                        style: TextStyle(
                          fontSize: AppConstants.roleCardDescriptionSize,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
