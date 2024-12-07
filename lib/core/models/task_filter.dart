import 'package:flutter/foundation.dart';
import '../../core/models/task_priority.dart';
import '../../core/models/task.dart';

class TaskFilter {
  final Set<TaskPriority> priorities;
  final Set<String> categories;
  final Set<TaskStatus> statuses;
  final bool autoSort;

  const TaskFilter({
    this.priorities = const {},
    this.categories = const {}, 
    this.statuses = const {},
    this.autoSort = true,
  });

  bool matches(Task task) {
    // Priority filter
    if (priorities.isNotEmpty && !priorities.contains(task.priority)) {
      return false;
    }

    // Category/project filter
    if (categories.isNotEmpty) {
      if (task.project == null || !categories.contains(task.project)) {
        return false;
      }
    }

    // Status filter
    if (statuses.isNotEmpty && !statuses.contains(task.status)) {
      return false;
    }

    return true;
  }

  TaskFilter copyWith({
    Set<TaskPriority>? priorities,
    Set<String>? categories,
    Set<TaskStatus>? statuses,
    bool? autoSort,
  }) {
    return TaskFilter(
      priorities: priorities ?? this.priorities,
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      autoSort: autoSort ?? this.autoSort,
    );
  }

  // Helper methods for common filters
  static const TaskFilter activeOnly = TaskFilter(
    statuses: {TaskStatus.todo, TaskStatus.inProgress, TaskStatus.onHold},
  );

  static const TaskFilter completedOnly = TaskFilter(
    statuses: {TaskStatus.completed},
  );

  static const TaskFilter allTasks = TaskFilter();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TaskFilter &&
      setEquals(other.priorities, priorities) &&
      setEquals(other.categories, categories) &&
      setEquals(other.statuses, statuses) &&
      other.autoSort == autoSort;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(priorities),
    Object.hashAll(categories),
    Object.hashAll(statuses),
    autoSort,
  );

  // Named constructors for common filters
  const factory TaskFilter.forStatus(Set<TaskStatus> statuses) = _TaskFilterStatus;
  const factory TaskFilter.forPriorities(Set<TaskPriority> priorities) = _TaskFilterPriority;
  const factory TaskFilter.forCategories(Set<String> categories) = _TaskFilterCategory;
}

class _TaskFilterStatus extends TaskFilter {
  const _TaskFilterStatus(Set<TaskStatus> statuses) : super(statuses: statuses);
}

class _TaskFilterPriority extends TaskFilter {
  const _TaskFilterPriority(Set<TaskPriority> priorities) : super(priorities: priorities);
}

class _TaskFilterCategory extends TaskFilter {
  const _TaskFilterCategory(Set<String> categories) : super(categories: categories);
}

// Extension for sorting tasks
extension TaskSorting on List<Task> {
  List<Task> sortByFilter(TaskFilter filter) {
    if (!filter.autoSort) return this;

    return [...this]..sort((a, b) {
      // First sort by status if filtered
      if (filter.statuses.isNotEmpty) {
        final aStatusIndex = a.status.index;
        final bStatusIndex = b.status.index;
        if (aStatusIndex != bStatusIndex) {
          return aStatusIndex.compareTo(bStatusIndex);
        }
      }

      // Then sort by priority if filtered
      if (filter.priorities.isNotEmpty) {
        final aPriorityIndex = a.priority.index;
        final bPriorityIndex = b.priority.index;
        if (aPriorityIndex != bPriorityIndex) {
          return aPriorityIndex.compareTo(bPriorityIndex);
        }
      }

      // Finally sort by due date if exists
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }

      // If no other criteria, sort by creation date
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  List<Task> applyFilter(TaskFilter filter) {
    if (!filter.autoSort && filter.priorities.isEmpty && 
        filter.categories.isEmpty && filter.statuses.isEmpty) {
      return this;
    }

    return sortByFilter(filter).where(filter.matches).toList();
  }
}