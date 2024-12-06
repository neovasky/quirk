import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  // Drag handle with completion bubble
                      SizedBox(
                        width: 40,  // Reduced width since we no longer have the bubble here
                        child: Transform.rotate(
                          angle: 3.14159 / 180,
                          child: const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  // Task content
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

class CompletionBubble extends StatefulWidget {
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
  State<CompletionBubble> createState() => _CompletionBubbleState();
}

class _CompletionBubbleState extends State<CompletionBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
        reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    if (widget.isCompleted) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CompletionBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted) {
      if (widget.isCompleted) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        HapticFeedback.lightImpact();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: widget.isCompleted ? widget.color : null,
                border: Border.all(
                  color: widget.color,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: widget.isCompleted ? Center(
                child: ScaleTransition(
                  scale: _checkAnimation,
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ) : null,
            ),
          );
        },
      ),
    );
  }
}