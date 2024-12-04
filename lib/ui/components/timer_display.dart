// lib/ui/components/timer_display.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/pomodoro_service.dart';

class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroService>(
      builder: (context, timer, child) {
        final minutes = timer.remainingSeconds ~/ 60;
        final seconds = timer.remainingSeconds % 60;
        
        return Column(
          children: [
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: timer.progress,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(
                timer.progress < 0.5 ? Colors.pink : Colors.orange,
              ),
              minHeight: 10,
            ),
          ],
        );
      },
    );
  }
}