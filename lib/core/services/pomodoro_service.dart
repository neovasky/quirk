// lib/core/services/pomodoro_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_settings.dart';

enum TimerState { stopped, running, paused }
enum TimerType { work, shortBreak, longBreak }

class PomodoroService extends ChangeNotifier {
  Timer? _timer;
  TimerState _state = TimerState.stopped;
  TimerType _type = TimerType.work;
  int _currentCycle = 0;
  int _remainingSeconds = 0;
  
  late TimerSettings _settings;
  final SharedPreferences prefs;

  // Changed constructor to take SharedPreferences
  PomodoroService(this.prefs) {
    _loadSettings();
  }

  // Getters
  TimerState get state => _state;
  TimerType get type => _type;
  int get remainingSeconds => _remainingSeconds;
  int get currentCycle => _currentCycle;
  int get totalCycles => _settings.cycles;
  double get progress {
    final currentDuration = _getCurrentDuration();
    return currentDuration == 0 ? 0 : (_getCurrentDuration() - _remainingSeconds) / _getCurrentDuration();
  }
  TimerSettings get settings => _settings;  // Added settings getter

  void _loadSettings() {
    final settingsJson = prefs.getString('timer_settings');
    if (settingsJson != null) {
      try {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        _settings = TimerSettings.fromJson(settingsMap);
      } catch (e) {
        _settings = const TimerSettings();
      }
    } else {
      _settings = const TimerSettings();
    }
    _remainingSeconds = _settings.workDurationInSeconds;
  }

  Future<void> updateSettings(TimerSettings newSettings) async {  // Changed method signature
    _settings = newSettings;
    await prefs.setString('timer_settings', json.encode(newSettings.toJson()));
    if (_state == TimerState.stopped) {
      _remainingSeconds = _settings.workDurationInSeconds;
    }
    notifyListeners();
  }

  // Rest of the methods remain the same...
  void startTimer() {
    if (_state == TimerState.paused) {
      _resumeTimer();
      return;
    }

    _state = TimerState.running;
    if (_currentCycle == 0) {
      _currentCycle = 1;
      _type = TimerType.work;
      _remainingSeconds = _settings.workDurationInSeconds;
    }
    _startCountdown();
    notifyListeners();
  }

  void pauseTimer() {
    _timer?.cancel();
    _state = TimerState.paused;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _state = TimerState.stopped;
    _currentCycle = 0;
    _type = TimerType.work;
    _remainingSeconds = _settings.workDurationInSeconds;
    notifyListeners();
  }

  void _resumeTimer() {
    _state = TimerState.running;
    _startCountdown();
    notifyListeners();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _handleTimerComplete();
      }
    });
  }

  int _getCurrentDuration() {
    switch (_type) {
      case TimerType.work:
        return _settings.workDurationInSeconds;
      case TimerType.shortBreak:
        return _settings.shortBreakInSeconds;
      case TimerType.longBreak:
        return _settings.longBreakInSeconds;
    }
  }

  void _handleTimerComplete() {
    _timer?.cancel();
    
    if (_type == TimerType.work) {
      if (_currentCycle >= _settings.cycles) {
        _type = TimerType.longBreak;
        _remainingSeconds = _settings.longBreakInSeconds;
      } else {
        _type = TimerType.shortBreak;
        _remainingSeconds = _settings.shortBreakInSeconds;
      }
    } else {
      _type = TimerType.work;
      if (_type == TimerType.longBreak) {
        _currentCycle = 1;
      } else {
        _currentCycle++;
      }
      _remainingSeconds = _settings.workDurationInSeconds;
    }

    if (_settings.autoStartBreaks) {
      _startCountdown();
    } else {
      _state = TimerState.paused;
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}