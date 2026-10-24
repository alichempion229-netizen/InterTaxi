import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/light_glass_theme.dart';

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
    final safeIndex = currentIndex.clamp(0, items.length - 1);
    final primary = LightGlassColors.primaryBlue;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: primary.withValues(alpha: .08)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _AppNavButton(
                    item: items[index],
                    selected: index == safeIndex,
                    primary: primary,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(index);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppNavButton extends StatelessWidget {
  final AppNavItem item;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _AppNavButton({
    required this.item,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? primary : LightGlassColors.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: onTap,
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: selected ? 52 : 32,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? primary : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: .30),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : const [],
                  ),
                  child: Icon(
                    selected ? (item.selectedIcon ?? item.icon) : item.icon,
                    size: 26,
                    color: selected ? Colors.white : color,
                  ),
                ),
                SizedBox(
                  height: 14,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 3,
                  decoration: BoxDecoration(
                    color: selected ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
