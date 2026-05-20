import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/database_providers.dart';
import '../../services/notification_service.dart';

class TimerState {
  final int elapsedSeconds;
  final bool isRunning;
  final String category;

  TimerState({this.elapsedSeconds = 0, this.isRunning = false, this.category = ''});

  TimerState copyWith({int? elapsedSeconds, bool? isRunning, String? category}) {
    return TimerState(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isRunning: isRunning ?? this.isRunning,
      category: category ?? this.category,
    );
  }
}

class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier() : super(TimerState()) {
    _loadState();
  }

  Timer? _timer;
  int _accumulatedSeconds = 0;
  DateTime? _startTime;

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final isRunning = prefs.getBool('timer_isRunning') ?? false;
    final accumulated = prefs.getInt('timer_accumulated') ?? 0;
    final startMillis = prefs.getInt('timer_startTime');
    final category = prefs.getString('timer_category') ?? '';

    int currentElapsed = accumulated;

    if (isRunning && startMillis != null) {
      _startTime = DateTime.fromMillisecondsSinceEpoch(startMillis);
      final diff = DateTime.now().difference(_startTime!).inSeconds;
      currentElapsed += diff;

      state = TimerState(isRunning: true, elapsedSeconds: currentElapsed, category: category);

      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      
      // Update notification with live chronometer
      NotificationService.showActiveNotification(
          state.category, state.elapsedSeconds, _formatTime(state.elapsedSeconds * 1000));
    } else {
      _accumulatedSeconds = accumulated;
      state = TimerState(isRunning: false, elapsedSeconds: currentElapsed, category: category);
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_isRunning', state.isRunning);
    await prefs.setInt('timer_accumulated', _accumulatedSeconds);
    if (_startTime != null) {
      await prefs.setInt('timer_startTime', _startTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('timer_startTime');
    }
    await prefs.setString('timer_category', state.category);
  }

  void _tick(Timer timer) {
    if (_startTime != null) {
      final diff = DateTime.now().difference(_startTime!).inSeconds;
      state = state.copyWith(elapsedSeconds: _accumulatedSeconds + diff);
    }
  }

  void setCategory(String category) {
    if (!state.isRunning) {
      state = state.copyWith(category: category);
      _saveState();
    }
  }

  void start() {
    if (state.isRunning) return;
    _startTime = DateTime.now();
    state = state.copyWith(isRunning: true);
    _saveState();

    NotificationService.showActiveNotification(
        state.category, state.elapsedSeconds, _formatTime(state.elapsedSeconds * 1000));

    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void pause() {
    if (!state.isRunning) return;
    if (_startTime != null) {
      _accumulatedSeconds += DateTime.now().difference(_startTime!).inSeconds;
    }
    _startTime = null;
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    _saveState();
  }

  Future<void> stopAndSave(WidgetRef ref) async {
    if (state.elapsedSeconds == 0) {
      _accumulatedSeconds = 0;
      _startTime = null;
      state = TimerState(category: state.category);
      _saveState();
      return;
    }
    pause();
    await AwesomeNotifications().cancel(10);
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await ref.read(databaseServiceProvider).saveSession(user.uid, state.category, state.elapsedSeconds);
    }
    _accumulatedSeconds = 0;
    _startTime = null;
    state = TimerState(category: state.category);
    _saveState();
  }

  Future<void> discardTimer() async {
    _timer?.cancel();
    await AwesomeNotifications().cancel(10);
    _accumulatedSeconds = 0;
    _startTime = null;
    state = TimerState(category: state.category);
    await _saveState();
  }

  String _formatTime(int milliseconds) {
    int seconds = (milliseconds / 1000).truncate() % 60;
    int minutes = (milliseconds / (1000 * 60)).truncate() % 60;
    int hours = (milliseconds / (1000 * 60 * 60)).truncate();
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) => TimerNotifier());