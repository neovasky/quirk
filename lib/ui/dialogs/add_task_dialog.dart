import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/task.dart';
import '../../core/models/task_priority.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _nameController = TextEditingController();
  final List<String> _selectedLabels = [];
  final _notesController = TextEditingController();
  final int _numberOfBreaks = 2;
  int _durationMinutes = 25;
  int _breakDurationMinutes = 5;
  TaskPriority _priority = TaskPriority.medium;
  String? _project;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  DateTime? _actionDate;
  RecurrenceInterval _recurrence = RecurrenceInterval.none;

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
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add New Task',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            const Divider(height: 1),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Task Name
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Task Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Duration Controls - Using a more compact layout
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

                    const SizedBox(height: 16),

                    // Priority and Recurrence in a row
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

                    const SizedBox(height: 16),

                    // Project field
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Project (optional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() => _project = value.isEmpty ? null : value);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Dates in a row
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateButton(
                            label: 'Due Date',
                            date: _dueDate,
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateButton(
                            label: 'Work Date',
                            date: _actionDate,
                            onTap: () => _selectDate(context, false),
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

                    const SizedBox(height: 16),

                    // Notes
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
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saveTask,
                    child: const Text('Add Task'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 8),
          Text(date?.toString().split(' ')[0] ?? label),
        ],
      ),
    );
  }

  // Helper Methods
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

    final task = Task(
      id: const Uuid().v4(),
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
    );
    
    Navigator.of(context).pop(task);
  }

  // Date/Time Selection Methods
  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isDueDate ? _dueDate : _actionDate) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
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

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}