import 'package:flutter/material.dart';
import '../../core/models/task_priority.dart';

class ViewMenuController {
  OverlayEntry? _overlayEntry;
  bool isOpen = false;

  void show(BuildContext context, GlobalKey buttonKey, {
    required ValueNotifier<bool> showCompletedTasks,
    required ValueNotifier<String> sortBy,
    required ValueNotifier<Set<TaskPriority>> selectedPriorities,
  }) {
    if (isOpen) return;

    final RenderBox buttonBox = buttonKey.currentContext!.findRenderObject() as RenderBox;
    final buttonPosition = buttonBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    const menuWidth = 300.0;
    const rightPadding = 16.0;
    final left = screenWidth - menuWidth - rightPadding;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: hide,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black12),
              ),
            ),
            Positioned(
              top: buttonPosition.dy + buttonBox.size.height + 8,
              left: left,
              child: ViewMenuOverlay(
                onClose: hide,
                showCompletedTasks: showCompletedTasks,
                sortBy: sortBy,
                selectedPriorities: selectedPriorities,
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    isOpen = true;
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    isOpen = false;
  }
}

class ViewMenuOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final ValueNotifier<bool> showCompletedTasks;
  final ValueNotifier<String> sortBy;
  final ValueNotifier<Set<TaskPriority>> selectedPriorities;

  const ViewMenuOverlay({
    super.key,
    required this.onClose,
    required this.showCompletedTasks,
    required this.sortBy,
    required this.selectedPriorities,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Filter by Priority'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: TaskPriority.values.map((priority) {
                              return ValueListenableBuilder<Set<TaskPriority>>(
                                valueListenable: selectedPriorities,
                                builder: (context, priorities, _) {
                                  return FilterChip(
                                    label: Text(priority.name.toUpperCase()),
                                    selected: priorities.contains(priority),
                                    onSelected: (selected) {
                                      final newPriorities = Set<TaskPriority>.from(priorities);
                                      if (selected) {
                                        newPriorities.add(priority);
                                      } else {
                                        newPriorities.remove(priority);
                                      }
                                      selectedPriorities.value = newPriorities;
                                    },
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sort by'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Priority',
                              'Due Date',
                              'Created',
                            ].map((option) {
                              return ValueListenableBuilder<String>(
                                valueListenable: sortBy,
                                builder: (context, currentSort, _) {
                                  return ChoiceChip(
                                    label: Text(option),
                                    selected: currentSort.toLowerCase() == option.toLowerCase(),
                                    onSelected: (selected) {
                                      if (selected) {
                                        sortBy.value = option.toLowerCase();
                                      }
                                    },
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Show Completed Tasks'),
                          ValueListenableBuilder<bool>(
                            valueListenable: showCompletedTasks,
                            builder: (context, value, _) {
                              return Switch(
                                value: value,
                                onChanged: (newValue) {
                                  showCompletedTasks.value = newValue;
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}