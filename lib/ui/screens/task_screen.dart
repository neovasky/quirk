import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/task.dart';
import '../../core/services/task_service.dart';
import '../../core/models/task_priority.dart';
import '../components/task_list_tile.dart';
import '../dialogs/add_task_dialog.dart';
import '../dialogs/task_details_dialog.dart';
import '../components/view_menu_overlay.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _viewMenuButtonKey = GlobalKey();
  final ViewMenuController _viewMenuController = ViewMenuController();
  final ValueNotifier<bool> showCompletedTasks = ValueNotifier<bool>(false);
  final ValueNotifier<String> sortBy = ValueNotifier<String>('priority');
  final ValueNotifier<Set<TaskPriority>> selectedPriorities = ValueNotifier<Set<TaskPriority>>({});
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    showCompletedTasks.dispose();
    sortBy.dispose();
    selectedPriorities.dispose();
    super.dispose();
  }

List<Task> _filterTasks(List<Task> tasks) {
    List<Task> filteredTasks = List<Task>.from(tasks);

    // Filter out hidden tasks
    filteredTasks = filteredTasks.where((task) => 
      task.status != TaskStatus.completedHidden
    ).toList();

    // Apply priority filters if any are selected
    if (selectedPriorities.value.isNotEmpty) {
      filteredTasks = filteredTasks.where(
        (task) => selectedPriorities.value.contains(task.priority)
      ).toList();
    }

    // Only sort if not in manual mode AND a sort mode is selected
    if (sortBy.value.toLowerCase() != 'manual') {
      filteredTasks.sort((a, b) {
        // Always put completed tasks at the bottom
        if (a.status.isCompleted && !b.status.isCompleted) return 1;
        if (!a.status.isCompleted && b.status.isCompleted) return -1;

        // Then apply selected sort
        switch (sortBy.value.toLowerCase()) {
          case 'priority':
            // HIGH (0) to LOW (2) order
            return a.priority.index.compareTo(b.priority.index);  // Removed the reverse comparison
          case 'due date':
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          case 'created':
            return b.createdAt.compareTo(a.createdAt);
          default:
            return 0;
        }
      });
    }

    // Apply search filter if text exists
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredTasks = filteredTasks.where((task) {
        final titleMatch = task.name.toLowerCase().contains(query);
        final projectMatch = task.project?.toLowerCase().contains(query) ?? false;
        final notesMatch = task.notes?.toLowerCase().contains(query) ?? false;
        return titleMatch || projectMatch || notesMatch;
      }).toList();
    }

    return filteredTasks;
  }

  Future<void> _handleAddTask(BuildContext context) async {
    final currentContext = context;
    final taskService = currentContext.read<TaskService>();
    
    final task = await showDialog<Task>(
      context: currentContext,
      builder: (context) => const AddTaskDialog(),
    );

    if (!mounted) return;

    if (task != null) {
      taskService.addTask(task);
    }
  }

  Future<void> _handleTaskTap(BuildContext context, Task task, TaskService taskService) async {
    final currentContext = context;
    
    final result = await showDialog<dynamic>(
      context: currentContext,
      builder: (context) => TaskDetailsDialog(task: task),
    );

    if (!mounted) return;

    if (result == 'delete') {
      taskService.deleteTask(task.id);
    } else if (result is Task) {
      taskService.updateTask(result);
    }
  }

  void _handleTaskCompletion(Task task, TaskService taskService) {
    debugPrint('Handling task completion. Current status: ${task.status}');
      
    if (task.status == TaskStatus.completedVisible) {
      debugPrint('Task was visible and completed - changing to todo');
      taskService.updateTask(task.copyWith(status: TaskStatus.todo));
    } else if (!task.status.isCompleted) {
      debugPrint('Task was uncompleted - handling normal completion');
      final showCompleted = showCompletedTasks.value;
      final newStatus = showCompleted ? 
        TaskStatus.completedVisible : 
        TaskStatus.completedHidden;
      taskService.updateTask(task.copyWith(status: newStatus));
    }
  }

void _handleReorder(TaskService taskService, int fromIndex, int toIndex) {
    // Switch to manual sorting mode
    sortBy.value = 'manual';
    
    // Execute the reorder
    taskService.reorderTasks(fromIndex, toIndex);
  }

  void _toggleCompletedTasksVisibility(TaskService taskService, bool showCompleted) {
    final completedTasks = taskService.tasks.where((task) => 
      task.status == TaskStatus.completedVisible || 
      task.status == TaskStatus.completedHidden
    );
    
    for (var task in completedTasks) {
      final newStatus = showCompleted 
        ? TaskStatus.completedVisible 
        : TaskStatus.completedHidden;
          
      if (task.status != newStatus) {
        taskService.updateTask(task.copyWith(status: newStatus));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search tasks...',
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            )
          : const Text('Tasks'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            key: _viewMenuButtonKey,
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _viewMenuController.show(
                context, 
                _viewMenuButtonKey,
                showCompletedTasks: showCompletedTasks,
                sortBy: sortBy,
                selectedPriorities: selectedPriorities,
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskService>(
        builder: (context, taskService, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: showCompletedTasks,
            builder: (context, showCompleted, child) {
              _toggleCompletedTasksVisibility(taskService, showCompleted);
              return ValueListenableBuilder<String>(
                valueListenable: sortBy,
                builder: (context, currentSort, child) {
                  return ValueListenableBuilder<Set<TaskPriority>>(
                    valueListenable: selectedPriorities,
                    builder: (context, priorities, child) {
                      return _TaskList(
                        tasks: _filterTasks(taskService.tasks),
                        onTaskTap: (task) => _handleTaskTap(context, task, taskService),
                        onTaskComplete: (task) => _handleTaskCompletion(task, taskService),
                        onReorder: (from, to) => _handleReorder(taskService, from, to),
                        sortingMode: currentSort,  // Pass the current sort mode
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleAddTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task) onTaskComplete;
  final Function(int, int) onReorder;
  final String sortingMode;

  const _TaskList({
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskComplete,
    required this.onReorder,
    required this.sortingMode,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Draggable<Task>(
          data: task,
          maxSimultaneousDrags: 1,  // Always allow dragging
          dragAnchorStrategy: (draggable, context, position) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            return renderBox.globalToLocal(position);
          },
          feedback: Material(
            elevation: 12.0,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 32,
              child: TaskListTile(
                key: ValueKey('drag_${task.id}'),
                task: task,
                onTap: () {},
                onComplete: () {},
                isDraggable: true,
                isDragging: true,
              ),
            ),
          ),
          childWhenDragging: SizedBox(
            height: 72,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: DragTarget<Task>(
            onWillAcceptWithDetails: (details) => details.data != task,
            onAcceptWithDetails: (details) {
              final taskService = context.read<TaskService>();
              final fromIndex = taskService.tasks.indexWhere((t) => t.id == details.data.id);
              final toIndex = taskService.tasks.indexWhere((t) => t.id == task.id);
              
              if (fromIndex != -1 && toIndex != -1) {
                onReorder(fromIndex, toIndex);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return Row(
                children: [
                  // Replace dots with arrow
                  SizedBox(
                    width: 40,
                    child: Transform.rotate(
                      angle: 3.14159 / 180,  // Slight rotation for the arrow
                      child: const Icon(
                        Icons.chevron_right,  // Arrow icon instead of drag_indicator
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TaskListTile(
                      key: ValueKey('${task.id}_${task.status}'),  
                      task: task,
                      onTap: () => onTaskTap(task),
                      onComplete: () => onTaskComplete(task),
                      isDraggable: true,  // Always allow dragging
                      isHighlighted: candidateData.isNotEmpty,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}