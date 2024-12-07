import 'package:flutter/material.dart';
import 'task_priority.dart';

enum RecurrenceInterval {
  none,
  daily,
  weekly,
  biWeekly,
  monthly,
  quarterly,
  semiAnnually,
  annually,
}

enum TaskStatus {
  todo,      // Not started
  inProgress,// Currently being worked on
  completed, // Done
  onHold,    // Temporarily paused
  cancelled  // Won't be done
}

class Label {
  final String id;
  final String name;
  final Color color;
  final IconData? icon;
  final String? description;
  final DateTime createdAt;

  Label({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      icon: json['icon'] != null ? IconData(json['icon'] as int, fontFamily: 'MaterialIcons') : null,
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'icon': icon?.codePoint,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Label copyWith({
    String? name,
    Color? color,
    IconData? icon,
    String? description,
  }) {
    return Label(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }
}

class Task {
  final String id;
  final String name;
  final Duration duration;
  final Duration breakDuration;
  final int numberOfBreaks;
  final TaskPriority priority;
  final String? project; 
  final List<String> labels;
  final DateTime? dueDate;  
  final DateTime? actionDate;
  final String? notes;
  final TaskStatus status;
  final Duration? actualDuration;
  final RecurrenceInterval recurrence;
  final DateTime? startTime;
  final List<Task>? subtasks;
  final DateTime createdAt;
  
  Task({
    required this.id,
    required this.name,
    required this.duration,
    this.breakDuration = const Duration(minutes: 5),
    this.numberOfBreaks = 2,
    this.priority = TaskPriority.medium,
    this.project,
    List<String>? labels,
    this.dueDate,
    this.actionDate,
    this.notes,
    this.status = TaskStatus.todo,
    this.actualDuration,
    this.recurrence = RecurrenceInterval.none,
    this.startTime,
    this.subtasks,
    DateTime? createdAt,
  }) : 
    labels = labels ?? const [],
    createdAt = createdAt ?? DateTime.now();

  bool get isOverdue {
    return dueDate != null && 
           status != TaskStatus.completed && 
           status != TaskStatus.cancelled && 
           dueDate!.isBefore(DateTime.now());
  }

  bool get isStartingSoon {
    if (startTime == null) return false;
    final now = DateTime.now();
    final difference = startTime!.difference(now);
    return difference.inMinutes <= 30 && difference.isNegative == false;
  }
  
  double get progress {
    if (subtasks == null || subtasks!.isEmpty) {
      return status == TaskStatus.completed ? 1.0 : 0.0;
    }
    final completedSubtasks = subtasks!.where((task) => task.status == TaskStatus.completed).length;
    return completedSubtasks / subtasks!.length;
  }

  Duration get timeSpent => actualDuration ?? const Duration();
  
  Color get statusColor {
    switch (status) {
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.onHold:
        return Colors.orange;
      case TaskStatus.cancelled:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.todo:
        return isOverdue ? Colors.red : priority.color;
    }
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    // Convert legacy completed/archived to TaskStatus
    TaskStatus derivedStatus = TaskStatus.todo;
    
    if (json.containsKey('status')) {
      derivedStatus = TaskStatus.values[json['status'] as int];
    } else {
      final bool isCompleted = json['completed'] as bool? ?? false;
      final bool isArchived = json['archived'] as bool? ?? false;
      
      if (isCompleted) {
        derivedStatus = TaskStatus.completed;
      } else if (isArchived) {
        derivedStatus = TaskStatus.cancelled;
      }
    }

    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      duration: Duration(seconds: json['duration'] as int),
      breakDuration: Duration(seconds: json['breakDuration'] ?? 300),
      numberOfBreaks: json['numberOfBreaks'] ?? 2,
      priority: TaskPriority.values[json['priority'] ?? 1],
      project: json['project'] as String?,
      labels: (json['labels'] as List<dynamic>?)?.cast<String>() ?? const [],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      actionDate: json['actionDate'] != null ? DateTime.parse(json['actionDate']) : null,
      notes: json['notes'] as String?,
      status: derivedStatus,
      actualDuration: json['actualDuration'] != null 
        ? Duration(seconds: json['actualDuration']) 
        : null,
      recurrence: RecurrenceInterval.values[json['recurrence'] ?? 0],
      startTime: json['startTime'] != null 
        ? DateTime.parse(json['startTime']) 
        : null,
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration': duration.inSeconds,
      'breakDuration': breakDuration.inSeconds,
      'numberOfBreaks': numberOfBreaks,
      'priority': priority.index,
      'project': project,
      'labels': labels,
      'dueDate': dueDate?.toIso8601String(),
      'actionDate': actionDate?.toIso8601String(),
      'notes': notes,
      'status': status.index,
      'actualDuration': actualDuration?.inSeconds,
      'recurrence': recurrence.index,
      'startTime': startTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Task copyWith({
    String? name,
    Duration? duration,
    Duration? breakDuration,
    int? numberOfBreaks,
    TaskPriority? priority,
    String? project,
    List<String>? labels,
    DateTime? dueDate,
    DateTime? actionDate,
    String? notes,
    TaskStatus? status,
    Duration? actualDuration,
    RecurrenceInterval? recurrence,
    DateTime? startTime,
    List<Task>? subtasks,
  }) {
    return Task(
      id: id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      breakDuration: breakDuration ?? this.breakDuration,
      numberOfBreaks: numberOfBreaks ?? this.numberOfBreaks,
      priority: priority ?? this.priority,
      project: project ?? this.project,
      labels: labels ?? this.labels,
      dueDate: dueDate ?? this.dueDate,
      actionDate: actionDate ?? this.actionDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      actualDuration: actualDuration ?? this.actualDuration,
      recurrence: recurrence ?? this.recurrence,
      startTime: startTime ?? this.startTime,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt,
    );
  }
}


class TaskComment {
  final String id;
  final String text;
  final DateTime createdAt;
  final String? authorId;
  final List<String>? attachments;

  const TaskComment({
    required this.id,
    required this.text,
    required this.createdAt,
    this.authorId,
    this.attachments,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      authorId: json['authorId'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'authorId': authorId,
      'attachments': attachments,
    };
  }
}