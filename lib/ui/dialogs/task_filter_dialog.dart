import 'package:flutter/material.dart';
import '../../core/models/task_priority.dart';
import '../../core/models/task.dart';
import '../../core/models/task_filter.dart';

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
  late Set<TaskStatus> _selectedStatuses;
  late bool _autoSort;

  @override
  void initState() {
    super.initState();
    _selectedPriorities = Set.from(widget.currentFilter.priorities);
    _selectedCategories = Set.from(widget.currentFilter.categories);
    _selectedStatuses = Set.from(widget.currentFilter.statuses);
    _autoSort = widget.currentFilter.autoSort;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(
          minWidth: 600,
          maxWidth: 800,
          minHeight: 300,
          maxHeight: 500,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Tasks',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilterChip(
                  label: const Text('Auto Sort'),
                  selected: _autoSort,
                  onSelected: (selected) {
                    setState(() => _autoSort = selected);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Priority Section
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

            // Status Section
            const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: TaskStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getStatusText(status)),
                      selected: _selectedStatuses.contains(status),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedStatuses.add(status);
                          } else {
                            _selectedStatuses.remove(status);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Projects Section
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

            const Spacer(),

            // Action Buttons
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
                          statuses: _selectedStatuses,
                          autoSort: _autoSort,
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

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.onHold:
        return 'On Hold';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }
}