import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/task.dart';
import '../../core/services/task_service.dart';

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
  @override
  Widget build(BuildContext context) {
    return Consumer<TaskService>(
      builder: (context, taskService, child) {
        final filteredTasks = widget.showCompleted
            ? widget.tasks.where((task) => task.status == TaskStatus.completed).toList()
            : widget.tasks.where((task) => task.status != TaskStatus.completed).toList();

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
            final dragKey = ValueKey('drag_${task.id}');
            final targetKey = ValueKey('target_${task.id}');
            
            return Draggable<int>(
              key: dragKey,
              data: index,
              feedback: Material(
                elevation: 6.0,
                child: Container(
                  width: MediaQuery.of(context).size.width - 32,
                  color: Theme.of(context).colorScheme.surface,
                  child: ListTile(
                    leading: const Icon(Icons.drag_indicator, color: Colors.grey),
                    title: Text(task.name),
                  ),
                ),
              ),
              child: DragTarget<int>(
                key: targetKey,
                onWillAcceptWithDetails: (details) {
                  return details.data != index;
                },
                onAcceptWithDetails: (details) {
                  final oldIndex = details.data;
                  final newIndex = index;
                  taskService.reorderTasks(oldIndex, newIndex);
                },
                builder: (context, candidateData, rejectedData) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: candidateData.isNotEmpty ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ] : null,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.drag_indicator, color: Colors.grey),
                    title: Text(
                      task.name,
                      style: TextStyle(
                        decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: _buildSubtitle(context, task),
                    trailing: IconButton(
                      icon: Icon(
                        task.status == TaskStatus.completed ? Icons.check_circle : Icons.circle_outlined,
                        color: task.statusColor,
                      ),
                      onPressed: () => widget.onTaskComplete(task),
                    ),
                    onTap: () => widget.onTaskTap(task),
                  ),
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
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';

    return '${date.month}/${date.day}/${date.year}';
  }
}