import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../services/auth_service.dart';
import '../../services/database_providers.dart';
import '../../services/notification_service.dart';

class TimerState {
  final int elapsedSeconds;
  final bool isRunning;
  final String category;

  TimerState({this.elapsedSeconds = 0, this.isRunning = false, this.category = 'Deep Work'});

  TimerState copyWith({int? elapsedSeconds, bool? isRunning, String? category}) {
    return TimerState(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isRunning: isRunning ?? this.isRunning,
      category: category ?? this.category,
    );
  }
}

class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier() : super(TimerState());

  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  void setCategory(String category) {
    if (!state.isRunning) state = state.copyWith(category: category);
  }

  void start() {
    if (state.isRunning) return;
    _stopwatch.start();
    state = state.copyWith(isRunning: true);

    NotificationService.showActiveNotification(state.category, _formatTime(_stopwatch.elapsedMilliseconds));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(elapsedSeconds: _stopwatch.elapsed.inSeconds);
      // Update background notification every minute to stay active safely
      if (state.elapsedSeconds % 60 == 0) {
        NotificationService.showActiveNotification(state.category, _formatTime(_stopwatch.elapsedMilliseconds));
      }
    });
  }

  void pause() {
    _stopwatch.stop();
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  Future<void> stopAndSave(WidgetRef ref) async {
    if (state.elapsedSeconds == 0) {
      _stopwatch.reset();
      state = TimerState(category: state.category);
      return;
    }
    pause();
    await AwesomeNotifications().cancel(10);
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await ref.read(databaseServiceProvider).saveSession(user.uid, state.category, state.elapsedSeconds);
    }
    _stopwatch.reset();
    state = TimerState(category: state.category);
    NotificationService.showIdleNotification();
  }

  String _formatTime(int milliseconds) {
    int seconds = (milliseconds / 1000).truncate() % 60;
    int minutes = (milliseconds / (1000 * 60)).truncate() % 60;
    int hours = (milliseconds / (1000 * 60 * 60)).truncate();
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) => TimerNotifier());