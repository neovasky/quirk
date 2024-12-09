// enhanced_task_interface.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/task.dart';
import '../../core/services/task_service.dart';

class EnhancedTaskInterface extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task) onTaskComplete;

  const EnhancedTaskInterface({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskComplete,
  });

  @override
  State<EnhancedTaskInterface> createState() => _EnhancedTaskInterfaceState();
}

class _EnhancedTaskInterfaceState extends State<EnhancedTaskInterface> {
  String? _selectedTaskId;

  @override
  Widget build(BuildContext context) {
    // Filter out hidden tasks
    final visibleTasks = widget.tasks
        .where((task) => task.status != TaskStatus.completedHidden)
        .toList();

    if (visibleTasks.isEmpty) {
      return const Center(
        child: Text('No tasks'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visibleTasks.length,
      itemBuilder: (context, index) {
        final task = visibleTasks[index];
        final isSelected = _selectedTaskId == task.id;
        
        return Draggable<Task>(
          data: task,
          feedback: _buildTaskCard(task, isSelected, true),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _buildTaskCard(task, isSelected, false),
          ),
          child: DragTarget<Task>(
            onWillAcceptWithDetails: (details) => details.data != task,
            onAcceptWithDetails: (details) {
              final taskService = context.read<TaskService>();
              final fromIndex = widget.tasks.indexWhere((t) => t.id == details.data.id);
              final toIndex = widget.tasks.indexWhere((t) => t.id == task.id);
              
              if (fromIndex != -1 && toIndex != -1) {
                taskService.reorderTasks(fromIndex, toIndex);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return _buildTaskCard(task, isSelected, false, 
                isDropTarget: candidateData.isNotEmpty);
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(Task task, bool isSelected, bool isDragging, {bool isDropTarget = false}) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDragging ? 8 : isSelected ? 2 : 1,
      color: task.isOverdue && !task.status.isCompleted
          ? Colors.red.withOpacity(0.1)
          : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDropTarget
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() => _selectedTaskId = isSelected ? null : task.id);
          widget.onTaskTap(task);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.name,
                            style: TextStyle(
                              fontSize: 16,
                              decoration: task.status.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.status.isCompleted ? Colors.grey : null,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            task.status.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                            color: task.statusColor,
                          ),
                          onPressed: () => widget.onTaskComplete(task),
                        ),
                      ],
                    ),
                    if (task.project != null || task.dueDate != null)
                      const SizedBox(height: 8),
                    if (task.project != null)
                      _buildTag(Icons.folder, task.project!),
                    if (task.dueDate != null)
                      _buildTag(Icons.event_outlined, _formatDate(task.dueDate!)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8, top: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
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