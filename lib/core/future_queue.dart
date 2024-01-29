import 'dart:async';

class FutureQueue {
  final List<MapEntry<Completer, Function(Completer<dynamic>)>> _queue = [];
  final Map<Future, Completer> _map = {};
  final List<Completer> _waiting = [];
  final Map<Completer, bool> _runing = {};
  late int max = 6;
  int _runningCount = 0;

  FutureQueue([this.max = 6]);

  Future<T> add<T>(Function(Completer completer) run) {
    Completer<T> completer = Completer<T>();
    Future<T> future = completer.future;
    _queue.insert(0, MapEntry(completer, run));
    _runNext();
    _map[future] = completer;
    return future;
  }

  bool isRuning(Future future) {
    return _runing.containsKey(_map[future]);
  }

  void dispose(Future future) {
    var completer = _map[future];
    if (completer != null) {
      completer.completeError(Exception('提前结束Future'));
      _queue.removeWhere((element) => element.key == completer);
      _map.remove(future);
      if (_queue.isEmpty) {
        for (var completer in _waiting) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      }
    }
  }

  void _runNext() {
    if (_queue.isEmpty) {
      for (var completer in _waiting) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }
    if (_runningCount >= max || _queue.isEmpty) return;
    _runningCount++;
    final future = _queue.removeAt(0);
    _runing[future.key] = true;
    Future.sync(() => future.value(future.key)).then((value) {
      _runningCount--;
      _runing.remove(future);
      _runNext();
    });
  }

  Future awaitAll() async {
    Completer completer = Completer();
    _waiting.add(completer);
    return completer.future;
  }
}
