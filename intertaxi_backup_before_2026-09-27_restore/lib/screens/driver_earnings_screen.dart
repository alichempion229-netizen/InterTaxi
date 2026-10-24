import 'package:intertaxi/l10n/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

enum _EarningsPeriod { day, week, month, year, all }

class DriverEarningsScreen extends StatefulWidget {
  final String driverId;

  const DriverEarningsScreen({super.key, required this.driverId});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF738097);
  static const _blue = Color(0xFF1769E0);

  final List<Map<String, dynamic>> _rides = [];
  StreamSubscription<Map<String, dynamic>>? _completionSubscription;
  Timer? _refreshTimer;
  _EarningsPeriod _period = _EarningsPeriod.day;
  bool _initialLoading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _completionSubscription = SocketService.instance.onTripCompleted.listen((
      event,
    ) {
      if (event['driver_id']?.toString() == widget.driverId) {
        _loadEarnings();
      }
    });
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadEarnings(),
    );
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    if (!mounted || _refreshing) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });

    final rides = await ApiService.fetchDriverEarnings(widget.driverId);
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _initialLoading = false;
      if (rides == null) {
        _error =
            'Маълумоти даромадро бор карда натавонистем.';
      } else {
        _rides
          ..clear()
          ..addAll(rides);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _completionSubscription?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredRides {
    if (_period == _EarningsPeriod.all) return List.of(_rides);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return _rides.where((ride) {
      final completedAt = _completedAt(ride);
      if (completedAt == null) return false;
      switch (_period) {
        case _EarningsPeriod.day:
          return completedAt.year == today.year &&
              completedAt.month == today.month &&
              completedAt.day == today.day;
        case _EarningsPeriod.week:
          return !completedAt.isBefore(weekStart) &&
              completedAt.isBefore(weekStart.add(const Duration(days: 7)));
        case _EarningsPeriod.month:
          return completedAt.year == today.year &&
              completedAt.month == today.month;
        case _EarningsPeriod.year:
          return completedAt.year == today.year;
        case _EarningsPeriod.all:
          return true;
      }
    }).toList();
  }

  DateTime? _completedAt(Map<String, dynamic> ride) {
    final value = ride['completed_at']?.toString();
    if (value == null || value.isEmpty) return null;
    final date = DateTime.tryParse(value);
    return date?.toLocal();
  }

  int _earningsFor(Map<String, dynamic> ride) =>
      int.tryParse(ride['earnings']?.toString() ?? '') ?? 0;

  int _approvedSeats(Map<String, dynamic> ride) =>
      int.tryParse(ride['approved_seats']?.toString() ?? '') ?? 0;

  int _pricePerSeat(Map<String, dynamic> ride) =>
      int.tryParse(ride['price_per_seat']?.toString() ?? '') ?? 0;

  int get _selectedTotal =>
      _filteredRides.fold(0, (sum, ride) => sum + _earningsFor(ride));

  String _formatAmount(int amount) {
    final digits = amount.toString();
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
  }

  String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year}  '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  String get _periodLabel => switch (_period) {
    _EarningsPeriod.day => 'Имрӯз',
    _EarningsPeriod.week => 'Ин ҳафта',
    _EarningsPeriod.month => 'Ин моҳ',
    _EarningsPeriod.year => 'Ин сол',
    _EarningsPeriod.all => 'Даромади умумӣ',
  };

  @override
  Widget build(BuildContext context) {
    final rides = _filteredRides;
    final hasUndatedCompletedRides = _rides.any(
      (ride) => _completedAt(ride) == null,
    );
    final dataAvailable = !_initialLoading && _error == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.translate('Даромад'),
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _loadEarnings,
            tooltip: AppLocalizations.translate('Навсозӣ'),
            icon: _refreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEarnings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _buildPeriodFilters(),
            const SizedBox(height: 18),
            _buildSummaryCard(rides, dataAvailable: dataAvailable),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.translate(
                'Ҳисоб аз рӯи нархи ҳар ҷой ва ҷойҳои тасдиқшудаи сафарҳои анҷомёфта аст; пардохти воқеӣ дар барнома сабт намешавад.',
              ),
              style: TextStyle(fontSize: 12, height: 1.45, color: _muted),
            ),
            if (_period != _EarningsPeriod.all && hasUndatedCompletedRides) ...[
              const SizedBox(height: 10),
              _buildUndatedNote(),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.translate(
                      'Сафарҳои анҷомёфта',
                    ),
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  dataAvailable ? '${rides.length}' : 'вЂ”',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_initialLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 42),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _blue,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else if (_error != null)
              _buildErrorState()
            else if (rides.isEmpty)
              _buildEmptyState()
            else
              ...rides.map(_buildRideCard),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilters() {
    const options = <(_EarningsPeriod, String)>[
      (_EarningsPeriod.day, 'Рӯз'),
      (_EarningsPeriod.week, 'Ҳафта'),
      (_EarningsPeriod.month, 'РњРѕТі'),
      (_EarningsPeriod.year, 'Сол'),
      (_EarningsPeriod.all, 'Даромади умумӣ'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            ChoiceChip(
              label: Text(option.$2),
              selected: _period == option.$1,
              onSelected: (_) => setState(() => _period = option.$1),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: _period == option.$1 ? Colors.white : _muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              selectedColor: _blue,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: _period == option.$1 ? _blue : const Color(0xFFE4E9F1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    List<Map<String, dynamic>> rides, {
    required bool dataAvailable,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08132344),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  AppIcons.payments_rounded,
                  color: _blue,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Text(
                _periodLabel,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              dataAvailable
                  ? '${_formatAmount(_selectedTotal)} СЃРѕРјРѕРЅУЈ'
                  : 'вЂ”',
              style: const TextStyle(
                color: _ink,
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.route_rounded, size: 16, color: _muted),
              const SizedBox(width: 7),
              Text(
                dataAvailable
                    ? '${rides.length} сафар'
                    : _initialLoading
                    ? 'Маълумот бор шуда истодааст'
                    : 'Маълумот дастрас нест',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUndatedNote() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      AppLocalizations.translate(
        'Барои баъзе сафарҳои пешина санаи анҷом сабт нашудааст. Онҳо танҳо дар даромади умумӣ дохил мешаванд.',
      ),
      style: TextStyle(color: Color(0xFF80621F), fontSize: 12, height: 1.4),
    ),
  );

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final from = ride['from_location']?.toString().trim() ?? '';
    final to = ride['to_location']?.toString().trim() ?? '';
    final seats = _approvedSeats(ride);
    final price = _pricePerSeat(ride);
    final completedAt = _completedAt(ride);
    final earnings = _earningsFor(ride);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FC),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.route_rounded, color: _blue, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$from в†’ $to',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  completedAt == null
                      ? 'Санаи анҷом сабт нашудааст'
                      : _formatDate(completedAt),
                  style: const TextStyle(color: _muted, fontSize: 11.5),
                ),
                const SizedBox(height: 4),
                Text(
                  seats == 0
                      ? 'Бронҳои тасдиқшуда надорад'
                      : '$seats ҷой × ${_formatAmount(price)} сомонӣ',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.translate(
              '${_formatAmount(earnings)} СЃРѕРјРѕРЅУЈ',
            ),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7ECF3)),
    ),
    child: Column(
      children: [
        Icon(Icons.receipt_long_rounded, color: Color(0xFFA7B1C1), size: 30),
        SizedBox(height: 10),
        Text(
          AppLocalizations.translate(
            'Дар ин давра сафарҳои анҷомёфта нестанд.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
        ),
      ],
    ),
  );

  Widget _buildErrorState() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7ECF3)),
    ),
    child: Column(
      children: [
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _loadEarnings,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(
            AppLocalizations.translate('Аз нав кӯшиш кардан'),
          ),
        ),
      ],
    ),
  );
}
