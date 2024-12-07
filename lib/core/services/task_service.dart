import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/task_filter.dart';

class TaskService extends ChangeNotifier {
  static const String _storageKey = 'tasks';
  final List<Task> _tasks = [];
  final Map<String, int> _manualOrder = {};
  SharedPreferences? _prefs;
  bool _initialized = false;
  TaskFilter _currentFilter = const TaskFilter();
  
  // Add a flag to track if we're using manual ordering
  bool _isManuallyOrdered = false;

  TaskService() {
    _initPrefs();
  }

  List<Task> get tasks {
    // First, filter the tasks based on current filter
    var filteredTasks = _tasks.where(_currentFilter.matches).toList();
    
    // If auto-sort is enabled and we haven't manually reordered
    if (_currentFilter.autoSort && !_isManuallyOrdered) {
      // First sort by status
      filteredTasks.sort((a, b) {
        final statusComparison = a.status.index.compareTo(b.status.index);
        if (statusComparison != 0) return statusComparison;
        
        // Then sort by priority (HIGH = 0 should come first)
        final priorityComparison = a.priority.index.compareTo(b.priority.index);
        if (priorityComparison != 0) return priorityComparison;
        
        // Then by due date if exists
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        } else if (a.dueDate != null) {
          return -1;
        } else if (b.dueDate != null) {
          return 1;
        }
        
        // Finally by creation date (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });
    } else if (_isManuallyOrdered && _manualOrder.isNotEmpty) {
      // Apply manual ordering
      filteredTasks.sort((a, b) {
        final orderA = _manualOrder[a.id] ?? 999999;
        final orderB = _manualOrder[b.id] ?? 999999;
        return orderA.compareTo(orderB);
      });
    }
    
    return List.unmodifiable(filteredTasks);
  }

  List<Task> get completedTasks => 
    tasks.where((task) => task.status == TaskStatus.completed).toList();
  
  List<Task> get pendingTasks => 
    tasks.where((task) => task.status != TaskStatus.completed).toList();
  
  bool get isInitialized => _initialized;
  TaskFilter get currentFilter => _currentFilter;

  // Method to explicitly reset to auto-sort
  void resetToAutoSort() {
    _isManuallyOrdered = false;
    _manualOrder.clear();
    notifyListeners();
  }

  void updateFilter(TaskFilter newFilter) {
    if (_currentFilter == newFilter) return;
    
    // If switching to auto-sort, clear manual ordering
    if (newFilter.autoSort && !_currentFilter.autoSort) {
      resetToAutoSort();
    }
    
    _currentFilter = newFilter;
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
      _manualOrder.clear();
      _isManuallyOrdered = false;
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
    // Reset to auto-sort when adding new tasks
    resetToAutoSort();
    await _saveTasks();
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      // Reset to auto-sort when updating tasks
      resetToAutoSort();
      await _saveTasks();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    _manualOrder.remove(taskId);
    await _saveTasks();
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    try {
      final visibleTasks = tasks;
      if (oldIndex < 0 || oldIndex >= visibleTasks.length || 
          newIndex < 0 || newIndex >= visibleTasks.length) {
        throw RangeError('Invalid index for reordering');
      }

      // Get the tasks being reordered
      final movedTask = visibleTasks[oldIndex];
      
      // Update manual ordering
      final tasksList = List<Task>.from(visibleTasks);
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      tasksList.removeAt(oldIndex);
      tasksList.insert(newIndex, movedTask);
      
      // Update order map and mark as manually ordered
      _isManuallyOrdered = true;
      for (var i = 0; i < tasksList.length; i++) {
        _manualOrder[tasksList[i].id] = i;
      }

      notifyListeners();
      await _saveTasks();
    } catch (e) {
      debugPrint('Error reordering tasks: $e');
      rethrow;
    }
  }
}