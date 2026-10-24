import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:intertaxi/app_icons.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/intertaxi_models.dart' as models;
import '../services/api_service.dart';
import '../widgets/city_selection_modal.dart';

/// InterTaxi Create Order Screen
/// Allows drivers to create new ride orders
class CreateOrderScreen extends StatefulWidget {
  final String driverName;
  final String driverPhone;

  const CreateOrderScreen({
    super.key,
    required this.driverName,
    required this.driverPhone,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  int _seats = 3;
  DateTime? _departureTime;
  bool _isLoading = false;
  late final AnimationController _publishAnimationController;

  final List<String> _locations = tajikCities;

  @override
  void dispose() {
    _publishAnimationController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _publishAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  static const Map<String, LatLng> _cityCoordinates = {
    'Душанбе': LatLng(38.5598, 68.7870),
    'Кӯлоб': LatLng(37.9146, 69.7847),
    'Восеъ': LatLng(37.8042, 69.6442),
    'Хуҷанд': LatLng(40.2826, 69.6222),
    'Бохтар': LatLng(37.8368, 68.7802),
    'Канибодом': LatLng(40.2833, 70.4333),
    'Исфара': LatLng(40.1228, 70.5983),
    'Файзобод': LatLng(38.5473, 69.2132),
    'Турсунзода': LatLng(38.5126, 68.2312),
    'Панҷакент': LatLng(39.4952, 67.6093),
    'Истаравшан': LatLng(39.9142, 69.0033),
    'Ваҳдат': LatLng(38.5563, 69.0135),
    'ТІРёСЃРѕСЂ': LatLng(38.5256, 68.5512),
    'РҐРѕСЂСѓТ“': LatLng(37.4893, 71.5532),
    'Данғара': LatLng(38.0983, 69.3384),
    'РЇРІРѕРЅ': LatLng(38.3090, 69.0558),
    'Рашт': LatLng(39.0286, 70.3733),
    'Шаҳритус': LatLng(37.2625, 68.1381),
    'Қубодиён': LatLng(37.4308, 68.0839),
    'Ҷаббор Расулов': LatLng(40.2458, 69.5000),
    'Спитамен': LatLng(40.2208, 69.3400),
    'Дарвоз': LatLng(38.4578, 70.7816),
  };

  Future<int> _calculateDurationMinutes() async {
    final from = _cityCoordinates[_pickupController.text.trim()];
    final to = _cityCoordinates[_destinationController.text.trim()];
    if (from == null || to == null) return 0;

    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
        {'overview': 'false'},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        final seconds = routes?.isNotEmpty == true
            ? (routes!.first['duration'] as num?)?.toDouble() ?? 0
            : 0;
        if (seconds > 0) return (seconds / 60).round();
      }
    } catch (_) {
      // Use a conservative local estimate if routing is temporarily offline.
    }

    final distanceKm = const Distance().as(LengthUnit.Kilometer, from, to);
    return (distanceKm / 55 * 60).round().clamp(1, 24 * 60);
  }

  Future<void> _selectDepartureTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0066FF),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF0066FF),
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _departureTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _handleCreateOrder() async {
    if (_pickupController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'Лутфан макони оғозро ворид кунед',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'Лутфан макони таъинотро ворид кунед',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'Лутфан нархро ворид кунед',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_departureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'Лутфан вақти рафтанро интихоб кунед',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    _publishAnimationController.repeat();

    try {
      final prefs = await SharedPreferences.getInstance();
      final durationTotalMinutes = await _calculateDurationMinutes();
      if (durationTotalMinutes <= 0) {
        throw Exception(
          'Давомнокии масир муайян карда нашуд',
        );
      }
      // 1) Publish the announcement to the server FIRST and capture the REAL
      //    server id (UUID). Storing that same id locally is what makes the
      //    delete button able to remove the row on the server too (and
      //    broadcast `trip_deleted` to every passenger device).
      final serverTrip = await ApiService.createTrip({
        'driver_id': widget.driverPhone,
        'driver_name': widget.driverName,
        'driver_phone': widget.driverPhone,
        'from_location': _pickupController.text.trim(),
        'to_location': _destinationController.text.trim(),
        'departure_time': _departureTime!.toIso8601String(),
        'duration_minutes': durationTotalMinutes,
        'car_brand': prefs.getString('driver_car_brand') ?? '',
        'car_model': prefs.getString('driver_car_model') ?? '',
        'car_color': prefs.getString('driver_car_color') ?? '',
        'car_plate': prefs.getString('driver_plate_number') ?? '',
        'price':
            int.tryParse(
              _priceController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0,
        'available_seats': _seats,
      });

      // 2) Build the local order using the server id when available
      //    (offline fallback keeps a local timestamp id).
      final order = models.Order(
        id:
            serverTrip?['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        fromLocation: _pickupController.text,
        toLocation: _destinationController.text,
        price: _priceController.text,
        duration: _formatDuration(durationTotalMinutes),
        durationMinutes: durationTotalMinutes,
        seats: _seats,
        notes: _notesController.text,
        createdAt: DateTime.now().toIso8601String(),
        departureTime: _departureTime!.toIso8601String(),
        driverName: widget.driverName,
        driverPhone: widget.driverPhone,
        carBrand: prefs.getString('driver_car_brand') ?? '',
        carModel: prefs.getString('driver_car_model') ?? '',
        carColor: prefs.getString('driver_car_color') ?? '',
        carPlate: prefs.getString('driver_plate_number') ?? '',
      );

      // 3) Persist the order locally (SharedPreferences) so it appears in
      //    "Эълонҳои ман" and survives app restarts.
      await models.saveOrder(order);

      if (!mounted) return;
      _publishAnimationController.stop();
      setState(() => _isLoading = false);

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
              Text(
                AppLocalizations.translate(
                  'Эълон бо муваффақият гузошта шуд',
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.translate(
                  'Мусофирон метавонанд ин сафарро интихоб кунанд',
                ),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to home
              },
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
    } catch (e) {
      if (!mounted) return;
      _publishAnimationController.stop();
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'Ҳангоми гузоштани эълон хато шуд: $e',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes дақиқа';
    if (minutes == 0) return '$hours соат';
    return '$hours соат $minutes дақиқа';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumHeader(),
                const SizedBox(height: 20),
                _buildRouteCard(),
                const SizedBox(height: 16),
                _buildTripOptionsCard(),
                const SizedBox(height: 16),
                _buildNotesCard(),
                const SizedBox(height: 22),
                _buildPublishButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF0052CC), Color(0xFF3385FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.campaign_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.translate('Эълон кардан'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  AppLocalizations.translate(
                    'Масир ва шартҳои сафарро интихоб кунед',
                  ),
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    return _buildCard(
      title: AppLocalizations.translate('Масири сафар'),
      icon: AppIcons.route_rounded,
      child: Column(
        children: [
          _buildLocationField(
            controller: _pickupController,
            hintText: AppLocalizations.translate(
              'Аз куҷо меравед?',
            ),
            icon: AppIcons.trip_origin_rounded,
            locations: _locations,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                children: List.generate(
                  3,
                  (_) => Container(
                    width: 2,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: const Color(0xFFB9CFFF),
                  ),
                ),
              ),
            ),
          ),
          _buildLocationField(
            controller: _destinationController,
            hintText: AppLocalizations.translate(
              'Ба куҷо меравед?',
            ),
            icon: AppIcons.location_on_rounded,
            locations: _locations,
          ),
        ],
      ),
    );
  }

  Widget _buildTripOptionsCard() {
    return _buildCard(
      title: AppLocalizations.translate('Шартҳои сафар'),
      icon: AppIcons.tune_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildPriceField()),
              const SizedBox(width: 12),
              Expanded(child: _buildSeatsField()),
            ],
          ),
          const SizedBox(height: 14),
          _buildDepartureField(),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _buildCard(
      title: AppLocalizations.translate('Эзоҳ'),
      icon: AppIcons.notes_rounded,
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: _inputDecoration('Маълумоти иловагӣ...'),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5ECF8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: const Color(0xFF0066FF), size: 19),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FAFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE0E8F5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE0E8F5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
    ),
  );

  Widget _buildPriceField() => TextFormField(
    controller: _priceController,
    keyboardType: TextInputType.number,
    decoration: _inputDecoration('Нарх (сомонӣ)').copyWith(
      prefixIcon: const Icon(
        AppIcons.payments_rounded,
        color: Color(0xFF0066FF),
      ),
    ),
  );

  Widget _buildSeatsField() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E8F5)),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.event_seat_rounded,
            color: Color(0xFF0066FF),
            size: 20,
          ),
          const Spacer(),
          IconButton(
            onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
            icon: const Icon(AppIcons.remove_circle_outline_rounded),
            color: const Color(0xFF0066FF),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$_seats',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          IconButton(
            onPressed: _seats < 8 ? () => setState(() => _seats++) : null,
            icon: const Icon(AppIcons.add_circle_outline_rounded),
            color: const Color(0xFF0066FF),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartureField() {
    return InkWell(
      onTap: _selectDepartureTime,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E8F5)),
        ),
        child: Row(
          children: [
            const Icon(AppIcons.schedule_rounded, color: Color(0xFF0066FF)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _departureTime == null
                    ? 'Вақти рафтанро интихоб кунед'
                    : '${_departureTime!.hour.toString().padLeft(2, '0')}:${_departureTime!.minute.toString().padLeft(2, '0')}  ${_departureTime!.day.toString().padLeft(2, '0')}.${_departureTime!.month.toString().padLeft(2, '0')}.${_departureTime!.year}',
                style: TextStyle(
                  color: _departureTime == null
                      ? Colors.grey[600]
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              AppIcons.chevron_right_rounded,
              color: Color(0xFF7B8AA6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleCreateOrder,
        icon: _isLoading
            ? AnimatedBuilder(
                animation: _publishAnimationController,
                builder: (context, child) => Transform.rotate(
                  angle: _publishAnimationController.value * 6.28318,
                  child: child,
                ),
                child: const Icon(AppIcons.directions_car_rounded, size: 22),
              )
            : const Icon(AppIcons.directions_car_rounded),
        label: Text(
          AppLocalizations.translate('Эълон кардан'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1769E0),
          disabledBackgroundColor: const Color(0xFF9CC2FF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required List<String> locations,
  }) {
    return InkWell(
      onTap: () async {
        final selected = await showCitySelectionSheet(
          context: context,
          title: hintText,
          cities: locations,
          selectedCity: controller.text.isEmpty ? null : controller.text,
        );
        if (selected != null && mounted) {
          setState(() => controller.text = selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0066FF), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.text.isEmpty ? hintText : controller.text,
                style: TextStyle(
                  fontSize: 15,
                  color: controller.text.isEmpty
                      ? Colors.grey[600]
                      : Colors.black87,
                  fontWeight: controller.text.isEmpty
                      ? FontWeight.normal
                      : FontWeight.w500,
                ),
              ),
            ),
            Icon(
              AppIcons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
