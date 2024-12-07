import 'package:flutter/material.dart';
import '../../core/models/task_priority.dart';

class ViewMenuController {
  OverlayEntry? _overlayEntry;
  bool isOpen = false;

  void show(BuildContext context, GlobalKey buttonKey) {
    if (isOpen) return;

    final RenderBox buttonBox = buttonKey.currentContext!.findRenderObject() as RenderBox;
    final buttonPosition = buttonBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        const menuWidth = 300.0;
        const rightPadding = 16.0;
        final left = screenWidth - menuWidth - rightPadding;

        return Stack(
          children: [
            // Backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: hide,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black12),
              ),
            ),
            // Menu
            Positioned(
              top: buttonPosition.dy + buttonBox.size.height + 8,
              left: left,
              child: ViewMenuOverlay(
                onClose: hide,
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

class ViewMenuOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const ViewMenuOverlay({
    super.key,
    required this.onClose,
  });

  @override
  State<ViewMenuOverlay> createState() => _ViewMenuOverlayState();
}

class _ViewMenuOverlayState extends State<ViewMenuOverlay> with SingleTickerProviderStateMixin {
  final Set<TaskPriority> _selectedPriorities = {};
  bool _showCompleted = false;
  String _grouping = 'None';
  String _sorting = 'Manual';
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 300,
          constraints: const BoxConstraints(maxHeight: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                
                // View Options
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildViewOption('List', Icons.list, true),
                      _buildViewOption('Board', Icons.view_kanban, false),
                      _buildViewOption('Calendar', Icons.calendar_today, false),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Show Completed Tasks Toggle
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Completed tasks'),
                  trailing: Switch(
                    value: _showCompleted,
                    onChanged: (value) {
                      setState(() => _showCompleted = value);
                    },
                  ),
                ),
                
                const Divider(),
                
                // Sort By Section
                _buildSection('Sort by', [
                  ListTile(
                    leading: const Icon(Icons.sort),
                    title: const Text('Grouping'),
                    trailing: DropdownButton<String>(
                      value: _grouping,
                      items: ['None', 'Priority', 'Due Date'].map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _grouping = value);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sort),
                    title: const Text('Sorting'),
                    trailing: DropdownButton<String>(
                      value: _sorting,
                      items: ['Manual', 'Due Date', 'Priority'].map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _sorting = value);
                        }
                      },
                    ),
                  ),
                ]),
                
                const Divider(),
                
                // Filter By Section
                _buildSection('Filter by', [
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Due date'),
                    trailing: const Text('All'),
                    onTap: () {
                      // Handle due date filter
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.flag),
                    title: const Text('Priority'),
                    trailing: const Text('All'),
                    onTap: () {
                      // Handle priority filter
                    },
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
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
            onPressed: widget.onClose,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewOption(String label, IconData icon, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    if (title == 'Filter by') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Due date'),
            trailing: const Text('All'),
            onTap: () {
              // Handle due date filter
            },
          ),
          // Priority filter with chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Priority'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: TaskPriority.values.map((priority) {
                    return FilterChip(
                      label: Text(priority.name),
                      selected: _selectedPriorities.contains(priority),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPriorities.add(priority);
                          } else {
                            _selectedPriorities.remove(priority);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}