import 'package:intertaxi/app_icons.dart';
import 'package:intertaxi/l10n/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

enum _EarningsPeriod { day, week, month, year, all }

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

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
  int _total = 0;
  int _requestVersion = 0;
  bool _initialLoading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _completionSubscription = SocketService.instance.onTripCompleted.listen((
      _,
    ) {
      _loadEarnings();
    });
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadEarnings(),
    );
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    if (!mounted) return;
    final requestVersion = ++_requestVersion;
    setState(() {
      _refreshing = true;
      _error = null;
    });

    final response = await ApiService.fetchDriverEarnings(period: _period.name);
    if (!mounted || requestVersion != _requestVersion) return;
    setState(() {
      _refreshing = false;
      _initialLoading = false;
      final trips = response?['trips'];
      if (response == null || trips is! List) {
        _error = 'Маълумоти даромадро бор карда натавонистем.';
      } else {
        _rides
          ..clear()
          ..addAll(trips.whereType<Map<String, dynamic>>());
        _total = int.tryParse(response['total']?.toString() ?? '') ?? 0;
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
    return List.of(_rides);
  }

  DateTime? _completedAt(Map<String, dynamic> ride) {
    final value = ride['completed_at']?.toString();
    if (value == null || value.isEmpty) return null;
    final date = DateTime.tryParse(value);
    return date?.toLocal();
  }

  int _earningsFor(Map<String, dynamic> ride) =>
      int.tryParse(ride['earnings']?.toString() ?? '') ?? 0;

  int get _selectedTotal => _total;

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
    _EarningsPeriod.week => 'Ҳафта',
    _EarningsPeriod.month => 'Моҳ',
    _EarningsPeriod.year => 'Сол',
    _EarningsPeriod.all => 'Ҳамагӣ',
  };

  @override
  Widget build(BuildContext context) {
    final rides = _filteredRides;
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
                : const Icon(AppIcons.refresh_rounded),
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
                'Даромад пас аз анҷоми сафар сабт мешавад.',
              ),
              style: TextStyle(fontSize: 12, height: 1.45, color: _muted),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.translate('Сафарҳои анҷомёфта'),
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  dataAvailable ? '${rides.length}' : '—',
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
      (_EarningsPeriod.day, 'Имрӯз'),
      (_EarningsPeriod.week, 'Ҳафта'),
      (_EarningsPeriod.month, 'Моҳ'),
      (_EarningsPeriod.year, 'Сол'),
      (_EarningsPeriod.all, 'Ҳамагӣ'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            ChoiceChip(
              label: Text(option.$2),
              selected: _period == option.$1,
              onSelected: (_) {
                if (_period == option.$1) return;
                setState(() {
                  _period = option.$1;
                  _initialLoading = true;
                  _rides.clear();
                  _total = 0;
                });
                _loadEarnings();
              },
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: FittedBox(
              key: ValueKey(dataAvailable ? _selectedTotal : 'unavailable'),
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                dataAvailable ? '${_formatAmount(_selectedTotal)} TJS' : '—',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(AppIcons.route_rounded, size: 16, color: _muted),
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

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final from = ride['from_location']?.toString().trim() ?? '';
    final to = ride['to_location']?.toString().trim() ?? '';
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
            child: const Icon(AppIcons.route_rounded, color: _blue, size: 19),
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
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${_formatAmount(earnings)} TJS',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _blue,
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
        Icon(AppIcons.receipt_long_rounded, color: Color(0xFFA7B1C1), size: 30),
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
          icon: const Icon(AppIcons.refresh_rounded, size: 18),
          label: Text(AppLocalizations.translate('Аз нав кӯшиш кардан')),
        ),
      ],
    ),
  );
}
