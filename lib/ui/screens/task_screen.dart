import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/task.dart';
import '../../core/services/task_service.dart';
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
  bool _isSearching = false;
  bool _isSidebarOpen = false;
  ValueNotifier<bool> showCompletedTasks = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _searchController.dispose();
    showCompletedTasks.dispose();
    super.dispose();
  }

  List<Task> _filterTasks(List<Task> tasks) {
    List<Task> filteredTasks = showCompletedTasks.value 
        ? tasks 
        : tasks.where((t) => t.status != TaskStatus.completed).toList();

    if (_searchController.text.isEmpty) return filteredTasks;
    
    final query = _searchController.text.toLowerCase();
    return filteredTasks.where((task) {
      final titleMatch = task.name.toLowerCase().contains(query);
      final projectMatch = task.project?.toLowerCase().contains(query) ?? false;
      final notesMatch = task.notes?.toLowerCase().contains(query) ?? false;
      return titleMatch || projectMatch || notesMatch;
    }).toList();
  }

  Future<void> _handleAddTask(BuildContext context) async {
    // Store both context and service before async operation
    final currentContext = context;
    final taskService = currentContext.read<TaskService>();
    
    final task = await showDialog<Task>(
      context: currentContext,
      builder: (context) => const AddTaskDialog(),
    );

    // First check if widget is mounted
    if (!mounted) return;

    // Then check if we have a task to add
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
    final newStatus = task.status == TaskStatus.completed 
        ? TaskStatus.todo 
        : TaskStatus.completed;
        
    final updatedTask = task.copyWith(status: newStatus);
    taskService.updateTask(updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSidebarOpen ? 250 : 0,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            child: Icon(Icons.person),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Account'),
                                Text('Email', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Add Task'),
                      onTap: () => _handleAddTask(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.inbox),
                      title: const Text('Inbox'),
                      onTap: () {}, // Implement inbox navigation
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Favorite Projects', 
                        style: TextStyle(color: Colors.grey)),
                    ),
                    const Spacer(),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () {}, // Implement settings navigation
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      setState(() => _isSidebarOpen = !_isSidebarOpen);
                    },
                  ),
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
                        );
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: Consumer<TaskService>(
                    builder: (context, taskService, child) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: showCompletedTasks,
                        builder: (context, showCompleted, child) {
                          return _TaskList(
                            tasks: _filterTasks(taskService.tasks),
                            onTaskTap: (task) => _handleTaskTap(context, task, taskService),
                            onTaskComplete: (task) => _handleTaskCompletion(task, taskService),
                            onReorder: taskService.reorderTasks,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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

  const _TaskList({
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskComplete,
    required this.onReorder,
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
                taskService.reorderTasks(fromIndex, toIndex);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Transform.rotate(
                      angle: 3.14159 / 180,
                      child: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
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
              );
            },
          ),
        );
      },
    );
  }
}