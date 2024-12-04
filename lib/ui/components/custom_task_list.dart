import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/task.dart';
import '../../core/services/task_service.dart';
import '../../core/widgets/reorderable_item.dart';

class CustomTaskList extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task) onTaskComplete;
  final bool showCompleted;

  const CustomTaskList({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskComplete,
    this.showCompleted = false,
  });

  @override
  State<CustomTaskList> createState() => _CustomTaskListState();
}

class _CustomTaskListState extends State<CustomTaskList> {
  Task? draggedTask;
  double dragOffset = 0;
  int? draggedIndex;

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskService>(
      builder: (context, taskService, child) {
        final filteredTasks = widget.showCompleted
            ? widget.tasks.where((task) => task.completed).toList()
            : widget.tasks.where((task) => !task.completed).toList();

        if (filteredTasks.isEmpty) {
          return Center(
            child: Text(
              widget.showCompleted ? 'No completed tasks' : 'No pending tasks',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];
            final isBeingDragged = draggedTask?.id == task.id;
            
            return ReorderableItem(
              key: ValueKey(task.id),
              enabled: true,
              onReorderStart: () {
                setState(() {
                  draggedTask = task;
                  draggedIndex = index;
                });
              },
              onReorderUpdate: (offset) {
                setState(() {
                  dragOffset = offset;
                  // Calculate new position
                  final newIndex = ((dragOffset) / 72).round() + draggedIndex!;
                  if (newIndex != draggedIndex && 
                      newIndex >= 0 && 
                      newIndex < filteredTasks.length) {
                    final mainOldIndex = taskService.tasks.indexOf(task);
                    final targetTask = filteredTasks[newIndex];
                    final mainNewIndex = taskService.tasks.indexOf(targetTask);
                    taskService.reorderTasks(mainOldIndex, mainNewIndex);
                    draggedIndex = newIndex;
                  }
                });
              },
              onReorderEnd: () {
                setState(() {
                  draggedTask = null;
                  dragOffset = 0;
                  draggedIndex = null;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isBeingDragged
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: const MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Icon(
                      Icons.drag_indicator,
                      color: Colors.grey,
                    ),
                  ),
                  title: Text(
                    task.name,
                    style: TextStyle(
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: _buildSubtitle(context, task),
                  trailing: IconButton(
                    icon: Icon(
                      task.completed ? Icons.check_circle : Icons.circle_outlined,
                      color: task.priorityColor,
                    ),
                    onPressed: () => widget.onTaskComplete(task),
                  ),
                  onTap: () => widget.onTaskTap(task),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubtitle(BuildContext context, Task task) {
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
    final yesterday = now.subtract(const Duration(days: 1));
    final tomorrow = now.add(const Duration(days: 1));

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }

    return '${date.month}/${date.day}';
  }
}