import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:intertaxi/app_icons.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/light_glass_theme.dart';
import '../widgets/light_glass_widgets.dart';
import 'socket_passenger_screen.dart';
import 'socket_driver_screen.dart';

enum UserRole { passenger, driver }

/// InterTaxi User Role Selection Screen (Light Glassmorphism White & Blue Theme)
class RoleSelectionScreen extends StatefulWidget {
  final String passengerName;
  final String passengerPhone;

  const RoleSelectionScreen({
    super.key,
    required this.passengerName,
    required this.passengerPhone,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;
  bool _isLoading = false;

  void _handleRoleSelection(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _handleContinue() {
    if (_selectedRole == null) return;

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (_selectedRole == UserRole.passenger) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SocketPassengerScreen(
                passengerName: widget.passengerName,
                passengerPhone: widget.passengerPhone,
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SocketDriverScreen(
                driverName: widget.passengerName,
                driverPhone: widget.passengerPhone,
                driverCar: 'Toyota Camry (White)',
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightGlassColors.bgLight1,
      body: LightGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Text(
                    AppLocalizations.translate('Шумо кӣ ҳастед?'),
                    style: TextStyle(
                      fontSize: AppConstants.roleTitleSize,
                      fontWeight: FontWeight.w700,
                      color: LightGlassColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.translate(
                      'Барои идома додан нақши худро дар барнома интихоб кунед',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: LightGlassColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildGlassCard(
                    role: UserRole.passenger,
                    title: AppLocalizations.translate('РњСѓСЃРѕС„РёСЂ'),
                    description:
                        'Ман мехоҳам бо таксӣ сафар кунам',
                    icon: AppIcons.person_rounded,
                    isSelected: _selectedRole == UserRole.passenger,
                    onTap: () => _handleRoleSelection(UserRole.passenger),
                  ),
                  const SizedBox(height: 16),
                  _buildGlassCard(
                    role: UserRole.driver,
                    title: AppLocalizations.translate('Ронанда'),
                    description:
                        'Ман мехоҳам ҳамчун ронанда кор кунам',
                    icon: AppIcons.directions_car_rounded,
                    isSelected: _selectedRole == UserRole.driver,
                    onTap: () => _handleRoleSelection(UserRole.driver),
                  ),
                  const SizedBox(height: 40),
                  LightGlassButton(
                    text: AppLocalizations.translate('Идома додан'),
                    onPressed: _selectedRole == null ? () {} : _handleContinue,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required UserRole role,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return LightGlassCard(
      padding: const EdgeInsets.all(20),
      radius: AppConstants.roleCardBorderRadius,
      onTap: onTap,
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
                  gradient: LightGlassGradients.primary,
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
                width: AppConstants.roleCardIconSize,
                height: AppConstants.roleCardIconSize,
                decoration: BoxDecoration(
                  gradient: isSelected ? LightGlassGradients.primary : null,
                  color: isSelected
                      ? null
                      : LightGlassColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isSelected
                      ? Colors.white
                      : LightGlassColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppConstants.roleCardTitleSize,
                  fontWeight: FontWeight.w700,
                  color: LightGlassColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  fontSize: AppConstants.roleCardDescriptionSize,
                  fontWeight: FontWeight.w400,
                  color: LightGlassColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
