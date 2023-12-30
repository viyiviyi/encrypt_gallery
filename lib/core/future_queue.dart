import 'dart:async';

class FutureQueue {
  final List<MapEntry<Completer, Function(Completer<dynamic>)>> _queue = [];
  final Map<Future, Completer> _map = {};
  int _runningCount = 0;

  Future<T> add<T>(Function(Completer completer) run) {
    Completer<T> completer = Completer<T>();
    Future<T> future = completer.future;
    _queue.add(MapEntry(completer, run));
    _runNext();
    _map[future] = completer;
    return future;
  }

  void dispose(Future future) {
    var completer = _map[future];
    if (completer != null) {
      completer.completeError(Exception('提前结束Future'));
      _queue.removeWhere((element) => element.key == completer);
      _map.remove(future);
    }
  }

  void _runNext() {
    if (_runningCount >= 3 || _queue.isEmpty) return;
    _runningCount++;
    final future = _queue.removeAt(0);
    Future.sync(() => future.value(future.key)).then((value) {
      _runningCount--;
      _runNext();
    });
  }
}
