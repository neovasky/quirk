import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/pomodoro_service.dart';
import '../dialogs/timer_settings_dialog.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ChangeNotifierProvider(
          create: (_) => PomodoroService(snapshot.data!),
          child: const PomodoroContent(),
        );
      },
    );
  }
}


class PomodoroContent extends StatelessWidget {
  const PomodoroContent({super.key});

  @override  // Added this annotation
  Widget build(BuildContext context) {
    return Consumer<PomodoroService>(
      builder: (context, timer, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pomodoro Timer'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => TimerSettingsDialog(
                      currentSettings: timer.settings,
                      onSettingsChanged: (newSettings) {
                        timer.updateSettings(newSettings);
                        timer.resetTimer(); // Reset the timer with new settings
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          body: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TimerDisplay(),
                SizedBox(height: 32),
                TimerControls(),
                SizedBox(height: 32),
                SessionInfo(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<PomodoroService>();
    final minutes = timer.remainingSeconds ~/ 60;
    final seconds = timer.remainingSeconds % 60;

    return Column(
      children: [
        Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 300,
          child: LinearProgressIndicator(
            value: timer.progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }
}

class TimerControls extends StatelessWidget {
  const TimerControls({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<PomodoroService>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton.large(
          onPressed: timer.state == TimerState.running
              ? timer.pauseTimer
              : timer.startTimer,
          child: Icon(
            timer.state == TimerState.running
                ? Icons.pause
                : Icons.play_arrow,
          ),
        ),
        const SizedBox(width: 20),
        FloatingActionButton.large(
          onPressed: timer.resetTimer,
          child: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class SessionInfo extends StatelessWidget {
  const SessionInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<PomodoroService>();
    
    return Column(
      children: [
        Text(
          'Cycle ${timer.currentCycle}/${timer.totalCycles}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(
          switch (timer.type) {
            TimerType.work => 'Work Time',
            TimerType.shortBreak => 'Short Break',
            TimerType.longBreak => 'Long Break',
          },
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}