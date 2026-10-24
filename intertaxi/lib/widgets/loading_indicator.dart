import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/glass_theme.dart';

/// InterTaxi Premium Loading Indicator (glassmorphism)
/// РњРёРЅРёРјР°Р»РёСЃС‚УЈ: С‚СЂРµРєРё СЃР°С„РµРґРё С€Р°С„С„РѕС„ + Р°РєСЃРµРЅС‚Рё РєР°Р±СѓРґРё СЂР°РІС€Р°РЅ
class InterTaxiLoadingIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color color;

  const InterTaxiLoadingIndicator({
    super.key,
    this.size = AppConstants.loadingIndicatorSize,
    this.strokeWidth = AppConstants.loadingStrokeWidth,
    this.color = GlassColors.accentSky,
  });

  @override
  State<InterTaxiLoadingIndicator> createState() =>
      _InterTaxiLoadingIndicatorState();
}

class _InterTaxiLoadingIndicatorState extends State<InterTaxiLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.loadingIndicatorDuration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppConstants.loadingCurve,
      ),
    );

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CircularProgressIndicator(
            strokeWidth: widget.strokeWidth,
            value: _animation.value,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
          );
        },
      ),
    );
  }
}
