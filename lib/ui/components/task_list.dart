import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/task.dart';
import '../../core/services/task_service.dart';
import 'task_list_tile.dart';

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
            
            return Draggable<Task>(
              data: task,
              maxSimultaneousDrags: 1,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              feedback: Material(
                elevation: 8.0,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  child: TaskListTile(
                    task: task,
                    onTap: () {},
                    onComplete: () {},
                    isDraggable: true,
                    isDragging: true,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: TaskListTile(
                  task: task,
                  onTap: () {},
                  onComplete: () {},
                  isDraggable: false,
                ),
              ),
              child: DragTarget<Task>(
                onWillAcceptWithDetails: (details) => details.data != task,
                onAcceptWithDetails: (details) {
                  final incomingTask = details.data;
                  final fromIndex = filteredTasks.indexWhere((t) => t.id == incomingTask.id);
                  final toIndex = filteredTasks.indexWhere((t) => t.id == task.id);
                  
                  if (fromIndex != -1 && toIndex != -1) {
                    final fullTaskList = taskService.tasks;
                    final actualFromIndex = fullTaskList.indexWhere((t) => t.id == incomingTask.id);
                    final actualToIndex = fullTaskList.indexWhere((t) => t.id == task.id);
                    taskService.reorderTasks(actualFromIndex, actualToIndex);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return Column(
                    children: [
                      if (candidateData.isNotEmpty)
                        Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Transform.rotate(
                                  angle: 0.0, // No rotation initially
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.rotationZ(0.0)
                                      ..rotateY(3.14159), // Rotate around Y-axis instead
                                    child: const Icon(
                                      Icons.expand_more,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                  CompletionBubble(
                                    isCompleted: task.status == TaskStatus.completed,
                                    // Use priority color instead of status color
                                    color: task.priority.color,  // Make sure TaskPriority enum has color property
                                    onTap: () => widget.onTaskComplete(task),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TaskListTile(
                              task: task,
                              onTap: () => widget.onTaskTap(task),
                              onComplete: () => widget.onTaskComplete(task),
                              isDraggable: false,
                              isHighlighted: candidateData.isNotEmpty,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class CompletionBubble extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 2,
          ),
          color: isCompleted ? color : Colors.transparent,
        ),
        child: isCompleted
            ? const Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}