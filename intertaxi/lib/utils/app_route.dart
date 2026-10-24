import 'package:flutter/material.dart';

/// Shared route transitions for all full-screen pages.
abstract final class AppRoute {
  static const Duration _duration = Duration(milliseconds: 200);

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
      fullscreenDialog: modal,
      transitionDuration: _duration,
      reverseTransitionDuration: _duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeOutWhenCovered = Tween<double>(begin: 1, end: 0).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeIn,
            reverseCurve: Curves.easeOut,
          ),
        );
        if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
          return FadeTransition(
            opacity: animation,
            child: FadeTransition(
              opacity: fadeOutWhenCovered,
              child: child,
            ),
          );
        }
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );
        if (modal) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        }
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: FadeTransition(
              opacity: fadeOutWhenCovered,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
