import 'package:flutter/material.dart';
import '../../core/models/task.dart';

class TaskListTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final bool isDraggable;
  final bool isHighlighted;
  final bool isDragging;

  const TaskListTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onComplete,
    this.isDraggable = false,
    this.isHighlighted = false,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: isHighlighted 
          ? Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            )
          : null,
        boxShadow: [
          if (isHighlighted || isDragging)
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: isDragging ? 8 : 4,
              spreadRadius: isDragging ? 2 : 1,
              offset: isDragging ? const Offset(0, 4) : const Offset(0, 2),
            ),
        ],
      ),
      child: ListTile(
        // Removed the leading icon since it's now handled by the drag handle overlay
        contentPadding: isDraggable 
            ? const EdgeInsets.only(left: 48, right: 16)  // Space for drag handle
            : null,
        title: Text(
          task.name,
          style: TextStyle(
            decoration: task.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: _buildSubtitle(context),
        trailing: IconButton(
          icon: Icon(
            task.completed ? Icons.check_circle : Icons.circle_outlined,
            color: task.priorityColor,
          ),
          onPressed: onComplete,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    if (task.dueDate == null && task.project == null) {
      return const SizedBox.shrink();
    }

    return Text(
      [
        if (task.project != null) task.project,
        if (task.dueDate != null) 'Due: ${_formatDate(task.dueDate!)}',
      ].join(' • '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';

    return '${date.month}/${date.day}/${date.year}';
  }
}