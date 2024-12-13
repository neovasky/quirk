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
  String? _lastSortMode;  // Track the last non-manual sort mode
  bool _isManualMode = false;  // Track if we're in manual mode

  TaskService() {
    _initPrefs();
  }

  // Getters
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get completedTasks => _tasks.where((task) => task.status.isCompleted).toList();
  List<Task> get pendingTasks => _tasks.where((task) => !task.status.isCompleted).toList();
  bool get isInitialized => _initialized;
  TaskFilter get currentFilter => _currentFilter;
  String? get lastSortMode => _lastSortMode;
  bool get isManualMode => _isManualMode;

  void updateFilter(TaskFilter newFilter) {
    _currentFilter = newFilter;
    if (newFilter.autoSort && _lastSortMode != null && !_isManualMode) {
      sortTasks(_lastSortMode!);
      notifyListeners();
    }
  }

  void sortTasks(String sortMode) {
    if (sortMode.toLowerCase() == 'manual') {
      _isManualMode = true;
      // Keep current order when switching to manual
      return;
    }

    _isManualMode = false;
    _lastSortMode = sortMode;

    _tasks.sort((a, b) {
      // First sort by status if filtered
      if (_currentFilter.statuses.isNotEmpty) {
        final aStatusIndex = a.status.index;
        final bStatusIndex = b.status.index;
        if (aStatusIndex != bStatusIndex) {
          return aStatusIndex.compareTo(bStatusIndex);
        }
      }

      // Then apply the selected sort
      switch (sortMode.toLowerCase()) {
        case 'priority':
          return a.priority.index.compareTo(b.priority.index);  // HIGH to LOW
        case 'due date':
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        case 'created':
          return b.createdAt.compareTo(a.createdAt);
        default:
          return 0;
      }
    });
    
    notifyListeners();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTasks();
    _initialized = true;
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
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }


  Future<void> addTask(Task task) async {
    _tasks.add(task);
    if (_lastSortMode != null && !_isManualMode) {
      sortTasks(_lastSortMode!);
    }
    await _saveTasks();
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      if (_lastSortMode != null && !_isManualMode) {
        sortTasks(_lastSortMode!);
      }
      await _saveTasks();
    }
  }

  Future<void> toggleTaskCompletion(Task task, bool showCompleted) async {
    TaskStatus newStatus;
    
    if (task.status == TaskStatus.completedVisible) {
      newStatus = TaskStatus.todo;
    } else {
      newStatus = task.status.toggleCompletion(showCompleted);
    }
    
    final updatedTask = task.copyWith(status: newStatus);
    await updateTask(updatedTask);
  }

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

      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      // Just move the task without resorting
      final task = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, task);
      
      _isManualMode = true;  // Set manual mode when reordering
      await _saveTasks();
    } catch (e) {
      debugPrint('Error reordering tasks: $e');
      rethrow;
    }
  }
}