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
    final theme = Theme.of(context);
    final isCompleted = task.status.isCompleted;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        task.name,
        style: theme.textTheme.titleMedium?.copyWith(
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          color: isCompleted ? Colors.grey : null,
        ),
      ),
      subtitle: _buildSubtitle(context),
      trailing: IconButton(
        icon: Icon(
          isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: task.statusColor,
        ),
        onPressed: onComplete,
      ),
      onTap: onTap,
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
        color: task.status.isCompleted ? 
            Colors.grey : 
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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