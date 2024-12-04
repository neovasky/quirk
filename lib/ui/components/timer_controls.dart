// lib/ui/components/timer_controls.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/pomodoro_service.dart';

class TimerControls extends StatelessWidget {
  const TimerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroService>(
      builder: (context, timer, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (timer.state != TimerState.running)
              FloatingActionButton(
                onPressed: () => timer.startTimer(),
                child: const Icon(Icons.play_arrow),
              ),
            if (timer.state == TimerState.running)
              FloatingActionButton(
                onPressed: () => timer.pauseTimer(),
                child: const Icon(Icons.pause),
              ),
            const SizedBox(width: 16),
            FloatingActionButton(
              onPressed: () => timer.resetTimer(),
              child: const Icon(Icons.refresh),
            ),
          ],
        );
      },
    );
  }
}