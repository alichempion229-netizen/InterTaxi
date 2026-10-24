import 'dart:ui';
import 'package:flutter/material.dart';

class FastBlueWhiteGlassCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double? height;
  final EdgeInsetsGeometry padding;

  const FastBlueWhiteGlassCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD6E6FA), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x160D47A1),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
