import 'package:flutter/material.dart';
import '../../core/models/task.dart';

class TaskListTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final bool isDraggable;

  const TaskListTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onComplete,
    this.isDraggable = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDraggable)
            const ReorderableDragStartListener(
              index: -1,
              child: Icon(Icons.drag_handle),
            ),
          InkWell(
            onTap: onComplete,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: task.completed ? task.priorityColor : Colors.transparent,
                border: Border.all(
                  color: task.priorityColor,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: task.completed
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
      title: Text(
        task.name,
        style: TextStyle(
          decoration: task.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration and project info
          Text(
            'Duration: ${task.duration.inMinutes} min'
            '${task.project != null ? ' • ${task.project}' : ''}'
            '${task.dueDate != null ? ' • Due: ${task.dueDate.toString().split(' ')[0]}' : ''}',
          ),
          // Labels
          if (task.labels.isNotEmpty)
            Wrap(
              spacing: 4,
              children: task.labels.map((label) => Chip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                label: Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              )).toList(),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}