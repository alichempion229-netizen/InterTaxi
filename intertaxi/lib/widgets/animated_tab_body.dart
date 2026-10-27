import 'package:flutter/material.dart';

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

class _AnimatedTabBodyState extends State<AnimatedTabBody> {
  late final List<Widget> _children = widget.children
      .map((child) => RepaintBoundary(child: child))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: widget.index,
    children: _children,
  );
}
