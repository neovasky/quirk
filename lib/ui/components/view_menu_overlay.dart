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
        const  menuWidth = 300.0;
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

class MenuSection {
  final String title;
  final Widget child;

  const MenuSection({required this.title, required this.child});
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
  String _sortBy = 'priority';
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
                ..._buildSections(theme),
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

  List<Widget> _buildSections(ThemeData theme) {
    final sections = [
      MenuSection(
        title: 'Filter by Priority',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TaskPriority.values.map((priority) {
            return FilterChip(
              label: Text(priority.name.toUpperCase()),
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
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              selectedColor: priority.color.withOpacity(0.2),
              labelStyle: TextStyle(
                color: _selectedPriorities.contains(priority)
                  ? priority.color
                  : theme.colorScheme.onSurface,
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ),
      MenuSection(
        title: 'Sort by',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSortOption('Priority', 'priority', Icons.flag_outlined, theme),
            _buildSortOption('Due Date', 'dueDate', Icons.calendar_today_outlined, theme),
            _buildSortOption('Created', 'created', Icons.access_time_outlined, theme),
          ],
        ),
      ),
      MenuSection(
        title: 'Visibility',
        child: SwitchListTile(
          title: const Text('Show Completed Tasks'),
          value: _showCompleted,
          onChanged: (value) {
            setState(() => _showCompleted = value);
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
    ];

    return sections.map((section) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              section.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: section.child,
          ),
          if (section != sections.last)
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
        ],
      );
    }).toList();
  }

  Widget _buildSortOption(String label, String value, IconData icon, ThemeData theme) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _sortBy = value);
        }
      },
    );
  }
}