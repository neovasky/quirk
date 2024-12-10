import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/task_filter.dart';

class TaskService extends ChangeNotifier {
  static const String _storageKey = 'tasks';
  final List<Task> _tasks = [];
  SharedPreferences? _prefs;
  bool _initialized = false;
  TaskFilter _currentFilter = const TaskFilter();

  TaskService() {
    _initPrefs();
  }

  // Getters
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get completedTasks => _tasks.where((task) => task.status.isCompleted).toList();
  List<Task> get pendingTasks => _tasks.where((task) => !task.status.isCompleted).toList();
  bool get isInitialized => _initialized;
  TaskFilter get currentFilter => _currentFilter;

  void updateFilter(TaskFilter newFilter) {
    _currentFilter = newFilter;
    if (newFilter.autoSort) {
      _sortTasks();
      notifyListeners();
    }
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      // First sort by status if filtered
      if (_currentFilter.statuses.isNotEmpty) {
        final aStatusIndex = a.status.index;
        final bStatusIndex = b.status.index;
        if (aStatusIndex != bStatusIndex) {
          return aStatusIndex.compareTo(bStatusIndex);
        }
      }

      // Then sort by priority if filtered (reversed for HIGH to LOW)
      if (_currentFilter.priorities.isNotEmpty) {
        final aPriorityIndex = a.priority.index;
        final bPriorityIndex = b.priority.index;
        if (aPriorityIndex != bPriorityIndex) {
          return bPriorityIndex.compareTo(aPriorityIndex);  // Reversed comparison
        }
      }

      // Then sort by due date
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }

      // Finally sort by creation date
      return b.createdAt.compareTo(a.createdAt);
    });
  }


  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await Future.wait([
      _loadTasks(),
    ]);
    _initialized = true;
    if (_currentFilter.autoSort) {
      _sortTasks();
    }
    notifyListeners();
  }

  Future<void> _loadTasks() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final tasksJson = prefs.getStringList(_storageKey) ?? [];
      _tasks.clear();
      _tasks.addAll(
        tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList()
      );
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> _saveTasks() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final tasksJson = _tasks
          .map((task) => jsonEncode(task.toJson()))
          .toList();
      await prefs.setStringList(_storageKey, tasksJson);
      notifyListeners();  // Ensure UI is updated
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    if (_currentFilter.autoSort) {
      _sortTasks();
    }
    await _saveTasks();
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      // Special handling for status changes
      final oldTask = _tasks[index];
      final oldStatus = oldTask.status;
      final newStatus = task.status;

      // Log status change for debugging
      debugPrint('Task status changing from $oldStatus to $newStatus');

      // Update the task
      _tasks[index] = task;

      // Sort if needed (but not for status toggles)
      if (_currentFilter.autoSort && oldStatus == newStatus) {
        _sortTasks();
      }

      // Save and notify
      await _saveTasks();
      
      // Ensure UI updates immediately for status changes
      if (oldStatus != newStatus) {
        notifyListeners();
      }
    }
  }

  Future<void> toggleTaskCompletion(Task task, bool showCompleted) async {
    TaskStatus newStatus;
    
    if (task.status == TaskStatus.completedVisible) {
      // If task is visible and completed, change to todo
      newStatus = TaskStatus.todo;
    } else {
      // Otherwise use normal toggle behavior
      newStatus = task.status.toggleCompletion(showCompleted);
    }
    
    final updatedTask = task.copyWith(status: newStatus);
    await updateTask(updatedTask);
  }

  // Helper method for toggling task visibility
  Future<void> toggleTaskVisibility(Task task, bool showCompleted) async {
    if (!task.status.isCompleted) return;
    
    final newStatus = showCompleted ? 
      TaskStatus.completedVisible : 
      TaskStatus.completedHidden;
    
    if (task.status != newStatus) {
      final updatedTask = task.copyWith(status: newStatus);
      await updateTask(updatedTask);
    }
  }


  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    await _saveTasks();
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < 0 || oldIndex >= _tasks.length || 
          newIndex < 0 || newIndex >= _tasks.length) {
        throw RangeError('Invalid index for reordering');
      }
      
      // Disable auto-sorting when manually reordering
      if (_currentFilter.autoSort) {
        _currentFilter = _currentFilter.copyWith(autoSort: false);
      }
      
      final task = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, task);
      
      await _saveTasks();
    } catch (e) {
      debugPrint('Error reordering tasks: $e');
      rethrow;
    }
  }
}