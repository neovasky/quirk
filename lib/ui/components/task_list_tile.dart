import 'package:flutter/material.dart';
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Completion Bubble
                    GestureDetector(
                      onTap: onComplete,
                      child: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 16, top: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: task.priorityColor,
                            width: 2,
                          ),
                          color: task.completed ? task.priorityColor : Colors.transparent,
                        ),
                        child: task.completed
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    // Task Title
                    Expanded(
                      child: Text(
                        task.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: task.completed 
                              ? Colors.grey 
                              : Colors.white,
                          decoration: task.completed 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                    ),
                    // Menu Button
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: onTap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Metadata Row
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (task.project != null)
                        _buildMetadataChip(
                          icon: Icons.label_outline,
                          label: task.project!,
                        ),
                      if (task.duration.inMinutes > 0)
                        _buildMetadataChip(
                          icon: Icons.timer_outlined,
                          label: '${task.duration.inMinutes}m',
                        ),
                      if (task.dueDate != null)
                        _buildMetadataChip(
                          icon: Icons.calendar_today_outlined,
                          label: _formatDate(task.dueDate!),
                          isOverdue: task.isOverdue,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    bool isOverdue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isOverdue ? Colors.red[300] : Colors.grey[400],
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isOverdue ? Colors.red[300] : Colors.grey[400],
            ),
          ),
        ],
      ),
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