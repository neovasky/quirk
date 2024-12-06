import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/task.dart';

class TaskListTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final bool isDraggable;
  final bool isDragging;
  final bool isHighlighted;

  const TaskListTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onComplete,
    this.isDraggable = false,
    this.isDragging = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted 
          ? Border.all(color: theme.colorScheme.primary.withOpacity(0.5))
          : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
          child: Row(
            children: [
              CompletionBubble(
                isCompleted: task.completed,
                color: task.priorityColor,
                onComplete: onComplete,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              decoration: task.completed ? TextDecoration.lineThrough : null,
                              color: task.completed ? theme.colorScheme.onSurface.withOpacity(0.6) : null,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onPressed: onTap,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    if (task.project != null || task.duration.inMinutes > 0 || task.dueDate != null)
                      const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      children: [
                        if (task.project != null)
                          _buildMetadata(
                            icon: Icons.folder_outlined,
                            label: task.project!,
                          ),
                        if (task.duration.inMinutes > 0)
                          _buildMetadata(
                            icon: Icons.timer_outlined,
                            label: '${task.duration.inMinutes}m',
                          ),
                        if (task.dueDate != null)
                          _buildMetadata(
                            icon: Icons.calendar_today_outlined,
                            label: _formatDate(task.dueDate!),
                            isOverdue: task.isOverdue,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata({
    required IconData icon,
    required String label,
    bool isOverdue = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isOverdue ? Colors.red[300] : Colors.grey[400],
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isOverdue ? Colors.red[300] : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';

    return '${date.month}/${date.day}';
  }
}

class CompletionBubble extends StatefulWidget {
  final bool isCompleted;
  final Color color;
  final VoidCallback onComplete;

  const CompletionBubble({
    super.key,
    required this.isCompleted,
    required this.color,
    required this.onComplete,
  });

  @override
  State<CompletionBubble> createState() => _CompletionBubbleState();
}

class _CompletionBubbleState extends State<CompletionBubble> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _burstController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _bounceAnimation;
  late List<Animation<double>> _burstAnimations;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..addStatusListener(_onAnimationStatus);

    _burstController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Create 8 burst particles with different angles
    _burstAnimations = List.generate(8, (index) {
      return Tween<double>(begin: 0.0, end: 30.0).animate(
        CurvedAnimation(
          parent: _burstController,
          curve: Curves.easeOut,
        ),
      );
    });

    // Bounce animation sequence
    _bounceAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Checkmark and fill animations
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    if (widget.isCompleted) {
      _controller.value = 1.0;
      _burstController.value = 1.0;
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _isAnimating = false;
      widget.onComplete();  // Call the completion callback after animation finishes
    }
  }

  void _handleTap() {
    if (_isAnimating) return;  // Prevent multiple taps during animation
    
    HapticFeedback.lightImpact();
    
    if (!widget.isCompleted) {
      _isAnimating = true;
      _controller.forward(from: 0.0);
      _burstController.forward(from: 0.0);
    } else {
      _controller.reverse();
      _burstController.reverse();
      widget.onComplete();  // For unchecking, we can call immediately
    }
  }

  @override
  void didUpdateWidget(CompletionBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted && !_isAnimating) {
      if (widget.isCompleted) {
        _controller.value = 1.0;
        _burstController.value = 1.0;
      } else {
        _controller.value = 0.0;
        _burstController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Burst particles
          ...List.generate(8, (index) {
            final angle = (index * 45) * (pi / 180); // Use pi from dart:math
            return AnimatedBuilder(
              animation: _burstAnimations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    cos(angle) * _burstAnimations[index].value,
                    sin(angle) * _burstAnimations[index].value,
                  ),
                  child: Opacity(
                    opacity: (1 - _burstController.value),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          // Main bubble
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      Colors.transparent,
                      widget.color,
                      _scaleAnimation.value,
                    ),
                    border: Border.all(
                      color: widget.color,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: ScaleTransition(
                      scale: _checkAnimation,
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: _scaleAnimation.value > 0 ? Colors.white : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}