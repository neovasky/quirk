// lib/core/models/timer_settings.dart

class TimerSettings {
  final int workDurationMin;
  final int workDurationSec;
  final int shortBreakMin;
  final int shortBreakSec;
  final int longBreakMin;
  final int longBreakSec;
  final int cycles;
  final bool autoStartBreaks;

  const TimerSettings({
    this.workDurationMin = 25,
    this.workDurationSec = 0,
    this.shortBreakMin = 5,
    this.shortBreakSec = 0,
    this.longBreakMin = 15,
    this.longBreakSec = 0,
    this.cycles = 4,
    this.autoStartBreaks = true,
  });

  int get workDurationInSeconds => workDurationMin * 60 + workDurationSec;
  int get shortBreakInSeconds => shortBreakMin * 60 + shortBreakSec;
  int get longBreakInSeconds => longBreakMin * 60 + longBreakSec;

  factory TimerSettings.fromJson(Map<String, dynamic> json) {
    return TimerSettings(
      workDurationMin: json['workDurationMin'] ?? 25,
      workDurationSec: json['workDurationSec'] ?? 0,
      shortBreakMin: json['shortBreakMin'] ?? 5,
      shortBreakSec: json['shortBreakSec'] ?? 0,
      longBreakMin: json['longBreakMin'] ?? 15,
      longBreakSec: json['longBreakSec'] ?? 0,
      cycles: json['cycles'] ?? 4,
      autoStartBreaks: json['autoStartBreaks'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workDurationMin': workDurationMin,
      'workDurationSec': workDurationSec,
      'shortBreakMin': shortBreakMin,
      'shortBreakSec': shortBreakSec,
      'longBreakMin': longBreakMin,
      'longBreakSec': longBreakSec,
      'cycles': cycles,
      'autoStartBreaks': autoStartBreaks,
    };
  }
}

class TimerPreset {
  final String name;
  final TimerSettings settings;

  const TimerPreset(this.name, this.settings);

  static const List<TimerPreset> presets = [
    TimerPreset('Regular', TimerSettings()),
    TimerPreset('Quick', TimerSettings(
      workDurationMin: 15,
      shortBreakMin: 3,
      longBreakMin: 10,
    )),
    TimerPreset('Extended', TimerSettings(
      workDurationMin: 45,
      shortBreakMin: 10,
      longBreakMin: 20,
    )),
    TimerPreset('Endurance', TimerSettings(
      workDurationMin: 50,
      shortBreakMin: 10,
      longBreakMin: 30,
    )),
  ];
}