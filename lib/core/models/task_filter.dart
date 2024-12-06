import 'task_priority.dart';
import 'task.dart';

// Moved from dialog to be a central definition
class TaskFilter {
  final Set<TaskPriority> priorities;
  final Set<String> categories;
  final bool? isCompleted;
  final bool autoSort;

  const TaskFilter({
    this.priorities = const {},
    this.categories = const {}, 
    this.isCompleted,
    this.autoSort = true,
  });

  bool matches(Task task) {
    // Check priorities
    if (priorities.isNotEmpty && !priorities.contains(task.priority)) {
      return false;
    }

    // Check project/categories
    if (categories.isNotEmpty) {
      if (task.project == null) {
        return false;
      }
      if (!categories.contains(task.project)) {
        return false;
      }
    }

    // Check completion status
    if (isCompleted != null && task.completed != isCompleted) {
      return false;
    }

    return true;
  }

  TaskFilter copyWith({
    Set<TaskPriority>? priorities,
    Set<String>? categories,
    bool? isCompleted,
    bool? autoSort,
  }) {
    return TaskFilter(
      priorities: priorities ?? this.priorities,
      categories: categories ?? this.categories,
      isCompleted: isCompleted ?? this.isCompleted,
      autoSort: autoSort ?? this.autoSort,
    );
  }
}