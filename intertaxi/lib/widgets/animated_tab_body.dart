import 'package:flutter/material.dart';

/// Keeps tab subtrees mounted while sliding the old and new pages horizontally
/// according to their tab order.
class AnimatedTabBody extends StatefulWidget {
  const AnimatedTabBody({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 200),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<AnimatedTabBody> createState() => _AnimatedTabBodyState();
}

class _AnimatedTabBodyState extends State<AnimatedTabBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..value = 1;
  late int _previousIndex = widget.index;

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
  void didUpdateWidget(covariant AnimatedTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.index != widget.index) {
      _previousIndex = oldWidget.index;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _controller.value = 1;
        _previousIndex = widget.index;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return IndexedStack(index: widget.index, children: widget.children);
    }

    final direction = widget.index >= _previousIndex ? 1.0 : -1.0;
    final progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
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
    final isPrevious = index == _previousIndex && !isCurrent;
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
