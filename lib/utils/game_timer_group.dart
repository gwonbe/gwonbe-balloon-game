import 'dart:async';

class GameTimerGroup {
  final Map<Object, Timer> _timers = {};
  bool _disposed = false;

  void once(Object key, Duration duration, void Function() callback) {
    late final Timer timer;
    timer = Timer(duration, () {
      if (_disposed || !identical(_timers[key], timer)) return;
      _timers.remove(key);
      callback();
    });
    _replace(key, timer);
  }

  void periodic(Object key, Duration interval, void Function() callback) {
    late final Timer timer;
    timer = Timer.periodic(interval, (_) {
      if (!_disposed && identical(_timers[key], timer)) callback();
    });
    _replace(key, timer);
  }

  void cancel(Object key) {
    _timers.remove(key)?.cancel();
  }

  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  void dispose() {
    _disposed = true;
    cancelAll();
  }

  void _replace(Object key, Timer timer) {
    if (_disposed) {
      timer.cancel();
      return;
    }
    _timers.remove(key)?.cancel();
    _timers[key] = timer;
  }
}
