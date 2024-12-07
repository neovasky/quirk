import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/task.dart';
import '../../core/models/task_filter.dart';
import '../../core/services/task_service.dart';
import '../components/task_list_tile.dart';
import '../dialogs/add_task_dialog.dart';
import '../dialogs/task_details_dialog.dart';
import '../dialogs/task_filter_dialog.dart';

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
  void initState() {
    super.initState();
    // Apply initial filter to TaskService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskService = context.read<TaskService>();
      taskService.updateFilter(_filter);
    });
  }

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
                  taskService.updateFilter(newFilter);
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed & Archived'),
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
                    taskService.tasks.where((t) => 
                      t.status != TaskStatus.completed && 
                      t.status != TaskStatus.cancelled
                    ).toList()
                  ),
                  onTaskTap: (task) => _handleTaskTap(context, task, taskService),
                  onTaskComplete: (task) => _handleTaskCompletion(task, taskService),
                ),
                // Completed & Cancelled Tasks
                _TaskList(
                  tasks: _filterTasks(
                    taskService.tasks.where((t) => 
                      t.status == TaskStatus.completed || 
                      t.status == TaskStatus.cancelled
                    ).toList()
                  ),
                  onTaskTap: (task) => _handleTaskTap(context, task, taskService),
                  onTaskComplete: (task) {
                    final updatedTask = task.copyWith(status: TaskStatus.todo);
                    taskService.updateTask(updatedTask);
                  },
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final taskService = context.read<TaskService>();
            final task = await showDialog<Task>(
              context: context,
              builder: (context) => const AddTaskDialog(),
            );
            
            if (task != null && mounted) {
              taskService.addTask(task);
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _handleTaskTap(BuildContext context, Task task, TaskService taskService) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => TaskDetailsDialog(task: task),
    );

    if (result == 'delete') {
      if (!mounted) return;
      taskService.deleteTask(task.id);
    } else if (result is Task) {
      if (!mounted) return;
      taskService.updateTask(result);
    }
  }

  void _handleTaskCompletion(Task task, TaskService taskService) {
    final newStatus = task.status == TaskStatus.completed 
        ? TaskStatus.todo 
        : TaskStatus.completed;
        
    final updatedTask = task.copyWith(status: newStatus);
    taskService.updateTask(updatedTask);
  }
}

// Inside _TaskList class in task_screen.dart

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
      return const Center(child: Text('No tasks'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Draggable<Task>(
          data: task,
          maxSimultaneousDrags: 1,
          dragAnchorStrategy: pointerDragAnchorStrategy,
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
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: TaskListTile(
              key: ValueKey('placeholder_${task.id}'),
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
              final taskService = context.read<TaskService>();
              final fromIndex = tasks.indexWhere((t) => t.id == incomingTask.id);
              final toIndex = tasks.indexWhere((t) => t.id == task.id);
              
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
                      // Arrow and completion status section
                      SizedBox(
                        width: 80,
                        child: Row(
                          children: [
                            Transform.rotate(
                              angle: 3.14159 / 180, // Rotates chevron to point right
                              child: const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            CompletionBubble(
                              isCompleted: task.status == TaskStatus.completed,
                              color: task.statusColor,
                              onComplete: () => onTaskComplete(task),
                            ),
                          ],
                        ),
                      ),
                      // Task tile
                      Expanded(
                        child: TaskListTile(
                          key: ValueKey(task.id),
                          task: task,
                          onTap: () => onTaskTap(task),
                          onComplete: () => onTaskComplete(task),
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
  }
}