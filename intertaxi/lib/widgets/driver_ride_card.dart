import 'dart:io';

import 'package:intertaxi/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/light_glass_theme.dart';
import '../models/driver_ride_model.dart';
import '../services/api_service.dart';

/// Passenger search result card for a driver's announced ride.
class DriverRideCard extends StatefulWidget {
  final DriverRide ride;
  final String searchFrom;
  final String searchTo;

  /// Called when the card or the details action is tapped.
  final VoidCallback? onTap;

  const DriverRideCard({
    super.key,
    required this.ride,
    required this.searchFrom,
    required this.searchTo,
    this.onTap,
  });

  @override
  State<DriverRideCard> createState() => _DriverRideCardState();
}

class _DriverRideCardState extends State<DriverRideCard> {
  bool _cardPressed = false;
  bool _selectPressed = false;
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _loadLocalAvatar();
  }

  Future<void> _loadLocalAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final ownPhone = (prefs.getString('user_phone') ?? '')
        .replaceAll(RegExp(r'\D'), '');
    final ridePhone = widget.ride.driverPhone.replaceAll(RegExp(r'\D'), '');
    final path = prefs.getString('user_avatar_path') ?? '';
    if (ownPhone.isNotEmpty && ownPhone == ridePhone && path.isNotEmpty &&
        await File(path).exists() && mounted) {
      setState(() => _localAvatarPath = path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.ride.route.isNotEmpty
        ? widget.ride.route.first
        : widget.searchFrom;
    final to = widget.ride.route.length > 1
        ? widget.ride.route.last
        : widget.searchTo;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Listener(
          onPointerDown: (_) => setState(() => _cardPressed = true),
          onPointerUp: (_) => setState(() => _cardPressed = false),
          onPointerCancel: (_) => setState(() => _cardPressed = false),
          child: AnimatedScale(
            scale: _cardPressed ? 0.98 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onTap?.call();
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: LightGlassColors.glassBorderSubtle,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildRoute(from, to),
                              const SizedBox(height: 8),
                              _buildInfoRow(),
                              const SizedBox(height: 8),
                              _buildDriverRow(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 96,
                          child: Column(
                            children: [
                              if (widget.ride.durationMinutes > 0)
                                _buildDurationBadge(),
                              const Spacer(),
                              _buildSelectButton(),
                            ],
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
  Widget _buildRoute(String from, String to) {
    return SizedBox(
      height: 58,
      child: Stack(
        children: [
          Positioned(
            left: 5.5,
            top: 13,
            bottom: 13,
            child: Container(width: 1, color: LightGlassColors.divider),
          ),
          _routeRow(from, LightGlassColors.success, 0),
          _routeRow(to, LightGlassColors.warning, 32),
          Positioned(
            left: 18,
            right: 0,
            top: 21,
            height: 16,
            child: Row(
              children: [
                const Expanded(child: Divider(height: 1, color: LightGlassColors.divider)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(Icons.directions_car_outlined, size: 16, color: LightGlassColors.textMuted),
                ),
                const Expanded(child: Divider(height: 1, color: LightGlassColors.divider)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeRow(String city, Color dotColor, double top) {
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      height: 26,
      child: Row(
        children: [
          SizedBox(
            width: 12,
            height: 26,
            child: Center(child: _routeDot(dotColor)),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                city,
                maxLines: 1,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: LightGlassColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _routeDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 9,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Expanded(child: _infoChip(AppIcons.sell_outlined, 'Нархи як ҷой:', '${widget.ride.fullRoutePrice} сомонӣ')),
        const SizedBox(width: 8),
        Expanded(child: _infoChip(AppIcons.people_outline_rounded, 'Озод:', '${widget.ride.availableSeats} ҷой')),
      ],
    );
  }
  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: LightGlassColors.surfaceTint, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, maxLines: 1, style: const TextStyle(fontSize: 11, color: LightGlassColors.textMuted)),
          ),
          const SizedBox(height: 1),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: LightGlassColors.primaryBlue),
                  const SizedBox(width: 4),
                  Text(value, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LightGlassColors.textPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDriverRow() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: LightGlassColors.lightBlue, shape: BoxShape.circle),
          child: widget.ride.driverAvatarUrl.isEmpty
              ? const Icon(AppIcons.person_rounded, size: 20, color: LightGlassColors.primaryBlue)
              : ClipOval(
                  child: Image.network(
                    ApiService.resolvePhotoUrl(widget.ride.driverAvatarUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _localAvatarPath == null
                        ? const Icon(AppIcons.person_rounded, size: 20, color: LightGlassColors.primaryBlue)
                        : Image.file(File(_localAvatarPath!), width: 36, height: 36, fit: BoxFit.cover),
                  ),
                ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(widget.ride.driverName.isEmpty ? 'Ронанда' : widget.ride.driverName, maxLines: 1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: LightGlassColors.textPrimary)),
              ),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('тел: ${widget.ride.driverPhone.isEmpty ? '—' : widget.ride.driverPhone}', maxLines: 1, style: const TextStyle(fontSize: 13, color: LightGlassColors.textSecondary)),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildDurationBadge() {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: LightGlassColors.lightBlue,
        shape: BoxShape.circle,
        border: Border.all(color: LightGlassColors.glassBorderSubtle, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            AppIcons.schedule_rounded,
            size: 16,
            color: LightGlassColors.primaryBlue,
          ),
          const SizedBox(height: 3),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Давомнокӣ:',
              style: TextStyle(
                fontSize: 9,
                color: LightGlassColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.ride.durationLabel,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: LightGlassColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectButton() {
    return Listener(
      onPointerDown: (_) => setState(() => _selectPressed = true),
      onPointerUp: (_) => setState(() => _selectPressed = false),
      onPointerCancel: (_) => setState(() => _selectPressed = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _selectPressed ? 0.92 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: LightGlassColors.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: LightGlassColors.primaryBlue.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSlide(
                  offset: _selectPressed ? const Offset(0.05, 0) : Offset.zero,
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  child: const Icon(AppIcons.arrow_forward_rounded, size: 26, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'ИНТИХОБ КАРДАН',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: LightGlassColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}
