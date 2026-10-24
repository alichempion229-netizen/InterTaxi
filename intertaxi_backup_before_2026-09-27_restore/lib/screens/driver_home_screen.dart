import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:intertaxi/app_icons.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../constants/glass_theme.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/animated_bottom_navigation.dart';
import 'profile_screen.dart';

/// InterTaxi Driver Home Screen (Glassmorphism White & Blue Theme)
class DriverHomeScreen extends StatefulWidget {
  final String driverName;
  final String driverPhone;

  const DriverHomeScreen({
    super.key,
    required this.driverName,
    required this.driverPhone,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = true;
  int _currentIndex = 0;
  final double _balance = 1250.50;
  final int _notificationCount = 3;

  final List<RideRequest> _rideRequests = [
    RideRequest(
      pickupLocation: 'Кӯлоб, Маркази шаҳр',
      destination: 'Душанбе, Фурудгоҳ',
      distance: '2.5 РєРј',
      estimatedPrice: '45 СЃРѕРјРѕРЅУЈ',
      estimatedTime: '15 дақиқа',
    ),
    RideRequest(
      pickupLocation: 'Восеъ, Бозор',
      destination: 'Хуҷанд, Маркази шаҳр',
      distance: '5.8 РєРј',
      estimatedPrice: '85 СЃРѕРјРѕРЅУЈ',
      estimatedTime: '25 дақиқа',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: AnimatedTabStack(
                  index: _currentIndex,
                  children: [
                    _buildHomeTab(),
                    const OrdersTab(),
                    const MessagesTab(),
                    ProfileScreen(
                      initialName: widget.driverName,
                      initialPhone: widget.driverPhone,
                    ),
                  ],
                ),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GlassColors.accentSky.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: const Icon(
              AppIcons.person_rounded,
              size: 26,
              color: GlassColors.accentSky,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.driverName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      AppIcons.star_rounded,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isOnline ? GlassColors.success : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isOnline ? 'Онлайн' : 'Офлайн',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isOnline ? GlassColors.success : Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GlassChip(
            label: AppLocalizations.translate(
              '${_balance.toStringAsFixed(0)} СЃРѕРј',
            ),
            accent: GlassColors.accentSky,
            icon: AppIcons.account_balance_wallet_rounded,
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              GlassIconButton(
                icon: AppIcons.notifications_rounded,
                onPressed: () {},
                size: 40,
                iconSize: 22,
              ),
              if (_notificationCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: GlassColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        _buildOnlineToggle(),
        Expanded(child: _buildMapArea()),
        if (_isOnline && _rideRequests.isNotEmpty) _buildRideRequests(),
      ],
    );
  }

  Widget _buildOnlineToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        radius: 18,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _isOnline
                    ? GlassColors.success.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isOnline
                    ? AppIcons.check_circle_rounded
                    : AppIcons.cancel_rounded,
                color: _isOnline ? GlassColors.success : Colors.white54,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOnline
                        ? 'Шумо онлайн ҳастед'
                        : 'Шумо офлайн ҳастед',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isOnline
                        ? 'Мусофирон метавонанд заказ диҳанд'
                        : 'Заказҳо қабул карда намешаванд',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isOnline,
              onChanged: (value) => setState(() => _isOnline = value),
              activeThumbColor: Colors.white,
              activeTrackColor: GlassColors.accentSky,
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: glassDecoration(
        radius: 20,
        fillOpacity: 0.10,
        borderOpacity: 0.25,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.map_rounded,
                      size: 72,
                      color: Colors.white.withValues(alpha: 0.40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.translate('Харита'),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: GlassIconButton(
                  icon: AppIcons.my_location_rounded,
                  iconColor: GlassColors.accentSky,
                  onPressed: () {},
                  size: 40,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRideRequests() {
    return Container(
      height: 290,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                AppIcons.notifications_active_rounded,
                size: 20,
                color: GlassColors.accentSky,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.translate('Заказҳои нав'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              GlassChip(
                label: AppLocalizations.translate(
                  '${_rideRequests.length} нав',
                ),
                accent: GlassColors.accentSky,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _rideRequests.length,
              itemBuilder: (context, index) {
                return _buildRideRequestCard(_rideRequests[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideRequestCard(RideRequest request) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: GlassColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: GlassColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.pickupLocation,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        request.destination,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.18), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTripDetail(
                  icon: AppIcons.straighten_rounded,
                  label: AppLocalizations.translate('Масофа'),
                  value: request.distance,
                ),
                const SizedBox(width: 12),
                _buildTripDetail(
                  icon: AppIcons.access_time_rounded,
                  label: AppLocalizations.translate('Вақт'),
                  value: request.estimatedTime,
                ),
                const SizedBox(width: 12),
                _buildTripDetail(
                  icon: AppIcons.attach_money_rounded,
                  label: AppLocalizations.translate('Нарх'),
                  value: request.estimatedPrice,
                  isHighlighted: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => _deleteRideRequest(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GlassColors.danger,
                        side: BorderSide(
                          color: GlassColors.danger.withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.translate('Нест кардан'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassButton(
                    text: AppLocalizations.translate('Қабул кардан'),
                    onPressed: () => _acceptRide(),
                    height: 40,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetail({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: isHighlighted
                ? GlassColors.accentSky
                : Colors.white.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? GlassColors.accentSky : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return AnimatedBottomNavigation(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedColor: Colors.white,
      unselectedColor: Colors.white70,
      items: [
        AnimatedNavigationItem(
          icon: AppIcons.home_rounded,
          label: '\u0410\u0441\u043e\u0441\u04e3',
        ),
        AnimatedNavigationItem(
          icon: AppIcons.route_rounded,
          label: '\u041c\u0430\u0441\u0438\u0440',
        ),
        AnimatedNavigationItem(
          icon: AppIcons.orders,
          label: '\u0424\u0430\u0440\u043c\u043e\u0438\u0448\u04b3\u043e',
        ),
        AnimatedNavigationItem(
          icon: AppIcons.person_rounded,
          label: '\u041f\u0440\u043e\u0444\u0438\u043b',
        ),
      ],
    );
  }

  void _acceptRide() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          radius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: GlassColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.check_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.translate('Заказ қабул шуд!'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.translate(
                  'Ба мувофиқаи маълумот раванд',
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 20),
              GlassButton(
                text: AppLocalizations.translate('РћРљ'),
                onPressed: () => Navigator.pop(context),
                height: 44,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteRideRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.translate('Заказ нест карда шуд'),
        ),
        backgroundColor: GlassColors.danger,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class RideRequest {
  final String pickupLocation;
  final String destination;
  final String distance;
  final String estimatedPrice;
  final String estimatedTime;

  RideRequest({
    required this.pickupLocation,
    required this.destination,
    required this.distance,
    required this.estimatedPrice,
    required this.estimatedTime,
  });
}

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                AppIcons.route_rounded,
                size: 56,
                color: GlassColors.accentSky,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.translate('Масирҳои ронанда'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.translate(
                  'Дар ин ҷо масирҳои эълоншудаи шумо намоиш дода мешаванд.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                AppIcons.message_rounded,
                size: 56,
                color: GlassColors.accentSky,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.translate('Паёмҳои ронанда'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.translate(
                  'Дар ин ҷо паёмҳои мусофирон ва бронҳо намоиш дода мешаванд.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
