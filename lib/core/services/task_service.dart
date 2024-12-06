import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/task_priority.dart';
import '../models/task_filter.dart';

class TaskService extends ChangeNotifier {
  static const String _storageKey = 'tasks';
  static const String _labelsKey = 'labels';
  List<Task> _tasks = [];
  List<Label> _labels = [];
  SharedPreferences? _prefs;
  bool _initialized = false;
  TaskFilter _currentFilter = const TaskFilter();

  TaskService() {
    _initPrefs();
  }

  // Getters
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get completedTasks => _tasks.where((task) => task.completed).toList();
  List<Task> get pendingTasks => _tasks.where((task) => !task.completed).toList();
  List<Label> get labels => List.unmodifiable(_labels);
  bool get isInitialized => _initialized;
  TaskFilter get currentFilter => _currentFilter;

  void updateFilter(TaskFilter newFilter) {
    _currentFilter = newFilter;
    if (newFilter.autoSort) {
      _sortTasks();
    }
    notifyListeners();
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      // First sort by completion status if needed
      if (_currentFilter.isCompleted != null) {
        if (a.completed != b.completed) {
          return a.completed ? 1 : -1;
        }
      }

      // Then sort by priority (high to low)
      final priorityCompare = a.priority.index.compareTo(b.priority.index);
      if (priorityCompare != 0) return -priorityCompare; // Reversed to put high priority first

      // Then sort by due date
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }

      // Finally sort by creation date (newer first)
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await Future.wait([
      _loadTasks(),
      _loadLabels(),
    ]);
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadTasks() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final tasksJson = prefs.getStringList(_storageKey) ?? [];
      _tasks = tasksJson
          .map((json) => Task.fromJson(jsonDecode(json)))
          .toList();
      if (_currentFilter.autoSort) {
        _sortTasks();
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      _tasks = [];
    }
  }

  Future<void> _loadLabels() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final labelsJson = prefs.getStringList(_labelsKey) ?? [];
      _labels = labelsJson
          .map((json) => Label.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error loading labels: $e');
      _labels = [];
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
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  Future<void> _saveLabels() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final labelsJson = _labels
          .map((label) => jsonEncode(label.toJson()))
          .toList();
      await prefs.setStringList(_labelsKey, labelsJson);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving labels: $e');
    }
  }

  // Task Operations
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
      _tasks[index] = task;
      if (_currentFilter.autoSort) {
        _sortTasks();
      }
      await _saveTasks();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    await _saveTasks();
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = task.copyWith(completed: !task.completed);
      _tasks[index] = updatedTask;
      if (_currentFilter.autoSort) {
        _sortTasks();
      }
      await _saveTasks();
    }
  }

  // Label Operations
  Future<void> addLabel(Label label) async {
    if (!_labels.any((l) => l.id == label.id)) {
      _labels.add(label);
      await _saveLabels();
    }
  }

  Future<void> updateLabel(Label label) async {
    final index = _labels.indexWhere((l) => l.id == label.id);
    if (index != -1) {
      _labels[index] = label;
      await _saveLabels();
    }
  }

  Future<void> deleteLabel(String labelId) async {
    _labels.removeWhere((label) => label.id == labelId);
    // Remove label from all tasks
    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (task.labels.any((l) => l == labelId)) { // Changed to check String in List<String>
        _tasks[i] = task.copyWith(
          labels: task.labels.where((id) => id != labelId).toList(),
        );
      }
    }
    await Future.wait([
      _saveLabels(),
      _saveTasks(),
    ]);
  }

  // Query Methods
  List<Task> getTasksByProject(String project) {
    return _tasks.where((task) => task.project == project).toList();
  }

  List<Task> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  List<Task> getTasksByLabel(String labelId) {
    return _tasks.where((task) => task.labels.contains(labelId)).toList();
  }

  List<Task> getOverdueTasks() {
    return _tasks.where((task) => task.isOverdue).toList();
  }

  List<Task> getUpcomingTasks({Duration window = const Duration(days: 7)}) {
    final now = DateTime.now();
    final cutoff = now.add(window);
    return _tasks.where((task) => 
      !task.completed && 
      task.dueDate != null &&
      task.dueDate!.isBefore(cutoff)).toList();
  }

  Set<String> get projects { 
    return _tasks
        .where((task) => task.project != null)
        .map((task) => task.project!)
        .toSet();
  }

  // Utility Methods
  Future<void> clearCompletedTasks({bool archive = true}) async {
    if (archive) {
      _tasks = _tasks.map((task) => 
        task.completed ? task.copyWith(archived: true) : task).toList();
    } else {
      _tasks.removeWhere((task) => task.completed);
    }
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
      notifyListeners();
    } catch (e) {
      debugPrint('Error reordering tasks: $e');
      rethrow;
    }
  }
}