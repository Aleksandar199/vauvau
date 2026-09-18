import 'package:flutter/material.dart';

class TiltOnDrag extends StatefulWidget {
  const TiltOnDrag({
    super.key,
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<TiltOnDrag> createState() => _TiltOnDragState();
}

class _TiltOnDragState extends State<TiltOnDrag>
    with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  late final AnimationController _controller;
  Animation<Offset>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
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
    setState(() => _offset += details.delta);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    _animation = Tween<Offset>(begin: _offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    await _controller.forward(from: 0);
    _controller.reset();
    _animation = null;
    if (mounted) {
      setState(() => _offset = Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final angle = (_offset.dx / 420).clamp(-0.35, 0.35);
    final tilt = (_offset.dy / 700).clamp(-0.16, 0.16);
    return GestureDetector(
      onTap: widget.onTap,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateX(-tilt)
          ..rotateZ(angle)
          ..translateByDouble(_offset.dx * 0.35, _offset.dy * 0.2, 0, 1),
        child: widget.child,
      ),
    );
  }
}
