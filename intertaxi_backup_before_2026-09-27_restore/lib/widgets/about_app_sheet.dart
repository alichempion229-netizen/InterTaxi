import 'package:intertaxi/l10n/app_localizations.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../constants/light_glass_theme.dart';
import 'light_glass_widgets.dart';
import '../widgets/intertaxi_logo.dart';

/// Shows an "About" Modal Bottom Sheet in Glassmorphism (white & blue theme).
Future<void> showAboutAppSheet({required BuildContext context}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: LightGlassColors.textPrimary.withValues(alpha: 0.35),
    isScrollControlled: true,
    builder: (_) => const _AboutAppSheet(),
  );
}

class _AboutAppSheet extends StatelessWidget {
  const _AboutAppSheet();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(LightGlassRadius.panel),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(LightGlassRadius.panel),
            ),
            border: Border(
              top: BorderSide(
                color: LightGlassColors.glassBorderSubtle,
                width: 1.2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: LightGlassColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const InterTaxiLogo(size: 96, showTagline: true),
              const SizedBox(height: 14),
              StatusBadge(label: 'v1.0.0'),
              const SizedBox(height: 18),
              Text(
                AppLocalizations.translate(
                  '''InterTaxi — платформаи мусофиркашӣ барои тамоми Тоҷикистон.  Бо якчанд клик сафари худро ёбед ё ҳамчун ронанда сафари  худро эълон кунед. Муқимӣ, бехатар ва бо нархи ошкоро.')),''',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: LightGlassColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              LightGlassButton(
                text: AppLocalizations.translate('Пӯшидан'),
                onPressed: () => Navigator.of(context).pop(),
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
