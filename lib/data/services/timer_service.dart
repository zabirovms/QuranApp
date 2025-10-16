import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimerService extends StateNotifier<int> {
  Timer? _timer;

  TimerService() : super(0);

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state + 1;
    });
  }

  void pause() {
    _timer?.cancel();
  }

  void reset() {
    _timer?.cancel();
    state = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerServiceProvider = StateNotifierProvider<TimerService, int>((ref) => TimerService());
