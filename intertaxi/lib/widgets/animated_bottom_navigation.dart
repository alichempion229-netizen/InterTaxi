import 'package:flutter/material.dart';
import 'package:intertaxi/l10n/app_localizations.dart';

/// Floating ceramic navigation pill shared by the passenger and driver flows.
class AnimatedBottomNavigation extends StatelessWidget {
  const AnimatedBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    this.backgroundColor = Colors.white,
    this.indicatorColor,
    this.horizontalPadding = 16,
    this.indicatorWidthFactor = .68,
  });

  final List<AnimatedNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final Color backgroundColor;
  final Color? indicatorColor;
  final double horizontalPadding;
  final double indicatorWidthFactor;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final safeIndex = currentIndex.clamp(0, items.length - 1);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        8,
        horizontalPadding,
        10,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE8EEF6), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x180C2344),
              blurRadius: 22,
              offset: Offset(0, 9),
            ),
            BoxShadow(
              color: Color(0xBFFFFFFF),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: SizedBox(
            height: 72,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth / items.length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _AnimatedNavigationIndicator(
                      index: safeIndex,
                      cellWidth: width,
                      widthFactor: indicatorWidthFactor,
                      color: indicatorColor ?? const Color(0xFF2563EB),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _NavigationButton(
                              item: items[i],
                              selected: i == safeIndex,
                              selectedColor: selectedColor,
                              unselectedColor: unselectedColor,
                              onTap: () => onTap(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavigationIndicator extends StatelessWidget {
  const _AnimatedNavigationIndicator({
    required this.index,
    required this.cellWidth,
    required this.widthFactor,
    required this.color,
  });

  final int index;
  final double cellWidth;
  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final indicatorWidth = cellWidth * widthFactor;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: cellWidth * index + (cellWidth - indicatorWidth) / 2,
      top: 9,
      width: indicatorWidth,
      height: 54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .24),
              blurRadius: 9,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedNavigationItem {
  const AnimatedNavigationItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _NavigationButton extends StatefulWidget {
  const _NavigationButton({
    required this.item,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final AnimatedNavigationItem item;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  State<_NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<_NavigationButton> {
  bool _pressed = false;
  static const _duration = Duration(milliseconds: 190);
  static const _iconSizeDuration = Duration(milliseconds: 200);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? widget.selectedColor
        : widget.unselectedColor;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: AppLocalizations.translate(widget.item.label),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: .16),
          highlightColor: Colors.white.withValues(alpha: .08),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? .94 : 1,
            duration: const Duration(milliseconds: 140),
            curve: _curve,
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: widget.selected ? 1.08 : 1,
                    duration: _iconSizeDuration,
                    curve: _curve,
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: color),
                      duration: _duration,
                      curve: _curve,
                      builder: (context, animatedColor, _) => Icon(
                        widget.item.icon,
                        size: 26,
                        color: animatedColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: _duration,
                    curve: _curve,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: widget.selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    child: Text(
                      AppLocalizations.translate(widget.item.label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
