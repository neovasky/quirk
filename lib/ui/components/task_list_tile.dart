import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/task.dart';

class TaskListTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final bool isDraggable;
  final bool isDragging;
  final bool isHighlighted;

  const TaskListTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onComplete,
    this.isDraggable = false,
    this.isDragging = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted 
          ? Border.all(color: theme.colorScheme.primary.withOpacity(0.5))
          : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
          child: Row(
            children: [
              CompletionBubble(
                isCompleted: task.completed,
                color: task.priorityColor,
                onTap: onComplete,
              ),
              const SizedBox(width: 16),
              // Task details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Task name
                        Expanded(
                          child: Text(
                            task.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              decoration: task.completed ? TextDecoration.lineThrough : null,
                              color: task.completed ? theme.colorScheme.onSurface.withOpacity(0.6) : null,
                            ),
                          ),
                        ),
                        // More options button
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onPressed: onTap,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    if (task.project != null || task.duration.inMinutes > 0 || task.dueDate != null)
                      const SizedBox(height: 4),
                    // Metadata row
                    Wrap(
                      spacing: 12,
                      children: [
                        if (task.project != null)
                          _buildMetadata(
                            icon: Icons.folder_outlined,
                            label: task.project!,
                          ),
                        if (task.duration.inMinutes > 0)
                          _buildMetadata(
                            icon: Icons.timer_outlined,
                            label: '${task.duration.inMinutes}m',
                          ),
                        if (task.dueDate != null)
                          _buildMetadata(
                            icon: Icons.calendar_today_outlined,
                            label: _formatDate(task.dueDate!),
                            isOverdue: task.isOverdue,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata({
    required IconData icon,
    required String label,
    bool isOverdue = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isOverdue ? Colors.red[300] : Colors.grey[400],
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isOverdue ? Colors.red[300] : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';

    return '${date.month}/${date.day}';
  }
}

class CompletionBubble extends StatefulWidget {
  final bool isCompleted;
  final Color color;
  final VoidCallback onTap;

  const CompletionBubble({
    super.key,
    required this.isCompleted,
    required this.color,
    required this.onTap,
  });

  @override
  State<CompletionBubble> createState() => _CompletionBubbleState();
}

class _CompletionBubbleState extends State<CompletionBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
        reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    if (widget.isCompleted) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CompletionBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted) {
      if (widget.isCompleted) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    return GestureDetector(
      onTap: () {
        widget.onTap();
        HapticFeedback.lightImpact();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: widget.isCompleted ? widget.color : null,
                border: Border.all(
                  color: widget.color,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: widget.isCompleted ? Center(
                child: ScaleTransition(
                  scale: _checkAnimation,
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ) : null,
            ),
          );
        },
      ),
    );
  }
}