import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:intertaxi/app_icons.dart';
import 'package:flutter/material.dart';

import '../constants/light_glass_theme.dart';
import '../models/driver_ride_model.dart';
import 'glass_widgets.dart' show GlassButton;
import 'light_glass_widgets.dart';

/// Premium glassmorphism trip card for passenger search results.
/// White & blue theme with frosted glass containers, clear white text & sky-blue accents.
class DriverRideCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final from = ride.route.isNotEmpty ? ride.route.first : searchFrom;
    final to = ride.route.length > 1 ? ride.route.last : searchTo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LightGlassCard(
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRouteRow(from, to),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildDriverRow()),
                const SizedBox(width: 10),
                _buildDurationBadge(),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(),
            const SizedBox(height: 12),
            _buildActionRow(),
          ],
        ),
      ),
    );
  }

  /// Driver avatar + name + phone number.
  Widget _buildDriverRow() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: LightGlassColors.lightBlue,
            shape: BoxShape.circle,
            border: Border.all(
              color: LightGlassColors.glassBorderSubtle,
              width: 1.2,
            ),
          ),
          child: const Icon(
            AppIcons.person_rounded,
            size: 24,
            color: LightGlassColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ride.driverName.isEmpty ? 'Ронанда' : ride.driverName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: LightGlassColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    AppIcons.phone_rounded,
                    size: 13,
                    color: LightGlassColors.primaryBlue,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      ride.driverPhone.isEmpty ? 'вЂ”' : ride.driverPhone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: LightGlassColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Route row: Origin в†’ Destination.
  Widget _buildRouteRow(String from, String to) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _routeDot(LightGlassColors.success),
            Container(width: 2, height: 24, color: LightGlassColors.divider),
            _routeDot(LightGlassColors.danger),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                from,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: LightGlassColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                to,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: LightGlassColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
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
            color: color.withValues(alpha: 0.40),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildDurationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: LightGlassColors.lightBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LightGlassColors.glassBorderSubtle, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            AppIcons.schedule_rounded,
            size: 18,
            color: LightGlassColors.primaryBlue,
          ),
          const SizedBox(height: 2),
          Text(
            ride.durationLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: LightGlassColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Expanded(
          child: _infoChip(
            AppIcons.sell_outlined,
            '${ride.fullRoutePrice} СЃРѕРјРѕРЅУЈ',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _infoChip(
            AppIcons.people_outline_rounded,
            '${ride.availableSeats} ҷой озод',
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: LightGlassColors.surfaceTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LightGlassColors.glassBorderSubtle, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: LightGlassColors.primaryBlue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: LightGlassColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        const Icon(
          AppIcons.schedule_rounded,
          size: 16,
          color: LightGlassColors.primaryBlue,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            ride.departureLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: LightGlassColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 38,
          child: GlassButton(
            text: AppLocalizations.translate('Интихоб кардан'),
            onPressed: onTap ?? () {},
            height: 38,
            fontSize: 12,
            icon: AppIcons.arrow_forward_rounded,
          ),
        ),
      ],
    );
  }
}
