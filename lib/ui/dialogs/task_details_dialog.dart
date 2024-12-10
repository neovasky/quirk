import 'package:flutter/material.dart';
import '../../core/models/task.dart';
import '../../core/models/task_priority.dart';

class TaskDetailsDialog extends StatefulWidget {
  final Task task;

  const TaskDetailsDialog({super.key, required this.task});

  @override
  State<TaskDetailsDialog> createState() => _TaskDetailsDialogState();
}

class _TaskDetailsDialogState extends State<TaskDetailsDialog> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final List<String> _selectedLabels = [];

  late int _durationMinutes;
  late int _breakDurationMinutes;
  late int _numberOfBreaks;
  late TaskPriority _priority;
  late String? _project;
  late DateTime? _dueDate;
  late TimeOfDay? _dueTime;
  late DateTime? _actionDate;
  late TaskStatus _status;
  late RecurrenceInterval _recurrence;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.task.name;
    _durationMinutes = widget.task.duration.inMinutes;
    _breakDurationMinutes = widget.task.breakDuration.inMinutes;
    _numberOfBreaks = widget.task.numberOfBreaks;
    _priority = widget.task.priority;
    _project = widget.task.project;
    _dueDate = widget.task.dueDate;
    _dueTime = widget.task.dueDate != null 
      ? TimeOfDay.fromDateTime(widget.task.dueDate!) 
      : null;
    _actionDate = widget.task.actionDate;
    _notesController.text = widget.task.notes ?? '';
    _recurrence = widget.task.recurrence;
    _selectedLabels.addAll(widget.task.labels);
    _status = widget.task.status;
  }

  String _getStatusTitle(TaskStatus status) {
    switch (status) {
      case TaskStatus.completedVisible:
      case TaskStatus.completedHidden:
        return 'Completed Task';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.onHold:
        return 'Task On Hold';
      case TaskStatus.cancelled:
        return 'Cancelled Task';
      case TaskStatus.todo:
        return 'Edit Task';
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.completedVisible:
        return 'Completed (Visible)';
      case TaskStatus.completedHidden:
        return 'Completed (Hidden)';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.onHold:
        return 'On Hold';
      case TaskStatus.cancelled:
        return 'Cancelled';
      case TaskStatus.todo:
        return 'To Do';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_status.isCompleted)
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getStatusTitle(_status),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(context),
                    tooltip: 'Delete Task',
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Task Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Status selection
                    DropdownButtonFormField<TaskStatus>(
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      value: _status,
                      items: [
                        TaskStatus.todo,
                        TaskStatus.inProgress,
                        TaskStatus.onHold,
                        TaskStatus.completedVisible,
                        TaskStatus.completedHidden,
                        TaskStatus.cancelled,
                      ].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(_getStatusText(status)),
                        );
                      }).toList(),
                      onChanged: (status) {
                        if (status != null) {
                          setState(() => _status = status);
                        }
                      },
                    ),


                    const SizedBox(height: 24),
                    
                    // Duration controls
                    Text('Task Duration', style: Theme.of(context).textTheme.titleSmall),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Work: $_durationMinutes min'),
                              Slider(
                                value: _durationMinutes.toDouble(),
                                min: 5,
                                max: 120,
                                divisions: 23,
                                onChanged: (value) {
                                  setState(() => _durationMinutes = value.round());
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Break: $_breakDurationMinutes min'),
                              Slider(
                                value: _breakDurationMinutes.toDouble(),
                                min: 1,
                                max: 30,
                                divisions: 29,
                                onChanged: (value) {
                                  setState(() => _breakDurationMinutes = value.round());
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<TaskPriority>(
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                            value: _priority,
                            items: TaskPriority.values.map((priority) {
                              return DropdownMenuItem(
                                value: priority,
                                child: Text(priority.name.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _priority = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<RecurrenceInterval>(
                            decoration: const InputDecoration(
                              labelText: 'Recurrence',
                              border: OutlineInputBorder(),
                            ),
                            value: _recurrence,
                            items: RecurrenceInterval.values.map((interval) {
                              return DropdownMenuItem(
                                value: interval,
                                child: Text(_getRecurrenceText(interval)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _recurrence = value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Project (optional)',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _project),
                      onChanged: (value) {
                        setState(() => _project = value.isEmpty ? null : value);
                      },
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_dueDate?.toString().split(' ')[0] ?? 'Set Due Date'),
                            onPressed: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_actionDate?.toString().split(' ')[0] ?? 'Set Work Date'),
                            onPressed: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),

                    if (_dueDate != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(_dueTime?.format(context) ?? 'Set Time'),
                        onPressed: () => _selectTime(context),
                      ),
                    ],

                    const SizedBox(height: 24),

                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _saveTask,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _getRecurrenceText(RecurrenceInterval interval) {
    switch (interval) {
      case RecurrenceInterval.none:
        return 'No repeat';
      case RecurrenceInterval.daily:
        return 'Daily';
      case RecurrenceInterval.weekly:
        return 'Weekly';
      case RecurrenceInterval.biWeekly:
        return 'Bi-Weekly';
      case RecurrenceInterval.monthly:
        return 'Monthly';
      case RecurrenceInterval.quarterly:
        return 'Quarterly';
      case RecurrenceInterval.semiAnnually:
        return '6 Months';
      case RecurrenceInterval.annually:
        return 'Yearly';
    }
  }

Future<void> _confirmDelete(BuildContext context) async {
    final navigatorState = Navigator.of(context);
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      navigatorState.pop('delete');
    }
  }


  void _saveTask() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task name')),
      );
      return;
    }

    DateTime? finalDueDate;
    if (_dueDate != null && _dueTime != null) {
      finalDueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime!.hour,
        _dueTime!.minute,
      );
    }
    
    final task = widget.task.copyWith(
      name: _nameController.text,
      duration: Duration(minutes: _durationMinutes),
      breakDuration: Duration(minutes: _breakDurationMinutes),
      numberOfBreaks: _numberOfBreaks,
      priority: _priority,
      project: _project,
      labels: _selectedLabels,
      dueDate: finalDueDate,
      actionDate: _actionDate,
      notes: _notesController.text,
      recurrence: _recurrence,
      status: _status,
    );
    
    Navigator.of(context).pop(task);
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final currentContext = context;
    final now = DateTime.now();
    DateTime initialDate;
    
    if (isDueDate) {
      initialDate = _dueDate ?? now;
      // If the due date is in the past, use today as initial date
      if (initialDate.isBefore(now)) {
        initialDate = now;
      }
    } else {
      initialDate = _actionDate ?? now;
      // If the action date is in the past, use today as initial date
      if (initialDate.isBefore(now)) {
        initialDate = now;
      }
    }

    final DateTime? picked = await showDatePicker(
      context: currentContext,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(2101),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
          _dueTime ??= const TimeOfDay(hour: 23, minute: 59);
        } else {
          _actionDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }
}