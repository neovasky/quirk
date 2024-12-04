import 'package:flutter/material.dart';
import '../../core/models/task.dart';
import '../../core/models/task_priority.dart';

class TaskFilter {
  final Set<TaskPriority> priorities;
  final Set<String> categories;
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
    if (categories.isNotEmpty && 
        task.project != null && 
        !categories.contains(task.project)) {
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
    return AlertDialog(
      title: const Text('Filter Tasks'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: TaskPriority.values.map((priority) {
                return FilterChip(
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
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
            if (widget.availableCategories.isEmpty)
              const Text('No categories available', style: TextStyle(fontStyle: FontStyle.italic))
            else
              Wrap(
                spacing: 8,
                children: widget.availableCategories.map((category) {
                  return FilterChip(
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
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            SegmentedButton<bool?>(
              segments: const [
                ButtonSegment(
                  value: null,
                  label: Text('All'),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Pending'),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Completed'),
                ),
              ],
              selected: {_selectedCompletion},
              onSelectionChanged: (Set<bool?> selected) {
                setState(() {
                  _selectedCompletion = selected.first;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        TextButton(
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
        TextButton(
          onPressed: () {
            const filter = TaskFilter();
            Navigator.of(context).pop(filter);
          },
          child: const Text('Clear'),
        ),
      ],
    );
  }
}