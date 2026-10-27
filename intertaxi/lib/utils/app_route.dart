import 'package:flutter/material.dart';

/// Shared route transitions for all full-screen pages.
abstract final class AppRoute {
  static const Duration _transitionDuration = Duration(milliseconds: 280);
  static const Duration _reverseTransitionDuration = Duration(milliseconds: 200);
  static const Curve _fadeCurve = Curves.easeOut;
  static const Curve _scaleCurve = Curves.easeOutCubic;
  static const double _outgoingOpacity = 0.85;

  static Future<T?> push<T>(BuildContext context, Widget page) =>
      Navigator.of(context).push<T>(_route<T>(page));

  static Future<T?> pushModal<T>(BuildContext context, Widget page) =>
      Navigator.of(context).push<T>(_route<T>(page, modal: true));

  static Future<T?> replace<T, TO>(
    BuildContext context,
    Widget page, {
    TO? result,
  }) => Navigator.of(context).pushReplacement<T, TO>(
    _route<T>(page),
    result: result,
  );

  static Future<T?> replaceAll<T>(BuildContext context, Widget page) =>
      Navigator.of(context).pushAndRemoveUntil<T>(
        _route<T>(page),
        (_) => false,
      );

  static PageRouteBuilder<T> _route<T>(Widget page, {bool modal = false}) {
    return PageRouteBuilder<T>(
      opaque: true,
      fullscreenDialog: modal,
      transitionDuration: _transitionDuration,
      reverseTransitionDuration: _reverseTransitionDuration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final incomingOpacity = CurvedAnimation(
          parent: animation,
          curve: _fadeCurve,
        );
        final incomingScale = CurvedAnimation(
          parent: animation,
          curve: _scaleCurve,
        );
        final outgoingOpacity = Tween<double>(
          begin: 1,
          end: _outgoingOpacity,
        ).animate(secondaryAnimation);
        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: FadeTransition(
            opacity: outgoingOpacity,
            child: RepaintBoundary(
              child: FadeTransition(
                opacity: incomingOpacity,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1).animate(incomingScale),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
