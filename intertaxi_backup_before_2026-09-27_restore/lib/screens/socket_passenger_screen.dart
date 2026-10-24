import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:intertaxi/app_icons.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/glass_theme.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../widgets/glass_widgets.dart';
import 'trip_detail_screen.dart';

class SocketPassengerScreen extends StatefulWidget {
  final String passengerName;
  final String passengerPhone;

  const SocketPassengerScreen({
    super.key,
    required this.passengerName,
    required this.passengerPhone,
  });

  @override
  State<SocketPassengerScreen> createState() => _SocketPassengerScreenState();
}

class _SocketPassengerScreenState extends State<SocketPassengerScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  bool _isConnected = false;
  String _status = 'Disconnected';
  Color _statusColor = GlassColors.danger;
  final List<Map<String, dynamic>> _trips = [];

  StreamSubscription<bool>? _connSub;
  StreamSubscription<List<Map<String, dynamic>>>? _listSub;
  StreamSubscription<Map<String, dynamic>>? _newSub;
  StreamSubscription<Map<String, dynamic>>? _updSub;
  StreamSubscription<Map<String, dynamic>>? _deletedSub;
  StreamSubscription<Map<String, dynamic>>? _bookSub;
  StreamSubscription<String>? _errSub;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _connect();
  }

  void _setupListeners() {
    _connSub = SocketService.instance.onConnectionStatus.listen((ok) {
      if (!mounted) return;
      setState(() {
        _isConnected = ok;
        _status = ok ? 'Connected' : 'Disconnected';
        _statusColor = ok ? GlassColors.success : GlassColors.danger;
      });
      if (ok) SocketService.instance.getTrips();
    });

    _listSub = SocketService.instance.onTripsList.listen((trips) {
      if (!mounted) return;
      setState(() {
        _trips.clear();
        _trips.addAll(trips);
      });
    });

    _newSub = SocketService.instance.onNewTrip.listen((t) {
      if (!mounted) return;
      // Respect the active route filter: a newly posted trip is only shown
      // when it matches the EXACT route the passenger is searching for.
      final f = _fromCtrl.text.trim();
      final toFilter = _toCtrl.text.trim();
      final tFrom = t['from_location']?.toString() ?? '';
      final tTo = t['to_location']?.toString() ?? '';
      if (f.isNotEmpty && tFrom != f) return;
      if (toFilter.isNotEmpty && tTo != toFilter) return;
      if (!_trips.any((x) => x['id'] == t['id'])) {
        setState(() => _trips.insert(0, t));
      }
    });

    _updSub = SocketService.instance.onTripUpdated.listen((t) {
      if (!mounted) return;
      final i = _trips.indexWhere((x) => x['id'] == t['id']);
      if (i >= 0) setState(() => _trips[i] = t);
    });

    // A driver deleted their trip вЂ” remove it from the list in real time.
    _deletedSub = SocketService.instance.onTripDeleted.listen((data) {
      if (!mounted) return;
      final id = data['id']?.toString();
      if (id == null || id.isEmpty) return;
      setState(() {
        _trips.removeWhere((x) => x['id']?.toString() == id);
      });
    });

    _bookSub = SocketService.instance.onBookingConfirmed.listen((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed!'),
          backgroundColor: Colors.green,
        ),
      );
    });

    _errSub = SocketService.instance.onError.listen((msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    });
  }

  void _connect() {
    SocketService.instance.connect(
      userId: widget.passengerPhone,
      role: 'passenger',
    );
  }

  void _search() {
    if (_isConnected) {
      SocketService.instance.getTrips(
        from: _fromCtrl.text.trim(),
        to: _toCtrl.text.trim(),
      );
    } else {
      _loadViaRest();
    }
  }

  Future<void> _loadViaRest() async {
    try {
      final base = await ApiService.resolveBaseUrl();
      final uri = Uri.parse('$base/api/trips').replace(
        queryParameters: {
          if (_fromCtrl.text.trim().isNotEmpty) 'from': _fromCtrl.text.trim(),
          if (_toCtrl.text.trim().isNotEmpty) 'to': _toCtrl.text.trim(),
        },
      );
      final resp = await http.get(uri);
      if (resp.statusCode == 200 && mounted) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (data['trips'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _trips.clear();
          _trips.addAll(list);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _listSub?.cancel();
    _newSub?.cancel();
    _updSub?.cancel();
    _deletedSub?.cancel();
    _bookSub?.cancel();
    _errSub?.cancel();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Musofir - ${widget.passengerName}'),
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(AppIcons.circle, size: 10, color: _statusColor),
                const SizedBox(width: 4),
                Text(
                  _status,
                  style: TextStyle(fontSize: 12, color: _statusColor),
                ),
              ],
            ),
          ),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildSearch(),
              if (!_isConnected) _buildBanner(),
              Expanded(
                child: _visibleTrips.isEmpty ? _buildEmpty() : _buildList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return GlassCard(
      width: double.infinity,
      radius: 18,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      fillColor: GlassColors.warning.withValues(alpha: 0.16),
      borderOpacity: 0.45,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                AppIcons.warning_amber,
                color: GlassColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Socket.IO disconnected',
                  style: TextStyle(
                    fontSize: 12,
                    color: GlassColors.textPrimary,
                  ),
                ),
              ),
              TextButton(onPressed: _connect, child: const Text('Retry')),
            ],
          ),
          const SizedBox(height: 8),
          GlassButton(
            text: 'Load via REST',
            icon: AppIcons.download,
            height: 44,
            fontSize: 14,
            onPressed: _loadViaRest,
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return GlassCard(
      radius: 20,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _field(
                  _fromCtrl,
                  'From',
                  AppIcons.my_location,
                  GlassColors.accentSky,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _toCtrl,
                  'To',
                  AppIcons.location_on,
                  GlassColors.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassButton(
            text: 'Search Trips',
            icon: AppIcons.search,
            height: 48,
            fontSize: 15,
            onPressed: _search,
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon,
    Color color,
  ) {
    return TextField(
      controller: c,
      style: const TextStyle(fontSize: 14, color: GlassColors.textPrimary),
      cursorColor: GlassColors.accentSky,
      decoration: glassInputDecoration(
        hintText: label,
        dense: true,
        radius: 12,
        prefixIcon: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppIcons.directions_car_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            _isConnected ? 'No trips found' : 'Not connected',
            style: const TextStyle(
              fontSize: 18,
              color: GlassColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isConnected ? 'Waiting for drivers...' : 'Tap Load via REST',
            style: const TextStyle(fontSize: 14, color: GlassColors.textMuted),
          ),
          if (!_isConnected) ...[
            const SizedBox(height: 16),
            GlassButton(
              text: 'Load via REST',
              icon: AppIcons.download,
              height: 46,
              fontSize: 14,
              onPressed: _loadViaRest,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList() {
    final visible = _visibleTrips;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visible.length,
      itemBuilder: (_, i) => _tripCard(visible[i]),
    );
  }

  /// Trips displayed on screen: ONLY the trips whose `from_location` AND
  /// `to_location` PRECISELY match the current search fields
  /// (trimmed, case-insensitive).
  ///
  /// The server already filters strictly (`GET /api/trips?from=...&to=...`
  /// uses `ilike`), but `new_trip` broadcasts and offline REST loads are
  /// double-checked here so a trip for a DIFFERENT route (e.g.
  /// "Кулоб -> Душанбе" while searching "Кулоб -> Восе") can never appear
  /// in the passenger's list.
  List<Map<String, dynamic>> get _visibleTrips {
    final f = _fromCtrl.text.trim().toLowerCase();
    final t = _toCtrl.text.trim().toLowerCase();
    if (f.isEmpty && t.isEmpty) return List.unmodifiable(_trips);
    return _trips.where((trip) {
      final tFrom =
          trip['from_location']?.toString().trim().toLowerCase() ?? '';
      final tTo = trip['to_location']?.toString().trim().toLowerCase() ?? '';
      if (f.isNotEmpty && tFrom != f) return false;
      if (t.isNotEmpty && tTo != t) return false;
      return true;
    }).toList();
  }

  /// Premium compact, flat, modern trip card.
  ///
  /// Shows ONLY: Driver Name (РќРѕРјСѓ РќР°СЃР°Р±), Phone Number (Р Р°Т›Р°РјРё С‚РµР»РµС„РѕРЅ),
  /// Available Seats (Т¶РѕРё РЅРёС€Р°СЃС‚), the Route (РњР°СЃРёСЂ: Р°Р· РєСѓТ·Рѕ С‚Рѕ РєСѓТ·Рѕ) and a
  /// "Подробно" button that opens [TripDetailScreen] with the full info.
  Widget _tripCard(Map<String, dynamic> t) {
    final dName = t['driver_name']?.toString() ?? '';
    final dPhone = t['driver_phone']?.toString() ?? '';
    final seats = t['available_seats']?.toString() ?? '0';
    final from = t['from_location']?.toString() ?? '';
    final to = t['to_location']?.toString() ?? '';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      radius: 18,
      blur: 12,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      onTap: () => _openDetails(t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Driver avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: GlassGradients.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  AppIcons.person_rounded,
                  size: 24,
                  color: GlassColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              // Driver name + phone number
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dName.isEmpty ? 'Ронанда' : dName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: GlassColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          AppIcons.phone_rounded,
                          size: 13,
                          color: GlassColors.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          dPhone.isEmpty ? 'вЂ”' : dPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: GlassColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 12),
          // Route (РњР°СЃРёСЂ: Р°Р· РєСѓТ·Рѕ С‚Рѕ РєСѓТ·Рѕ).
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 14,
                color: Colors.white.withValues(alpha: 0.35),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.translate('Масир: аз $from то $to'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GlassColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Available seats (Т¶РѕРё РЅРёС€Р°СЃС‚) + "Подробно" button.
          Row(
            children: [
              const Icon(
                AppIcons.event_seat_rounded,
                size: 16,
                color: GlassColors.accentSky,
              ),
              const SizedBox(width: 5),
              Text(
                AppLocalizations.translate('Ҷои нишаст: $seats'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: GlassColors.textSecondary,
                ),
              ),
              const Spacer(),
              GlassButton(
                text: AppLocalizations.translate('Подробно'),
                outlined: true,
                height: 36,
                radius: 10,
                fontSize: 13,
                onPressed: () => _openDetails(t),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openDetails(Map<String, dynamic> t) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripDetailScreen(
          trip: t,
          passengerName: widget.passengerName,
          passengerPhone: widget.passengerPhone,
        ),
      ),
    );
  }
}
