import 'package:intertaxi/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';
import 'create_order_screen.dart';
import 'profile_screen.dart';
import 'route_screen.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/animated_tab_body.dart';

/// InterTaxi Driver Home Screen
/// Professional taxi driver interface with modern design
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
  bool _profileTabMounted = false;
  final int _notificationCount = 3;

  // Mock ride requests
  final List<RideRequest> _rideRequests = [
    RideRequest(
      pickupLocation: 'Кӯлоб, Маркази шаҳр',
      destination: 'Душанбе, Фурудгоҳ',
      distance: '2.5 км',
      estimatedPrice: '45 сомонӣ',
      estimatedTime: '15 дақиқа',
    ),
    RideRequest(
      pickupLocation: 'Восеъ, Бозор',
      destination: 'Хуҷанд, Маркази шаҳр',
      distance: '5.8 км',
      estimatedPrice: '85 сомонӣ',
      estimatedTime: '25 дақиқа',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            _buildHeader(),

            // Main Content
            Expanded(
              child: AnimatedTabBody(
                index: _currentIndex,
                duration: const Duration(milliseconds: 200),
                children: [
                  _buildHomeTab(),
                  _buildRouteTab(),
                  _buildMessagesTab(),
                  _profileTabMounted
                      ? _buildProfileTab()
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            const SizedBox(height: 100),

            // Bottom Navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0052CC), Color(0xFF3385FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(AppIcons.person, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 12),

          // Driver Info
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
                      color: Color(0xFFFFD166),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isOnline ? 'Онлайн' : 'Офлайн',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Notifications
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  AppIcons.notifications_rounded,
                  size: 24,
                  color: Colors.black87,
                ),
              ),
              if (_notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
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
        // Online/Offline Toggle
        _buildOnlineToggle(),

        // Map Area
        Expanded(child: _buildMapArea()),

        // Ride Requests
        if (_isOnline && _rideRequests.isNotEmpty) _buildRideRequests(),
      ],
    );
  }

  Widget _buildCreateOrderTab() {
    return CreateOrderScreen(
      driverName: widget.driverName,
      driverPhone: widget.driverPhone,
    );
  }

  Widget _buildRouteTab() {
    return _buildCreateOrderTab();
  }

  Widget _buildMessagesTab() {
    return const MessagesTab();
  }

  Widget _buildProfileTab() {
    return ProfileScreen(
      initialName: widget.driverName,
      initialPhone: widget.driverPhone,
    );
  }

  Widget _buildOnlineToggle() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isOnline
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isOnline ? AppIcons.check_circle_rounded : AppIcons.cancel_rounded,
              color: _isOnline ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? 'Шумо онлайн ҳастед' : 'Шумо офлайн ҳастед',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isOnline
                      ? 'Мусофирон метавонанд заказ диҳанд'
                      : 'Заказҳо қабул карда намешаванд',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Toggle Switch
          Switch(
            value: _isOnline,
            onChanged: (value) {
              setState(() {
                _isOnline = value;
              });
            },
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.green,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const RouteScreen(fromCity: 'Душанбе', toCity: 'Кӯлоб'),
    );
  }

  Widget _buildRideRequests() {
    return Container(
      height: 310,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(
                  AppIcons.notifications_active_rounded,
                  size: 20,
                  color: Color(0xFF0066FF),
                ),
                const SizedBox(width: 8),
                Text(
                  'Эълони нав',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_rideRequests.length} нав',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const SizedBox(height: 12),
          SizedBox(
            height: 250,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pickup & Destination
            Row(
              children: [
                // Route Line
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(width: 2, height: 40, color: Colors.grey[300]),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Locations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.pickupLocation,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        request.destination,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Trip Details
            Row(
              children: [
                _buildTripDetail(
                  icon: AppIcons.straighten_rounded,
                  label: 'Масофа',
                  value: request.distance,
                ),
                const SizedBox(width: 16),
                _buildTripDetail(
                  icon: AppIcons.access_time_rounded,
                  label: 'Вақт',
                  value: request.estimatedTime,
                ),
                const SizedBox(width: 16),
                _buildTripDetail(
                  icon: AppIcons.attach_money_rounded,
                  label: 'Нарх',
                  value: request.estimatedPrice,
                  isHighlighted: true,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _deleteRideRequest(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Нест кардан',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRide(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Қабул кардан',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
            size: 18,
            color: isHighlighted ? const Color(0xFF0066FF) : Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? const Color(0xFF0066FF) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return AppBottomNav(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() {
        _currentIndex = index;
        if (index == 3) _profileTabMounted = true;
      }),
      items: const [
        AppNavItem(icon: LucideIcons.house, label: 'Асосӣ'),
        AppNavItem(icon: LucideIcons.route, label: 'Масир'),
        AppNavItem(icon: LucideIcons.messageCircle, label: 'Паёмҳо'),
        AppNavItem(icon: LucideIcons.userRound, label: 'Профил'),
      ],
    );
  }

  void _acceptRide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.check_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Заказ қабул шуд!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ба мувофиқаи маълумот раванд',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF0066FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteRideRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Заказ нест карда шуд'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Ride Request Model
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

// Placeholder tabs for bottom navigation
class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.list_alt_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Заказҳои ман',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class EarningsTab extends StatelessWidget {
  const EarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.attach_money_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Даромадҳо',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.message_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Сообщения',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.person_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Профил',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
