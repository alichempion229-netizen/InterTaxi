import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:intertaxi/app_icons.dart';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/glass_theme.dart';
import '../services/api_service.dart';
import '../widgets/glass_widgets.dart';

/// Lets the user point the app at the InterTaxi Flask backend.
///
/// The backend is deployed on Render at `https://intertaxi-zarc.onrender.com` and
/// that is the default address for every REST and Socket.IO call. This screen
/// only exists as an override for local development (e.g. pointing the app at
/// a Flask instance running on a PC: `http://192.168.1.20:5000`). The address
/// is stored in SharedPreferences (key `backend_url`) and used by every REST
/// and Socket.IO call through [ApiService.resolveBaseUrl].
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  static const String _baseUrlPrefsKey = 'backend_url';

  final TextEditingController _urlCtrl = TextEditingController();
  String _currentUrl = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final effective = await ApiService.resolveBaseUrl();
    if (!mounted) return;
    setState(() {
      _currentUrl = effective;
      // The field shows the saved override only (empty = platform default).
      _urlCtrl.text = prefs.getString(_baseUrlPrefsKey) ?? '';
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    await ApiService.setCustomBaseUrl(_urlCtrl.text);
    final effective = await ApiService.resolveBaseUrl();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _currentUrl = effective;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.translate(
            'Суроғаи сервер нигоҳ дошта шуд: $effective',
          ),
        ),
        backgroundColor: GlassColors.accentBlue,
      ),
    );
  }

  Future<void> _reset() async {
    await ApiService.setCustomBaseUrl('');
    final effective = await ApiService.resolveBaseUrl();
    if (!mounted) return;
    setState(() {
      _urlCtrl.clear();
      _currentUrl = effective;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.translate(
            'Ба пешфарз баргашт: $effective',
          ),
        ),
      ),
    );
  }

  /// Pings the backend by fetching the trips list.
  Future<void> _testConnection() async {
    setState(() => _busy = true);
    final trips = await ApiService.fetchTrips();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          trips.isNotEmpty
              ? 'Пайваст шуд! Эълонҳои фаъол: ${trips.length}'
              : 'Пайвастшавӣ нагузашт ё эълонҳо нестанд. IP-и компютерро санҷед.',
        ),
        backgroundColor: trips.isNotEmpty
            ? GlassColors.success
            : GlassColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.translate('Сервер')),
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
      ),
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentCard(),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.translate('Суроғаи нав'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GlassColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                GlassTextField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  hintText: 'https://intertaxi-zarc.onrender.com',
                  prefixIcon: const Icon(AppIcons.link_rounded),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.translate(
                    'Сервери Render ҳамчун сервери пешфарз истифода мешавад. Барои сервери маҳаллӣ URL-ро ворид кунед.',
                  ),
                  style: TextStyle(fontSize: 12, color: GlassColors.textMuted),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        text: AppLocalizations.translate(
                          'Нигоҳ доштан',
                        ),
                        icon: AppIcons.save_rounded,
                        height: 50,
                        enabled: !_busy,
                        onPressed: _save,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassButton(
                        text: AppLocalizations.translate('Санҷиш'),
                        icon: _busy ? null : AppIcons.wifi_find_rounded,
                        outlined: true,
                        height: 50,
                        enabled: !_busy,
                        isLoading: _busy,
                        onPressed: _testConnection,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _busy ? null : _reset,
                    icon: const Icon(AppIcons.restart_alt_rounded, size: 18),
                    label: Text(
                      AppLocalizations.translate(
                        'Ба пешфарз баргардонидан',
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: GlassColors.accentSky,
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

  Widget _buildCurrentCard() {
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.translate('Суроғаи ҷорӣ'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: GlassColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentUrl.isEmpty ? '-' : _currentUrl,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: GlassColors.accentSky,
            ),
          ),
        ],
      ),
    );
  }
}
