import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const AppNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

class AppBottomNav extends StatelessWidget {
  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final safeIndex = currentIndex.clamp(0, items.length - 1).toInt();
    const panelHeight = 76.0;
    const iconAreaHeight = 44.0;
    const labelGap = 2.0;
    const labelHeight = 15.0;
    final circleSize = items.length <= 4 ? 44.0 : 40.0;
    final iconSize = items.length <= 4 ? 24.0 : 22.0;
    final circleTop =
        (panelHeight - iconAreaHeight - labelGap - labelHeight) / 2 +
        (iconAreaHeight - circleSize) / 2;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        child: Container(
          height: panelHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFEAF3FF)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF3B82F6),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x403B82F6),
                blurRadius: 18,
                offset: Offset(0, 0),
              ),
              BoxShadow(
                color: Color(0x1F3B82F6),
                blurRadius: 30,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: slotWidth * safeIndex + (slotWidth - circleSize) / 2,
                    top: circleTop,
                    width: circleSize,
                    height: circleSize,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF1E5BFF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x661E5BFF),
                            blurRadius: 14,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var index = 0; index < items.length; index++)
                        Expanded(
                          child: _AppNavButton(
                            item: items[index],
                            selected: index == safeIndex,
                            panelHeight: panelHeight,
                            iconAreaHeight: iconAreaHeight,
                            labelGap: labelGap,
                            iconSize: iconSize,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onTap(index);
                            },
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
    );
  }
}

class _AppNavButton extends StatelessWidget {
  final AppNavItem item;
  final bool selected;
  final double panelHeight;
  final double iconAreaHeight;
  final double labelGap;
  final double iconSize;
  final VoidCallback onTap;

  const _AppNavButton({
    required this.item,
    required this.selected,
    required this.panelHeight,
    required this.iconAreaHeight,
    required this.labelGap,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : const Color(0xFF6F86B5);
    final labelColor = selected
        ? const Color(0xFF1E5BFF)
        : const Color(0xFF6F86B5);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              height: panelHeight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: iconAreaHeight,
                      child: Center(
                        child: TweenAnimationBuilder<Color?>(
                          tween: ColorTween(end: iconColor),
                          duration: const Duration(milliseconds: 160),
                          builder: (context, animatedColor, _) => Icon(
                            selected ? (item.selectedIcon ?? item.icon) : item.icon,
                            size: iconSize,
                            color: animatedColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: labelGap),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: TweenAnimationBuilder<Color?>(
                        tween: ColorTween(end: labelColor),
                        duration: const Duration(milliseconds: 160),
                        builder: (context, animatedColor, _) => Text(
                          item.label,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: animatedColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
