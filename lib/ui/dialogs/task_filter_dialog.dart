import 'package:flutter/material.dart';
import '../../core/models/task.dart';
import '../../core/models/task_priority.dart';

class TaskFilter {
  final Set<TaskPriority> priorities;
  final Set<String> categories;  // Keep as categories
  final bool? isCompleted;

  const TaskFilter({
    this.priorities = const {},
    this.categories = const {}, 
    this.isCompleted,
  });

  bool matches(Task task) {
    if (priorities.isNotEmpty && !priorities.contains(task.priority)) {
      return false;
    }
    if (categories.isNotEmpty && task.project != null && !categories.contains(task.project)) {
      return false;
    }
    if (isCompleted != null && task.completed != isCompleted) {
      return false;
    }
    return true;
  }
}

class TaskFilterDialog extends StatefulWidget {
  final TaskFilter currentFilter;
  final List<String> availableCategories;

  const TaskFilterDialog({
    super.key, 
    required this.currentFilter,
    required this.availableCategories,
  });

  @override
  State<TaskFilterDialog> createState() => _TaskFilterDialogState();
}

class _TaskFilterDialogState extends State<TaskFilterDialog> {
  late Set<TaskPriority> _selectedPriorities;
  late Set<String> _selectedCategories;
  late bool? _selectedCompletion;

  @override
  void initState() {
    super.initState();
    _selectedPriorities = Set.from(widget.currentFilter.priorities);
    _selectedCategories = Set.from(widget.currentFilter.categories);
    _selectedCompletion = widget.currentFilter.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
        constraints: const BoxConstraints(
          minWidth: 600, // Minimum width to fit all filter options
          maxWidth: 800, // Maximum width to not be overwhelming
          minHeight: 300,
          maxHeight: 500,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Tasks',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: TaskPriority.values.map((priority) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(priority.name.toUpperCase()),
                      selected: _selectedPriorities.contains(priority),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPriorities.add(priority);
                          } else {
                            _selectedPriorities.remove(priority);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Projects', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (widget.availableCategories.isEmpty)
              const Text(
                'No projects available',
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            else
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: widget.availableCategories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: _selectedCategories.contains(category),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 24),
            const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: _buildStatusButtons(),
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    const filter = TaskFilter();
                    Navigator.of(context).pop(filter);
                  },
                  child: const Text('Clear'),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final filter = TaskFilter(
                          priorities: _selectedPriorities,
                          categories: _selectedCategories,
                          isCompleted: _selectedCompletion,
                        );
                        Navigator.of(context).pop(filter);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatusButtons() {
    final buttonData = [
      (label: 'All', value: null),
      (label: 'Pending', value: false),
      (label: 'Completed', value: true),
    ];

    return buttonData.map((data) {
      final isSelected = _selectedCompletion == data.value;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedCompletion = data.value),
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Text(data.label),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}