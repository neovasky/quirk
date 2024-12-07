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
    if (widget.tasks.isEmpty) {
      return const Center(
        child: Text('No tasks'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.tasks.length,
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
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
    final isCompleted = task.status == TaskStatus.completed;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDragging ? 8 : isSelected ? 2 : 1,
      color: task.isOverdue && task.status != TaskStatus.completed
          ? Colors.red.withOpacity(0.1)
          : theme.colorScheme.surface,
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
              // Title and completion button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority indicator and completion button combined
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    icon: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.statusColor,
                          width: 2,
                        ),
                      ),
                      child: task.status == TaskStatus.completed
                          ? Icon(Icons.check, size: 18, color: task.statusColor)
                          : null,
                    ),
                    onPressed: () => widget.onTaskComplete(task),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.name,
                      style: TextStyle(
                        fontSize: 18,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? Colors.grey : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {}, // Add menu options here
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tags and metadata
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (task.project != null)
                    _buildTag(Icons.label_outline, task.project!),
                  ...task.labels.map((label) => _buildTag(Icons.label_outline, label)),
                  if (task.duration.inMinutes > 0)
                    _buildTag(Icons.timer_outlined, '${task.duration.inMinutes}m'),
                  if (task.dueDate != null)
                    _buildTag(Icons.event_outlined, _formatDate(task.dueDate!)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
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

    return '${date.month}/${date.day}/${date.year}';
  }
}