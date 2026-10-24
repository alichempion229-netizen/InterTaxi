import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:intertaxi/app_icons.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/glass_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_widgets.dart';
import 'location_selection_screen.dart';

/// InterTaxi Passenger Trip Selection Screen
/// Premium trip booking screen in Tajik language
class PassengerTripScreen extends StatefulWidget {
  final String passengerName;
  final String passengerPhone;

  const PassengerTripScreen({
    super.key,
    required this.passengerName,
    required this.passengerPhone,
  });

  @override
  State<PassengerTripScreen> createState() => _PassengerTripScreenState();
}

class _PassengerTripScreenState extends State<PassengerTripScreen> {
  String? _selectedStartLocation;
  String? _selectedDestination;
  bool _isLoading = false;
  bool _isStartCardExpanded = false;
  bool _isDestinationCardExpanded = false;

  final List<String> _startLocations = [
    'Кӯлоб',
    'Душанбе',
    'Восеъ',
  ];

  final List<String> _destinationLocations = [
    'Кӯлоб',
    'Душанбе',
    'Восеъ',
  ];

  void _handleLocationSelect(String type, String location) {
    setState(() {
      if (type == 'start') {
        _selectedStartLocation = location;
        _isStartCardExpanded = false;
      } else {
        _selectedDestination = location;
        _isDestinationCardExpanded = false;
      }
    });
  }

  void _handleSearch() {
    if (_selectedStartLocation == null || _selectedDestination == null) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to next screen
        // TODO: Navigate to driver selection screen
        print('Search: $_selectedStartLocation to $_selectedDestination');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Welcome Title
                  Text(
                    AppLocalizations.translate(
                      'Хуш омадед, мусофир!',
                    ),
                    style: TextStyle(
                      fontSize: AppConstants.welcomeTitleSize,
                      fontWeight: FontWeight.w700,
                      color: GlassColors.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    AppLocalizations.translate(
                      'Биёед саёҳати худро оғоз кунем',
                    ),
                    style: TextStyle(
                      fontSize: AppConstants.welcomeSubtitleSize,
                      fontWeight: FontWeight.w400,
                      color: GlassColors.textSecondary,
                      letterSpacing: 0.2,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Starting Location Card
                  _buildLocationCard(
                    title: AppLocalizations.translate(
                      'Аз куҷо меравед?',
                    ),
                    placeholder:
                        'Ҷойи оғозро интихоб кунед',
                    selectedLocation: _selectedStartLocation,
                    icon: AppIcons.trip_origin_rounded,
                    onTap: () => _openLocationScreen('start'),
                  ),
                  const SizedBox(height: 16),
                  // Destination Card
                  _buildLocationCard(
                    title: AppLocalizations.translate(
                      'Ба куҷо рафтан мехоҳед?',
                    ),
                    placeholder:
                        'Макони таъинотро интихоб кунед',
                    selectedLocation: _selectedDestination,
                    icon: AppIcons.location_on_rounded,
                    onTap: () => _openLocationScreen('destination'),
                  ),
                  const SizedBox(height: 40),
                  // Search Button
                  CustomButton(
                    text: AppLocalizations.translate(
                      'Ҷустуҷӯи мошин',
                    ),
                    onPressed: _handleSearch,
                    isLoading: _isLoading,
                    enabled:
                        _selectedStartLocation != null &&
                        _selectedDestination != null &&
                        !_isLoading,
                  ),
                  const SizedBox(height: 24),
                  // Helper Text
                  Center(
                    child: Text(
                      AppLocalizations.translate(
                        'Нуқтаҳои дигарро низ интихоб карда метавонед',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: GlassColors.textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openLocationScreen(String type) {
    final locations = type == 'start' ? _startLocations : _destinationLocations;
    final selected = type == 'start'
        ? _selectedStartLocation
        : _selectedDestination;
    final title = type == 'start'
        ? 'Аз куҷо меравед?'
        : 'Ба куҷо рафтан мехоҳед?';

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LocationSelectionScreen(
              title: title,
              locations: locations,
              selectedLocation: selected,
              onSelect: (location) => _handleLocationSelect(type, location),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required String placeholder,
    required String? selectedLocation,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      radius: 20,
      padding: EdgeInsets.zero,
      blur: 14,
      borderOpacity: selectedLocation != null ? 0.5 : 0.28,
      glow: selectedLocation != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon with glass styling
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: selectedLocation != null
                          ? GlassGradients.accent
                          : null,
                      color: selectedLocation != null
                          ? null
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: selectedLocation != null
                          ? GlassColors.textPrimary
                          : GlassColors.accentSky,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and selected location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: GlassColors.textMuted,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedLocation ?? placeholder,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: selectedLocation != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selectedLocation != null
                                ? GlassColors.textPrimary
                                : GlassColors.textSecondary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow icon
                  Icon(
                    AppIcons.arrow_forward_ios_rounded,
                    size: 20,
                    color: selectedLocation != null
                        ? GlassColors.accentSky
                        : GlassColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
