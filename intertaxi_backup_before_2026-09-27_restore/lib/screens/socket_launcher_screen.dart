import 'package:intertaxi/app_icons.dart';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../constants/glass_theme.dart';
import '../widgets/glass_widgets.dart';
import 'socket_passenger_screen.dart';
import 'socket_driver_screen.dart';

/// Launcher screen for the Socket.IO real-time demo.
///
/// Provides quick access to the passenger and driver screens
/// that connect to the Flask-SocketIO backend.
class SocketLauncherScreen extends StatelessWidget {
  const SocketLauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Socket.IO Live Demo'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: GlassColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
      ),
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  AppIcons.wifi_tethering,
                  size: 80,
                  color: GlassColors.accentSky,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Real-Time Taxi Demo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: GlassColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect to the Flask-SocketIO server on your PC',
                  style: TextStyle(
                    fontSize: 14,
                    color: GlassColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildDemoCard(
                  context,
                  title: 'Passenger',
                  description: 'Request rides and track drivers in real-time',
                  icon: AppIcons.person,
                  color: GlassColors.accentSky,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SocketPassengerScreen(
                          passengerName: 'Demo Passenger',
                          passengerPhone: '+992 900 000 001',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildDemoCard(
                  context,
                  title: 'Driver',
                  description: 'Accept orders and share live GPS location',
                  icon: AppIcons.directions_car,
                  color: GlassColors.accentBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SocketDriverScreen(
                          driverName: 'Demo Driver',
                          driverPhone: '+992 900 000 002',
                          driverCar: 'Toyota Camry (White)',
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                GlassCard(
                  radius: GlassRadius.field,
                  padding: const EdgeInsets.all(14),
                  fillColor: GlassColors.warning.withValues(alpha: 0.16),
                  borderOpacity: 0.45,
                  child: const Text(
                    'Make sure your Flask-SocketIO server is running on your PC '
                    'and the app is pointed at its IP (server address button in the ads tab)..',
                    style: TextStyle(
                      fontSize: 12,
                      color: GlassColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(20),
      blur: 14,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: GlassGradients.accent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: GlassColors.accentBlue.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: GlassColors.textPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: GlassColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GlassColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            AppIcons.arrow_forward_ios,
            size: 18,
            color: GlassColors.textMuted,
          ),
        ],
      ),
    );
  }
}
