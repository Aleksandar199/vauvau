import 'package:flutter/material.dart';

class SwipeableStack extends StatefulWidget {
  const SwipeableStack({
    super.key,
    required this.child,
    required this.onLike,
    required this.onPass,
    this.enabled = true,
    this.onTap,
  });

  final Widget child;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<SwipeableStack> createState() => _SwipeableStackState();
}

class _SwipeableStackState extends State<SwipeableStack>
    with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  late final AnimationController _controller;
  Animation<Offset>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_animation != null) {
          setState(() => _offset = _animation!.value);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) {
      return;
    }
    setState(() => _offset += details.delta);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (!widget.enabled) {
      return;
    }
    if (_offset.dx > 120) {
      await _fling(const Offset(500, 0), widget.onLike);
    } else if (_offset.dx < -120) {
      await _fling(const Offset(-500, 0), widget.onPass);
    } else {
      await _fling(Offset.zero, null);
    }
  }

  Future<void> _fling(Offset end, VoidCallback? onDone) async {
    _animation = Tween<Offset>(begin: _offset, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    await _controller.forward(from: 0);
    _controller.reset();
    _animation = null;
    setState(() => _offset = Offset.zero);
    onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final angle = (_offset.dx / 420).clamp(-0.38, 0.38);
    final tilt = (_offset.dy / 640).clamp(-0.14, 0.14);
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(-tilt)
          ..rotateZ(angle)
          ..translateByDouble(_offset.dx, _offset.dy, 0, 1),
        child: widget.child,
      ),
    );
  }
}
