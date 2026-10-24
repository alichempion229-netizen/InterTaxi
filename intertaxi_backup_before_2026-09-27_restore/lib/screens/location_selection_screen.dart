import 'package:intertaxi/app_icons.dart';
import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/glass_theme.dart';
import '../widgets/glass_widgets.dart';

/// InterTaxi Location Selection Screen
/// Simple screen for selecting cities
class LocationSelectionScreen extends StatefulWidget {
  final String title;
  final List<String> locations;
  final String? selectedLocation;
  final ValueChanged<String> onSelect;

  const LocationSelectionScreen({
    super.key,
    required this.title,
    required this.locations,
    this.selectedLocation,
    required this.onSelect,
  });

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Title
                Text(
                  AppLocalizations.translate(widget.title),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: GlassColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Location List
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.locations.length,
                    itemBuilder: (context, index) {
                      final location = widget.locations[index];
                      final isSelected = widget.selectedLocation == location;

                      return GestureDetector(
                        onTap: () {
                          widget.onSelect(location);
                        },
                        child: GlassCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          radius: GlassRadius.field,
                          blur: 12,
                          padding: const EdgeInsets.all(16),
                          fillColor: isSelected
                              ? GlassColors.accentBlue.withValues(alpha: 0.28)
                              : null,
                          borderOpacity: isSelected ? 0.6 : 0.28,
                          glow: isSelected,
                          child: Row(
                            children: [
                              // Location icon with glass background
                              Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? GlassGradients.accent
                                      : null,
                                  color: isSelected
                                      ? null
                                      : Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.28),
                                  ),
                                ),
                                child: const Icon(
                                  AppIcons.location_on_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Location name
                              Expanded(
                                child: Text(
                                  AppLocalizations.translate(location),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? GlassColors.textPrimary
                                        : GlassColors.textSecondary,
                                  ),
                                ),
                              ),
                              // Check icon
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    gradient: GlassGradients.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    AppIcons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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
