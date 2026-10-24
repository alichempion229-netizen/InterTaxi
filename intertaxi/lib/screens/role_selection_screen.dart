import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/app_route.dart';
import 'socket_driver_screen.dart';
import 'socket_passenger_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum UserRole { passenger, driver }

class RoleSelectionScreen extends StatefulWidget {
  final String passengerName;
  final String passengerPhone;
  final Future<void> Function(UserRole role)? onContinue;
  final Widget Function(UserRole role)? destinationBuilder;

  const RoleSelectionScreen({
    super.key,
    required this.passengerName,
    required this.passengerPhone,
    this.onContinue,
    this.destinationBuilder,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;
  bool _isLoading = false;

  void _select(UserRole role) {
    unawaited(HapticFeedback.selectionClick());
    if (_selectedRole == role) return;
    setState(() => _selectedRole = role);
  }

  Future<void> _continue() async {
    final role = _selectedRole;
    if (role == null || _isLoading) return;
    setState(() => _isLoading = true);
    if (kDebugMode) debugPrint('[RoleSelection] Continue tapped: $role');
    try {
      final onContinue = widget.onContinue;
      if (onContinue != null) {
        if (kDebugMode) debugPrint('[RoleSelection] Role save started');
        await onContinue(role).timeout(const Duration(seconds: 15));
        if (!mounted) return;
        if (kDebugMode) debugPrint('[RoleSelection] Role save completed');
      }

      if (!mounted) return;
      final page = widget.destinationBuilder?.call(role) ??
          (role == UserRole.passenger
              ? SocketPassengerScreen(
                  passengerName: widget.passengerName,
                  passengerPhone: widget.passengerPhone,
                )
              : SocketDriverScreen(
                  driverName: widget.passengerName,
                  driverPhone: widget.passengerPhone,
                  driverCar: 'Toyota Camry (White)',
                ));
      if (kDebugMode) debugPrint('[RoleSelection] Navigating to $role');
      AppRoute.replace<void, void>(context, page);
    } on TimeoutException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[RoleSelection] Role save timed out: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (mounted) _showContinueError('Вақт тамом шуд. Лутфан аз нав кӯшиш кунед.');
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[RoleSelection] Continue failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (mounted) _showContinueError('Хато рӯй дод. Лутфан аз нав кӯшиш кунед.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showContinueError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Шумо кистед?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF142033),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        asset: 'assets/passenger2.png',
                        title: 'Мусофир',
                        subtitle: 'Сафар ёбед ва чой банд кунед',
                        icon: Icons.luggage_rounded,
                        selected: _selectedRole == UserRole.passenger,
                        onTap: () => _select(UserRole.passenger),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _RoleCard(
                        asset: 'assets/driver1.png',
                        title: 'Ронанда',
                        subtitle: 'Сафар эълон кунед, мусофир гиред',
                        icon: Icons.local_taxi_rounded,
                        selected: _selectedRole == UserRole.driver,
                        onTap: () => _select(UserRole.driver),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ContinueButton(
                enabled: _selectedRole != null && !_isLoading,
                loading: _isLoading,
                onTap: _continue,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

const double kPad = 8;
const double kCardRadius = 24;
const double kInfoH = 60;

class _RoleCard extends StatelessWidget {
  final String asset;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.02 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(kPad),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kCardRadius),
            border: Border.all(
              color: selected ? const Color(0xFF2563EB) : Colors.transparent,
              width: selected ? 2.5 : 2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 10,
                    ),
                  ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(kCardRadius - kPad),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(asset, fit: BoxFit.cover),
                      if (!selected)
                        ColoredBox(color: Colors.white.withOpacity(.12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: kInfoH,
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected ? null : const Color(0xFFEAF1FF),
                        gradient: selected
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF3B82F6),
                                  Color(0xFF2563EB),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2563EB)
                                      .withOpacity(.22),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : const [],
                      ),
                      child: Icon(
                        icon,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F1B3D),
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? const Color(0xFF2563EB)
                            : Colors.transparent,
                        border: selected
                            ? null
                            : Border.all(
                                color: const Color(0xFFC7CEDB),
                                width: 2,
                              ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOutBack,
                        child: selected
                            ? const Icon(
                                Icons.check,
                                key: ValueKey('selected'),
                                color: Colors.white,
                                size: 19,
                              )
                            : const SizedBox(
                                key: ValueKey('unselected'),
                                width: 28,
                                height: 28,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : .48,
      duration: const Duration(milliseconds: 250),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1769E0), Color(0xFF4387F0)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x33256DDA),
                    blurRadius: 20,
                    offset: Offset(0, 9),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: enabled ? onTap : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Идома додан',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .15,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
