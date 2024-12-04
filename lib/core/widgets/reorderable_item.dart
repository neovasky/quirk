import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReorderableItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onReorderStart;
  final ValueChanged<double> onReorderUpdate;
  final VoidCallback onReorderEnd;
  final bool enabled;

  const ReorderableItem({
    super.key,
    required this.child,
    required this.onReorderStart,
    required this.onReorderUpdate,
    required this.onReorderEnd,
    this.enabled = true,
  });

  @override
  State<ReorderableItem> createState() => _ReorderableItemState();
}

class _ReorderableItemState extends State<ReorderableItem> {
  bool isDragging = false;
  Offset dragOffset = Offset.zero;
  double startY = 0;

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      isDragging = true;
      startY = details.globalPosition.dy;
    });
    HapticFeedback.mediumImpact();
    widget.onReorderStart();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      dragOffset = Offset(0, details.globalPosition.dy - startY);
    });
    widget.onReorderUpdate(dragOffset.dy);
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      isDragging = false;
      dragOffset = Offset.zero;
    });
    widget.onReorderEnd();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.enabled ? _handleDragStart : null,
      onPanUpdate: widget.enabled ? _handleDragUpdate : null,
      onPanEnd: widget.enabled ? _handleDragEnd : null,
      child: Transform.translate(
        offset: dragOffset,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            boxShadow: isDragging
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}