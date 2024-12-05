import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/task.dart';
import '../../core/services/task_service.dart';
import '../dialogs/add_task_dialog.dart';
import '../dialogs/task_details_dialog.dart';
import '../dialogs/task_filter_dialog.dart';
import '../components/task_list_tile.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  TaskFilter _filter = const TaskFilter();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> _filterTasks(List<Task> tasks) {
    if (_searchController.text.isEmpty) {
      return tasks.where((task) => _filter.matches(task)).toList();
    }
    
    final query = _searchController.text.toLowerCase();
    return tasks.where((task) {
      final matchesFilter = _filter.matches(task);
      final titleMatch = task.name.toLowerCase().contains(query);
      final projectMatch = task.project?.toLowerCase().contains(query) ?? false;
      final notesMatch = task.notes?.toLowerCase().contains(query) ?? false;
      return matchesFilter && (titleMatch || projectMatch || notesMatch);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: TextStyle(color: Colors.white70),
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
              icon: const Icon(Icons.filter_list),
              onPressed: () async {
                final taskService = context.read<TaskService>();
                final projects = taskService.tasks
                    .where((t) => t.project != null)
                    .map((t) => t.project!)
                    .toSet()
                    .toList();
                
                final newFilter = await showDialog<TaskFilter>(
                  context: context,
                  builder: (context) => TaskFilterDialog(
                    currentFilter: _filter,
                    availableCategories: projects,
                  ),
                );

                if (newFilter != null) {
                  setState(() {
                    _filter = newFilter;
                  });
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Archive'),
            ],
          ),
        ),
        body: Consumer<TaskService>(
          builder: (context, taskService, child) {
            return TabBarView(
              children: [
                // Active Tasks
                _TaskList(
                  tasks: _filterTasks(
                    taskService.tasks.where((t) => !t.archived).toList()
                  ),
                  onTaskTap: (task) async {
                    final result = await showDialog<dynamic>(
                      context: context,
                      builder: (context) => TaskDetailsDialog(task: task),
                    );

                    if (result == 'delete') {
                      if (!context.mounted) return;
                      taskService.deleteTask(task.id);
                    } else if (result is Task) {
                      if (!context.mounted) return;
                      taskService.updateTask(result);
                    }
                  },
                  onTaskComplete: (task) {
                    final updatedTask = task.copyWith(
                      completed: !task.completed,
                      archived: !task.completed,
                    );
                    taskService.updateTask(updatedTask);
                  },
                ),
                // Archived Tasks
                _TaskList(
                  tasks: _filterTasks(
                    taskService.tasks.where((t) => t.archived).toList()
                  ),
                  onTaskTap: (task) async {
                    final result = await showDialog<dynamic>(
                      context: context,
                      builder: (context) => TaskDetailsDialog(task: task),
                    );

                    if (result == 'delete') {
                      if (!context.mounted) return;
                      taskService.deleteTask(task.id);
                    } else if (result is Task) {
                      if (!context.mounted) return;
                      taskService.updateTask(result);
                    }
                  },
                  onTaskComplete: (task) {
                    final updatedTask = task.copyWith(
                      completed: false,
                      archived: false,
                    );
                    taskService.updateTask(updatedTask);
                  },
                ),
              ],
            );
          },
        ),
floatingActionButton: FloatingActionButton(
  onPressed: () async {
    // Store the TaskService before async gap
    final taskService = context.read<TaskService>();
    
    final task = await showDialog<Task>(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );
    
    // Check if task not null and widget still mounted
    if (task != null && mounted) {
      // Use the stored taskService instead of accessing context again
      taskService.addTask(task);
    }
  },
  child: const Icon(Icons.add),
),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task) onTaskComplete;

  const _TaskList({
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('No tasks'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        
        return Column(
          children: [
            LongPressDraggable<int>(
              data: index,
              delay: const Duration(milliseconds: 71),  // Reduced delay for better responsiveness
              hapticFeedbackOnStart: true,  // Add haptic feedback when drag starts
              feedback: Material(
                elevation: 8.0,  // Increased elevation for better depth
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  child: TaskListTile(
                    key: ValueKey('drag_${task.id}'),
                    task: task,
                    onTap: () {},
                    onComplete: () {},
                    isDraggable: true,
                    isDragging: true,  // Added state for dragging visual
                  ),
                ),
              ),
              childWhenDragging: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: 0.3,
                child: SizedBox(
                  height: 72,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ),
              child: DragTarget<int>(
                onWillAcceptWithDetails: (details) => details.data != index,
                onAcceptWithDetails: (details) {
                  final taskService = context.read<TaskService>();
                  taskService.reorderTasks(details.data, index);
                },
                builder: (context, candidateData, rejectedData) {
                  return MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: TaskListTile(
                      key: ValueKey(task.id),
                      task: task,
                      onTap: () => onTaskTap(task),
                      onComplete: () => onTaskComplete(task),
                      isDraggable: true,
                      isHighlighted: candidateData.isNotEmpty,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}