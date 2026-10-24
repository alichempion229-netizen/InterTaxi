import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:intertaxi/app_icons.dart';
import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../constants/glass_theme.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../widgets/glass_widgets.dart';

class SocketDriverScreen extends StatefulWidget {
  final String driverName;
  final String driverPhone;
  final String driverCar;

  const SocketDriverScreen({
    super.key,
    required this.driverName,
    required this.driverPhone,
    this.driverCar = '',
  });

  @override
  State<SocketDriverScreen> createState() => _SocketDriverScreenState();
}

class _SocketDriverScreenState extends State<SocketDriverScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  bool _isConnected = false;
  String _status = 'Disconnected';
  Color _statusColor = GlassColors.danger;
  final List<Map<String, dynamic>> _myTrips = [];

  StreamSubscription<bool>? _connSub;
  StreamSubscription<Map<String, dynamic>>? _newTripSub;
  StreamSubscription<Map<String, dynamic>>? _tripUpdSub;
  StreamSubscription<Map<String, dynamic>>? _tripDelSub;
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
    });

    _newTripSub = SocketService.instance.onNewTrip.listen((trip) {
      if (!mounted) return;
      if (trip['driver_id'] == widget.driverPhone) {
        setState(() => _myTrips.insert(0, trip));
      }
    });

    _tripUpdSub = SocketService.instance.onTripUpdated.listen((t) {
      if (!mounted) return;
      final i = _myTrips.indexWhere((x) => x['id'] == t['id']);
      if (i >= 0) setState(() => _myTrips[i] = t);
    });

    // A trip was deleted (by this driver or elsewhere) — keep our list in sync.
    _tripDelSub = SocketService.instance.onTripDeleted.listen((data) {
      if (!mounted) return;
      final id = data['id']?.toString();
      if (id == null || id.isEmpty) return;
      setState(() {
        _myTrips.removeWhere((x) => x['id']?.toString() == id);
      });
    });

    _errSub = SocketService.instance.onError.listen((msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: GlassColors.danger),
      );
    });
  }

  void _connect() {
    SocketService.instance.connect(userId: widget.driverPhone, role: 'driver');
  }

  Future<void> _publish() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not connected'),
          backgroundColor: GlassColors.danger,
        ),
      );
      return;
    }
    final from = _fromCtrl.text.trim();
    final to = _toCtrl.text.trim();
    final price = _priceCtrl.text.trim();
    final seats = _seatsCtrl.text.trim();
    if (from.isEmpty || to.isEmpty || price.isEmpty || seats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fill all fields'),
          backgroundColor: GlassColors.warning,
        ),
      );
      return;
    }
    final payload = {
      'driver_id': widget.driverPhone,
      'driver_name': widget.driverName,
      'driver_phone': widget.driverPhone,
      'from_location': from,
      'to_location': to,
      'price': int.tryParse(price) ?? 0,
      'available_seats': int.tryParse(seats) ?? 0,
      'departure_time': _dateCtrl.text.isEmpty
          ? DateTime.now().toIso8601String()
          : '${_dateCtrl.text}T${_timeCtrl.text}:00',
    };

    // Primary path: real-time Socket.IO emit. The server broadcasts the trip
    // back on `new_trip`, which the listener below inserts into _myTrips.
    final sent = await SocketService.instance.postTrip(payload);

    // Fallback path: if the socket dropped between the status check and the
    // emit, push the announcement via REST so it is never lost.
    if (!sent) {
      final ok = await ApiService.postTrip(payload);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Serverga ulanib bo\'lmadi (publish failed)'),
            backgroundColor: GlassColors.danger,
          ),
        );
        return;
      }
      // The trip is saved server-side, but no socket broadcast will reach us
      // while offline — show it in our own list immediately.
      setState(() {
        _myTrips.insert(0, {
          ...payload,
          'id': -(DateTime.now().millisecondsSinceEpoch),
          'status': 'active',
        });
      });
    }

    _fromCtrl.clear();
    _toCtrl.clear();
    _priceCtrl.clear();
    _seatsCtrl.clear();
    _dateCtrl.clear();
    _timeCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trip published!'),
        backgroundColor: GlassColors.success,
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) {
      _dateCtrl.text =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null && mounted) {
      _timeCtrl.text =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _newTripSub?.cancel();
    _tripUpdSub?.cancel();
    _tripDelSub?.cancel();
    _errSub?.cancel();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _priceCtrl.dispose();
    _seatsCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Driver - ${widget.driverName}'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildForm(),
                const SizedBox(height: 24),
                Text(
                  'My Trips (${_myTrips.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: GlassColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTripsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Post New Trip',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: GlassColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _field(
            _fromCtrl,
            'From (City)',
            AppIcons.my_location,
            GlassColors.accentSky,
          ),
          const SizedBox(height: 12),
          _field(
            _toCtrl,
            'To (City)',
            AppIcons.location_on,
            GlassColors.accentBlue,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  _priceCtrl,
                  'Price (Somoni)',
                  AppIcons.attach_money,
                  GlassColors.accentLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _seatsCtrl,
                  'Seats',
                  AppIcons.event_seat,
                  GlassColors.accentSky,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: _field(
                      _dateCtrl,
                      'Date',
                      AppIcons.calendar_today,
                      GlassColors.accentLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: AbsorbPointer(
                    child: _field(
                      _timeCtrl,
                      'Time',
                      AppIcons.access_time,
                      GlassColors.accentSky,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GlassButton(
            text: 'Publish Trip',
            icon: AppIcons.send_rounded,
            height: 50,
            enabled: _isConnected,
            onPressed: _publish,
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

  Widget _buildTripsList() {
    if (_myTrips.isEmpty) {
      return GlassCard(
        radius: 18,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              AppIcons.directions_car,
              size: 48,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No trips posted',
              style: TextStyle(color: GlassColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _myTrips.length,
      itemBuilder: (_, i) => _tripCard(_myTrips[i]),
    );
  }

  /// Asks the server to delete one of the driver's own trips.
  ///
  /// PRIMARY path: REST `http.delete('$base/api/trips/<id>')` — this always
  /// hits the server so the row is REALLY removed from the database (Render).
  /// The server then broadcasts `trip_deleted` to every connected client,
  /// which also removes the row from this driver's own list in real time.
  /// FALLBACK: Socket.IO `delete_trip` when HTTP is unreachable.
  /// The local list is only updated AFTER the server confirms, so the app
  /// can never drift out of sync with the server.
  Future<void> _deleteTrip(Map<String, dynamic> t) async {
    final id = t['id']?.toString() ?? '';
    if (id.isEmpty || id.startsWith('-')) return; // offline placeholder row

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text(
          AppLocalizations.translate(
            'Трип нест карда шавад? Мусофирон онро фавран мебинанд.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: GlassColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // 1) ALWAYS send the HTTP DELETE to the server first. This guarantees
    //    the trip is permanently deleted from the server database.
    final ok = await ApiService.deleteTrip(id);
    if (!mounted) return;

    if (ok) {
      // Server confirmed (deleted now, or already gone). Sync the local
      // list immediately — the `trip_deleted` broadcast usually does this
      // first, this is just a safety net.
      setState(() {
        _myTrips.removeWhere((x) => x['id']?.toString() == id);
      });
      return;
    }

    // 2) HTTP failed (server unreachable) — fall back to Socket.IO.
    final sent = await SocketService.instance.deleteTrip(
      id,
      ack: (resp) {
        final respOk = resp is Map && resp['ok'] == true;
        if (!mounted) return;
        if (respOk) {
          setState(() {
            _myTrips.removeWhere((x) => x['id']?.toString() == id);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.translate(
                  'Нест карда нашуд (delete failed)',
                ),
              ),
              backgroundColor: GlassColors.danger,
            ),
          );
        }
      },
    );
    if (!sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'Сервер дастрас нест (server unreachable)',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _tripCard(Map<String, dynamic> t) {
    final from = t['from_location'] ?? 'Unknown';
    final to = t['to_location'] ?? 'Unknown';
    final price = t['price'] ?? '0';
    final seats = t['available_seats'] ?? '0';
    final active = t['status'] == 'active';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    active ? 'ACTIVE' : 'BOOKED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: active ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$price Somoni',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066FF),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete this trip (broadcasts trip_deleted to all users)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    AppIcons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                  tooltip: AppLocalizations.translate('Нест кардан'),
                  onPressed: () => _deleteTrip(t),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(AppIcons.my_location, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Text(AppLocalizations.translate(from)),
              ],
            ),
            Row(
              children: [
                const Icon(AppIcons.location_on, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Text(AppLocalizations.translate(to)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(AppIcons.event_seat, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$seats seats',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
