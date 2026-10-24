import 'package:flutter/material.dart';
import 'package:intertaxi/l10n/app_localizations.dart';

/// Compact glass-friendly navigation with one shared animation system for all
/// destinations. The bar owns only its button animations; tab content remains
/// managed by its parent.
class AnimatedBottomNavigation extends StatelessWidget {
  const AnimatedBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    this.backgroundColor = const Color(0xFF1769E0),
    this.indicatorColor,
  });

  final List<AnimatedNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final Color backgroundColor;
  final Color? indicatorColor;

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, items.length - 1);
    final cardColor = backgroundColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330C2344),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Material(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: SizedBox(
                height: 62,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth / items.length;
                    return Stack(
                      children: [
                        _AnimatedNavigationIndicator(
                          index: safeIndex,
                          cellWidth: width,
                          color: indicatorColor ?? selectedColor,
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
        ),
      ),
    );
  }
}

class _AnimatedNavigationIndicator extends StatelessWidget {
  const _AnimatedNavigationIndicator({
    required this.index,
    required this.cellWidth,
    required this.color,
  });

  final int index;
  final double cellWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final indicatorWidth = cellWidth - 8;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: cellWidth * index + 4,
      top: 2,
      width: indicatorWidth,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(17),
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

/// Keeps tab subtrees mounted while animating only the outgoing and incoming
/// tabs, so maps, forms, and scroll positions keep their existing state.
class AnimatedTabStack extends StatefulWidget {
  const AnimatedTabStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 175),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<AnimatedTabStack> createState() => _AnimatedTabStackState();
}

class _AnimatedTabStackState extends State<AnimatedTabStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..value = 1;
  late int _previousIndex = widget.index;

  @override
  void didUpdateWidget(covariant AnimatedTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.index != widget.index) {
      _previousIndex = oldWidget.index;
      _controller.forward(from: 0);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          _previousIndex != widget.index) {
        setState(() => _previousIndex = widget.index);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final direction = widget.index >= _previousIndex ? 1.0 : -1.0;
    final progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var index = 0; index < widget.children.length; index++)
          _buildTab(index, progress, direction),
      ],
    );
  }

  Widget _buildTab(int index, Animation<double> progress, double direction) {
    final isCurrent = index == widget.index;
    final isPrevious =
        index == _previousIndex && _previousIndex != widget.index;
    final isVisible = isCurrent || isPrevious;
    final Animation<double> opacity = isCurrent
        ? progress
        : ReverseAnimation(progress);
    final slide = isCurrent
        ? Tween<Offset>(
            begin: Offset(.008 * direction, 0),
            end: Offset.zero,
          ).animate(progress)
        : Tween<Offset>(
            begin: Offset.zero,
            end: Offset(-.004 * direction, 0),
          ).animate(progress);

    return Offstage(
      offstage: !isVisible,
      child: TickerMode(
        enabled: isVisible,
        child: IgnorePointer(
          ignoring: !isCurrent,
          child: FadeTransition(
            opacity: opacity,
            child: SlideTransition(
              position: slide,
              child: widget.children[index],
            ),
          ),
        ),
      ),
    );
  }
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
  static const _duration = Duration(milliseconds: 225);
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
          splashColor: widget.selectedColor.withValues(alpha: .10),
          highlightColor: widget.selectedColor.withValues(alpha: .04),
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
                    scale: widget.selected ? 1.1 : 1,
                    duration: _iconSizeDuration,
                    curve: _curve,
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: color),
                      duration: _duration,
                      curve: _curve,
                      builder: (context, animatedColor, _) => Icon(
                        widget.item.icon,
                        size: 23,
                        color: animatedColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: _duration,
                    curve: _curve,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
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
