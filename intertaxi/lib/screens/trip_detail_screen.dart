import 'dart:io';

import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:intertaxi/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../models/car_brand.dart';
import '../models/car_color.dart';
import '../services/api_service.dart';
import '../utils/app_route.dart';
import '../data/tajik_location_coordinates.dart';

/// InterTaxi Trip Detail Screen (РџРѕРґСЂРѕР±РЅРѕ).
///
/// Shows the FULL information about a single trip: from/to locations,
/// available seats, price, departure time and driver details (name, phone).
/// Opened from the compact trip card in the passenger list.
class TripDetailScreen extends StatefulWidget {
  /// Raw trip map exactly as delivered by the backend / socket events.
  final Map<String, dynamic> trip;

  final String passengerName;
  final String passengerPhone;

  const TripDetailScreen({
    super.key,
    required this.trip,
    this.passengerName = '',
    this.passengerPhone = '',
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class BookingSentScreen extends StatelessWidget {
  final int requestedSeats;
  final String from;
  final String to;

  const BookingSentScreen({
    super.key,
    required this.requestedSeats,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(
          AppLocalizations.translate('Брон фиристода шуд'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.notifications_active_rounded,
                    size: 42,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.translate(
                    'Дархости шумо фиристода шуд',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.translate(
                    '$requestedSeats ҷой • $from → $to',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.translate(
                    'Лутфан мунтазир монед. Ронанда ба дархости шумо ҷавоб медиҳад.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    child: Text(
                      AppLocalizations.translate(
                        'Ба саҳифаи асосӣ',
                      ),
                    ),
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

class _TripDetailScreenState extends State<TripDetailScreen> {
  bool _booking = false;
  int _requestedSeats = 1;
  List<String> _localCarPhotoPaths = const <String>[];
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _loadLocalCarPhotos();
  }

  Future<void> _loadLocalCarPhotos() async {
    final driverPhone = _driverPhone.replaceAll(RegExp(r'\D'), '');
    if (driverPhone.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPhone = (prefs.getString('user_phone') ?? '')
          .replaceAll(RegExp(r'\D'), '');
      if (userPhone != driverPhone) return;
      final paths = <String>['', '', ''];
      final avatarPath = prefs.getString('user_avatar_path') ?? '';
      for (var index = 0; index < paths.length; index++) {
        final path = prefs.getString('driver_car_photo_${index + 1}') ?? '';
        if (path.isNotEmpty && await File(path).exists()) paths[index] = path;
      }
      if (mounted) {
        setState(() {
          _localCarPhotoPaths = paths;
          _localAvatarPath = avatarPath.isNotEmpty && File(avatarPath).existsSync()
              ? avatarPath
              : null;
        });
      }
    } catch (_) {
      // Local photos are optional; remote trip details remain usable.
    }
  }

  // --- Field accessors with safe fallbacks ---------------------------------

  String get _id => widget.trip['id']?.toString() ?? '';
  String get _from => widget.trip['from_location']?.toString() ?? '-';
  String get _to => widget.trip['to_location']?.toString() ?? '-';
  String get _price => widget.trip['price']?.toString() ?? '0';
  String get _seats => widget.trip['available_seats']?.toString() ?? '0';
  String get _departure {
    final raw = widget.trip['departure_time']?.toString() ?? '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$hour:$minute $day.$month.${parsed.year}';
  }

  int get _durationMinutes =>
      int.tryParse(widget.trip['duration_minutes']?.toString() ?? '') ?? 0;
  String get _carBrand =>
      widget.trip['car_brand']?.toString().trim() ??
      widget.trip['carBrand']?.toString().trim() ??
      '';
  String get _carModel {
    for (final key in ['car_model', 'model', 'driver_car_model']) {
      final value = widget.trip[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }
  String get _carColor {
    for (final key in ['car_color', 'carColor', 'color']) {
      final value = widget.trip[key]?.toString().trim() ?? '';
      if (value.isEmpty ||
          value == '-' ||
          value == '\u2014' ||
          value == 'вЂ”' ||
          value.contains('вЂ') ||
          value.contains('â€”')) {
        continue;
      }
      return value;
    }
    return '';
  }
  String get _carPlate => widget.trip['car_plate']?.toString() ?? '';
  String get _driverName => widget.trip['driver_name']?.toString() ?? '';
  String get _driverPhone => widget.trip['driver_phone']?.toString() ?? '';
  String get _driverAvatarUrl => widget.trip['driver_avatar_url']?.toString() ?? '';
  List<String> get _carPhotoUrls {
    final rawPhotos = widget.trip['car_photos'];
    final photos = rawPhotos is List
        ? rawPhotos.map((photo) => photo?.toString().trim() ?? '').take(3).toList()
        : <String>[];
    const photoKeys = [
      'car_photo_front',
      'car_photo_rear',
      'car_photo_side',
    ];
    return List<String>.generate(3, (index) {
      if (index < photos.length && photos[index].isNotEmpty) {
        return ApiService.resolvePhotoUrl(photos[index]);
      }
      return ApiService.resolvePhotoUrl(
        widget.trip[photoKeys[index]]?.toString().trim() ?? '',
      );
    });
  }
  List<String> get _carPhotoThumbUrls {
    final rawPhotos = widget.trip['car_photo_thumbs'];
    final photos = rawPhotos is List
        ? rawPhotos.map((photo) => photo?.toString().trim() ?? '').take(3).toList()
        : <String>[];
    const photoKeys = [
      'car_thumb_front',
      'car_thumb_rear',
      'car_thumb_side',
    ];
    return List<String>.generate(3, (index) {
      if (index < photos.length && photos[index].isNotEmpty) {
        return ApiService.resolvePhotoUrl(photos[index]);
      }
      return ApiService.resolvePhotoUrl(
        widget.trip[photoKeys[index]]?.toString().trim() ?? '',
      );
    });
  }
  bool get _hasCarPhotos =>
      _carPhotoUrls.any((url) => url.isNotEmpty) ||
      _localCarPhotoPaths.any((path) => path.isNotEmpty);
  bool get _isActive => widget.trip['status']?.toString() == 'active';
  int get _seatsInt => int.tryParse(_seats) ?? 0;
  bool get _bookable => _isActive && _seatsInt > 0;

  String get _vehicleName {
    final brand = _carBrand.trim();
    final model = _carModel.trim();
    if (brand.isEmpty || brand == '-' || brand == '\u2014' || brand.contains('\u0432\u0402')) {
      return model;
    }
    return model.isEmpty || model == '-' || model == '\u2014' || model.contains('\u0432\u0402')
        ? brand
        : '$brand $model';
  }
  String? get _vehicleLogoAsset {
    return carBrandLogoAsset(_carBrand);
  }

  String get _formattedPlate {
    final compact = _carPlate.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final match = RegExp(r'^(\d{4})((?:[A-Z]|[\u0400-\u04FF]){1,3})(\d{2})$').firstMatch(compact);
    if (match != null) {
      return '${match.group(1)} ${match.group(2)} ${match.group(3)}';
    }
    return _carPlate.trim().isEmpty
        ? '-'
        : _carPlate.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  }
  bool get _hasValidCarColor {
    final value = _carColor.trim();
    return value.isNotEmpty &&
        value != '\u2014' &&
        value != '-' &&
        !value.contains('\u0432\u0402') &&
        !value.contains('\u00e2\u20ac');
  }

  bool get _hasKnownCarColor {
    if (!_hasValidCarColor) return false;
    const knownNames = [
      '\u0421\u0430\u0444\u0435\u0434',
      '\u0421\u0438\u0451\u04b3',
      '\u041d\u0443\u049b\u0440\u0430\u0433\u04e3',
      '\u041c\u0435\u0442\u0430\u043b\u043b\u0438\u043a',
      '\u041a\u0430\u0431\u0443\u0434',
      '\u0417\u0430\u0440\u0434',
      '\u0421\u0430\u0431\u0437',
      '\u0421\u0443\u0440\u0445',
    ];
    return knownNames.any(
          (name) => name.toLowerCase() == _normalizedCarColor.toLowerCase(),
        ) ||
        carColorSwatch(_carColor, fallback: Colors.transparent) !=
            Colors.transparent;
  }

  String get _normalizedCarColor {
    switch (_carColor.trim()) {
      case '\u{421}\u{430}\u{444}\u{435}\u{434}':
        return '\u{421}\u{430}\u{444}\u{435}\u{434}';
      case '\u{421}\u{438}\u{451}\u{4b3}':
        return '\u{421}\u{438}\u{451}\u{4b3}';
      case '\u{41d}\u{443}\u{49b}\u{440}\u{430}\u{433}\u{4e3}':
        return '\u{41d}\u{443}\u{49b}\u{440}\u{430}\u{433}\u{4e3}';
      case '\u{41c}\u{435}\u{442}\u{430}\u{43b}\u{43b}\u{438}\u{43a}':
        return '\u{41c}\u{435}\u{442}\u{430}\u{43b}\u{43b}\u{438}\u{43a}';
      case '\u{41a}\u{430}\u{431}\u{443}\u{434}':
        return '\u{41a}\u{430}\u{431}\u{443}\u{434}';
      case '\u{417}\u{430}\u{440}\u{434}':
        return '\u{417}\u{430}\u{440}\u{434}';
      case '\u{421}\u{430}\u{431}\u{437}':
        return '\u{421}\u{430}\u{431}\u{437}';
      case '\u{421}\u{443}\u{440}\u{445}':
        return '\u{421}\u{443}\u{440}\u{445}';
      default:
        return _carColor.trim();
    }
  }

  String get _carColorDisplay {
    if (!_hasKnownCarColor) {
      return '\u041d\u0438\u0448\u043e\u043d \u0434\u043e\u0434\u0430 \u043d\u0430\u0448\u0443\u0434\u0430\u0430ст';
    }
    switch (_normalizedCarColor) {
      case '\u0421\u0430\u0444\u0435\u0434':
        return '\u0421\u0430\u0444\u0435\u0434';
      case '\u0421\u0438\u0451\u04b3':
        return '\u0421\u0438\u0451\u04b3';
      case '\u041d\u0443\u049b\u0440\u0430\u0433\u04e3':
        return '\u041d\u0443\u049b\u0440\u0430\u0433\u04e3';
      case '\u041c\u0435\u0442\u0430\u043b\u043b\u0438\u043a':
        return '\u041c\u0435\u0442\u0430\u043b\u043b\u0438\u043a';
      case '\u041a\u0430\u0431\u0443\u0434':
        return '\u041a\u0430\u0431\u0443\u0434';
      case '\u0417\u0430\u0440\u0434':
        return '\u0417\u0430\u0440\u0434';
      case '\u0421\u0430\u0431\u0437':
        return '\u0421\u0430\u0431\u0437';
      case '\u0421\u0443\u0440\u0445':
        return '\u0421\u0443\u0440\u0445';
    }
    if (_normalizedCarColor.toLowerCase() == '\u043c\u0435\u0442\u0430\u043b\u043b\u0438\u043a') {
      return '\u041c\u0435\u0442\u0430\u043b\u043b\u0438\u043a';
    }
    final mapped = carColorSwatch(_carColor, fallback: Colors.transparent).value;
    if (mapped == const Color(0xFFE8EDF5).value) return '\u0421\u0430\u0444\u0435\u0434';
    if (mapped == const Color(0xFF252A34).value) return '\u0421\u0438\u0451\u04b3';
    if (mapped == const Color(0xFFB8C0CC).value) return '\u041d\u0443\u049b\u0440\u0430\u0433\u04e3';
    if (mapped == const Color(0xFF1769E0).value) return '\u041a\u0430\u0431\u0443\u0434';
    if (mapped == const Color(0xFFE53935).value) return '\u0421\u0443\u0440\u0445';
    if (mapped == const Color(0xFF35A66F).value) return '\u0421\u0430\u0431\u0437';
    if (mapped == const Color(0xFFFFC107).value) return '\u0417\u0430\u0440\u0434';
    return _normalizedCarColor;
  }

  Color get _carColorSwatch {
    if (_normalizedCarColor.toLowerCase() == '\u043c\u0435\u0442\u0430\u043b\u043b\u0438\u043a') {
      return const Color(0xFF5A5F66);
    }
    switch (_normalizedCarColor) {
      case '\u0421\u0430\u0444\u0435\u0434':
        return const Color(0xFFF5F5F5);
      case '\u0421\u0438\u0451\u04b3':
        return const Color(0xFF141414);
      case '\u041d\u0443\u049b\u0440\u0430\u0433\u04e3':
        return const Color(0xFFC0C4C8);
      case '\u041c\u0435\u0442\u0430\u043b\u043b\u0438\u043a':
        return const Color(0xFF5A5F66);
      case '\u041a\u0430\u0431\u0443\u0434':
        return const Color(0xFF1E5AC8);
      case '\u0417\u0430\u0440\u0434':
        return const Color(0xFFF5C814);
      case '\u0421\u0430\u0431\u0437':
        return const Color(0xFF1E9646);
      case '\u0421\u0443\u0440\u0445':
        return const Color(0xFFC81E1E);
      default:
        final mapped = carColorSwatch(_carColor, fallback: Colors.transparent).value;
        if (mapped == const Color(0xFFE8EDF5).value) return const Color(0xFFF5F5F5);
        if (mapped == const Color(0xFF252A34).value) return const Color(0xFF141414);
        if (mapped == const Color(0xFFB8C0CC).value) return const Color(0xFFC0C4C8);
        if (mapped == const Color(0xFF1769E0).value) return const Color(0xFF1E5AC8);
        if (mapped == const Color(0xFFE53935).value) return const Color(0xFFC81E1E);
        if (mapped == const Color(0xFF35A66F).value) return const Color(0xFF1E9646);
        if (mapped == const Color(0xFFFFC107).value) return const Color(0xFFF5C814);
        return Colors.grey;
    }
  }
  // --- Actions --------------------------------------------------------------

  Future<void> _bookTrip() async {
    if (_booking || _id.isEmpty || !_bookable) return;
    setState(() => _booking = true);
    final result = await ApiService.createBooking(
      tripId: _id,
      passengerName: widget.passengerName,
      passengerPhone: widget.passengerPhone,
      requestedSeats: _requestedSeats,
    );
    if (!mounted) return;
    setState(() => _booking = false);
    if (result['ok'] == true) {
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      AppRoute.replace<void, void>(context, BookingSentScreen(
            requestedSeats: _requestedSeats,
            from: _from,
            to: _to,
          ));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['error']?.toString() ??
              AppLocalizations.translate(
                'Брон кардан иҷро нашуд',
              ),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(AppLocalizations.translate('Подробно')),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          52 + MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRouteCard(),
            const SizedBox(height: 12),
            _buildInfoCard(),
            const SizedBox(height: 12),
            _buildSeatSelector(),
            if (_hasVehicleDetails) ...[
              const SizedBox(height: 12),
              _buildVehicleCard(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _bookable ? _bookTrip : null,
              icon: _booking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(AppIcons.event_seat_rounded),
              label: Text(
                _bookable
                    ? 'Брон кардан'
                    : 'Ҷой дастрас нест',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.gray300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatSelector() {
    final maxSeats = _seatsInt > 0 ? _seatsInt : 1;
    final canDecrease = !_booking && _requestedSeats > 1;
    final canIncrease = !_booking && _requestedSeats < maxSeats;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(AppIcons.event_seat_rounded, color: AppColors.primaryBlue, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '\u0427\u0430\u043d\u0434 \u04b7\u043e\u0439 \u0431\u0440\u043e\u043d \u043c\u0435\u043a\u0443\u043d\u0435\u0434?',
                    maxLines: 1,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '\u04b2\u0430\u043c\u0430\u0433\u04e3: $_requestedSeats \u04b7\u043e\u0439 \u0430\u0437 $_seats \u043e\u0437\u043e\u0434',
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _seatStepButton(
                label: '\u2212',
                enabled: canDecrease,
                onPressed: canDecrease
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _requestedSeats--);
                      }
                    : null,
              ),
              SizedBox(
                width: 34,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Text(
                      '$_requestedSeats',
                      key: ValueKey<int>(_requestedSeats),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ),
              _seatStepButton(
                label: '+',
                enabled: canIncrease,
                onPressed: canIncrease
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _requestedSeats++);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seatStepButton({
    required String label,
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    final color = enabled ? AppColors.primaryBlue : AppColors.gray300;
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w500,
                color: enabled ? Colors.white : AppColors.gray600,
              ),
            ),
          ),
        ),
      ),
    );
  }
  /// Big flat card with the full from -> to route and the price.
  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0052CC), Color(0xFF1683FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.gray300.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isActive ? 'ДАСТРАС' : 'Р‘РђРЎРўРђ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: _isActive ? Colors.greenAccent : AppColors.gray600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$_price сомонӣ',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDriverProfile(),
          const SizedBox(height: 18),
          _routeRow(
            icon: AppIcons.trip_origin_rounded,
            iconColor: Colors.greenAccent,
            text: _from,
          ),
          Container(
            margin: const EdgeInsets.only(left: 10),
            width: 2,
            height: 22,
            color: Colors.white54,
          ),
          _routeRow(
            icon: AppIcons.location_on_rounded,
            iconColor: Colors.redAccent,
            text: _to,
          ),
          if (locationCoordinatesFor(_from) == null ||
              locationCoordinatesFor(_to) == null)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Координатаи ин макон ҳанӯз илова нашудааст',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverProfile() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54),
          ),
          child: _driverAvatarUrl.isEmpty
              ? const Icon(AppIcons.person_rounded, size: 24, color: Colors.white)
              : ClipOval(
                  child: Image.network(
                    ApiService.resolvePhotoUrl(_driverAvatarUrl),
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _localAvatarPath == null
                        ? const Icon(AppIcons.person_rounded, size: 24, color: Colors.white)
                        : Image.file(File(_localAvatarPath!), width: 42, height: 42, fit: BoxFit.cover),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _driverName.isEmpty ? 'Ронанда' : _driverName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _driverPhone.isEmpty ? 'Рақам нест' : _driverPhone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Icon(AppIcons.verified_rounded, color: Colors.white70, size: 20),
      ],
    );
  }

  Widget _routeRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// Flat info card with the key trip details arranged for quick scanning.
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _flatDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  icon: AppIcons.event_seat_rounded,
                  label: AppLocalizations.translate('Ҷойҳои холӣ'),
                  value: _seats,
                  suffix: 'ҷой',
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryTile(
                  icon: AppIcons.timelapse_rounded,
                  label: AppLocalizations.translate('Давомнокӣ'),
                  value: _buildDurationLabel(),
                  color: const Color(0xFFE18332),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _summaryTile(
            icon: AppIcons.schedule_rounded,
            label: AppLocalizations.translate('Вақти сафар'),
            value: _departure.isEmpty ? '-' : _departure,
            color: const Color(0xFF7A55D8),
            fullValue: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? suffix,
    bool fullValue = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          // The detail screen sits inside a SingleChildScrollView, so this
          // Column has unbounded height. A flex child (Spacer) throws a
          // RenderFlex exception there and leaves the route looking blank.
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: fullValue ? 2 : 1,
                  overflow: fullValue
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fullValue ? 14 : 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 3),
                Text(
                  suffix,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _buildDurationLabel() {
    if (_durationMinutes <= 0) return '-';
    final hours = _durationMinutes ~/ 60;
    final minutes = _durationMinutes % 60;
    if (hours == 0) return '$minutes дақ.';
    if (minutes == 0) return '$hours с.';
    return '$hours с. $minutes дақ.';
  }
  bool get _hasVehicleDetails =>
      _carBrand.isNotEmpty ||
      _carModel.isNotEmpty ||
      _carColor.isNotEmpty ||
      _carPlate.isNotEmpty ||
      _hasCarPhotos;

  /// Vehicle details displayed as compact premium badges.
  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _flatDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              '\u041c\u0430\u044a\u043b\u0443\u043c\u043e\u0442\u0438 \u043c\u043e\u0448\u0438\u043d',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ),
          Row(
            children: [
              Expanded(child: _buildBrandTile()),
              const SizedBox(width: 8),
              Expanded(child: _buildColorBadge()),
            ],
          ),
          const SizedBox(height: 8),
          _buildPlateTile(),
          if (_hasCarPhotos) ...[
            const SizedBox(height: 8),
            _buildCarPhotosButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildCarPhotosButton() {
    return Material(
      color: AppColors.primaryBlue.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _showCarPhotos,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 22,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Аксҳои мошин',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.primaryBlue.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCarPhotos() async {
    if (!_hasCarPhotos) return;
    final pageController = PageController();
    const captions = ['Пеш', 'Қафо', 'Паҳлу'];
    var currentPage = 0;
    final photoUrls = _carPhotoUrls;
    final thumbnailUrls = _carPhotoThumbUrls;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.48,
        maxChildSize: 0.95,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setViewerState) => Container(
            decoration: const BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Аксҳои мошин',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.52,
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: captions.length,
                    onPageChanged: (index) =>
                        setViewerState(() => currentPage = index),
                    itemBuilder: (context, index) => InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: _buildCarPhotoImage(
                        index,
                        photoUrls,
                        thumbnailUrls,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: List<Widget>.generate(captions.length, (index) {
                    final selected = currentPage == index;
                    return ChoiceChip(
                      label: Text(captions[index]),
                      selected: selected,
                      onSelected: (_) {
                        setViewerState(() => currentPage = index);
                        pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      },
                      selectedColor:
                          AppColors.primaryBlue.withValues(alpha: 0.16),
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primaryBlue
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: AppColors.primaryBlue.withValues(alpha: 0.14),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    pageController.dispose();
  }

  Widget _buildCarPhotoImage(
    int index,
    List<String> photoUrls,
    List<String> thumbnailUrls,
  ) {
    final url = photoUrls[index];
    final localPath = index < _localCarPhotoPaths.length
        ? _localCarPhotoPaths[index]
        : '';
    final uri = Uri.tryParse(url);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority) {
      final thumbnailUrl = thumbnailUrls[index];
      final thumbnailUri = Uri.tryParse(thumbnailUrl);
      return Image.network(
        url,
        fit: BoxFit.contain,
        cacheWidth: 1280,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnailUri != null &&
                  (thumbnailUri.scheme == 'http' ||
                      thumbnailUri.scheme == 'https') &&
                  thumbnailUri.hasAuthority)
                Image.network(
                  thumbnailUrl,
                  fit: BoxFit.contain,
                  cacheWidth: 360,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              const Center(child: CircularProgressIndicator()),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) => localPath.isNotEmpty
            ? _buildLocalCarPhoto(localPath)
            : _carPhotoErrorPlaceholder(),
      );
    }
    if (localPath.isNotEmpty) return _buildLocalCarPhoto(localPath);
    return _carPhotoErrorPlaceholder();
  }

  Widget _buildLocalCarPhoto(String path) {
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          _carPhotoErrorPlaceholder(),
    );
  }

  Widget _carPhotoErrorPlaceholder() {
    return Container(
      color: AppColors.offWhite,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 42, color: AppColors.gray600),
          SizedBox(height: 8),
          Text(
            'Акс дастрас нест',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandTile() {
    final logoAsset = _vehicleLogoAsset;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 30,
            child: logoAsset == null
                ? const Icon(AppIcons.directions_car_rounded, size: 24, color: AppColors.primaryBlue)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: logoAsset.endsWith('.svg')
                        ? SvgPicture.asset(
                            logoAsset,
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(AppIcons.directions_car_rounded, size: 24, color: AppColors.primaryBlue),
                          )
                        : Image.asset(
                            logoAsset,
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                            cacheWidth: 60,
                            cacheHeight: 60,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(AppIcons.directions_car_rounded, size: 24, color: AppColors.primaryBlue),
                          ),
                  ),
          ),
          const SizedBox(height: 5),
          const Text(
            '\u041c\u043e\u0448\u0438\u043d',
            maxLines: 1,
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _vehicleName.isEmpty ? '-' : _vehicleName,
              maxLines: 1,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBadge() {
    final hasColor = _hasValidCarColor;
    final swatch = _hasKnownCarColor ? _carColorSwatch : Colors.grey;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 30,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: swatch.value == const Color(0xFFF5F5F5).value
                        ? AppColors.gray300
                        : Colors.white,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '\u0420\u0430\u043d\u0433',
            maxLines: 1,
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _carColorDisplay,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: hasColor ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlateTile() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\u0420\u0430\u049b\u0430\u043c\u0438 \u043c\u043e\u0448\u0438\u043d',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, box) => AspectRatio(
              aspectRatio: 2131 / 410,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/tojik_plate.png', fit: BoxFit.fill),
                  Positioned(
                    left: box.maxWidth * .21,
                    right: box.maxWidth * .03,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _carPlate.trim().isEmpty
                                ? 'Нишон дода нашудааст'
                                : _formattedPlate,
                            maxLines: 1,
                            style: TextStyle(
                              color: _carPlate.trim().isEmpty
                                  ? AppColors.textTertiary
                                  : const Color(0xFF111111),
                              fontWeight: FontWeight.w800,
                              fontSize: box.maxWidth * .11,
                              letterSpacing: 2,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// Flat, modern card decoration: white surface, hairline border, no shadow.
  BoxDecoration _flatDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    );
  }
}
class _TajikFlagPainter extends CustomPainter {
  const _TajikFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stripeHeight = size.height / 3;
    final colors = [
      const Color(0xFFCC0000),
      Colors.white,
      const Color(0xFF008000),
    ];
    for (var index = 0; index < colors.length; index++) {
      final paint = Paint()..color = colors[index];
      canvas.drawRect(
        Rect.fromLTWH(0, stripeHeight * index, size.width, stripeHeight),
        paint,
      );
    }
    final crownPaint = Paint()..color = const Color(0xFFF5C814);
    canvas.drawCircle(Offset(size.width / 2, stripeHeight * 1.5), 2, crownPaint);
  }

  @override
  bool shouldRepaint(covariant _TajikFlagPainter oldDelegate) => false;
}
