import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/task.dart';
import '../../core/services/task_service.dart';

class TaskList extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task) onTaskComplete;
  final bool showCompleted;

  const TaskList({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskComplete,
    this.showCompleted = false,
  });

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
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
          itemCount: filteredTasks.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final task = filteredTasks[index];
            
            // Make each task draggable
            return Draggable<int>(
              // Pass the index as data
              data: index,
              
              // What the user sees while dragging
              feedback: Material(
                elevation: 8.0,
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  child: ListTile(
                    leading: const Icon(Icons.drag_indicator, color: Colors.grey),
                    title: Text(
                      task.name,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              
              // What appears in the original location while dragging
              childWhenDragging: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(
                    task.name,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              
              // The normal task display
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drag_indicator, color: Colors.grey),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          task.status == TaskStatus.completed ? Icons.check_circle : Icons.circle_outlined,
                          color: task.statusColor,
                        ),
                        onPressed: () => widget.onTaskComplete(task),
                      ),
                    ],
                  ),
                  title: Text(
                    task.name,
                    style: TextStyle(
                      decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: _buildSubtitle(context, task),
                  trailing: task.isOverdue && task.status == TaskStatus.todo
                      ? const Icon(Icons.warning, color: Colors.red)
                      : null,
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
    final List<String> subtitleParts = [];
    
    if (task.project != null) {
      subtitleParts.add(task.project!);
    }
    
    if (task.dueDate != null) {
      subtitleParts.add('Due: ${_formatDate(task.dueDate!)}');
    }

    if (task.duration.inMinutes > 0) {
      subtitleParts.add('${task.duration.inMinutes}min');
    }

    if (subtitleParts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      subtitleParts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    }

    return '${date.month}/${date.day}/${date.year}';
  }
}