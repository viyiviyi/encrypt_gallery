import 'dart:async';

class FutureQueue<T> {
  final List<Future<T> Function()> _queue = [];
  final Map<Future, Future<T> Function()> _map = {};
  final Map<Future<T> Function(), Completer> _funComponentMap = {};
  final List<Completer> _waiting = []; // 正在等待全部执行完成的Completer列表
  late int max = 6;
  int _runningCount = 0;

  FutureQueue([this.max = 6]);

  Future<T> add(Future<T> Function() run) {
    Completer<T> completer = Completer<T>();
    Future<T> future = completer.future;
    _queue.add(run);
    _map[future] = run;
    _funComponentMap[run] = completer;
    _runNext();
    return future;
  }

  Future<T> insert0(Future<T> Function() run) {
    Completer<T> completer = Completer<T>();
    Future<T> future = completer.future;
    _queue.insert(0, run);
    _map[future] = run;
    _funComponentMap[run] = completer;
    _runNext();
    return future;
  }

  /// 提前队列中的项并获取新的Future，可以复用之前的进度，同时结束之前的Future
  Future<T> inAdvance(Future<T> future) {
    if (_map.containsKey(future)) {
      var fun = _map[future]!;
      var idx = _queue.indexOf(fun);
      if (idx > 0) {
        // 如果还未执行，提前到第一个
        Completer<T> completer = Completer<T>();
        Future<T> newFuture = completer.future;
        _funComponentMap[fun]?.completeError(Exception('提前Future并放弃旧Future'));
        _map.remove(future);
        _funComponentMap.remove(fun);
        _map[newFuture] = fun;
        _funComponentMap[fun] = completer;
        _queue.insert(0, _queue.removeAt(idx));
        _runNext();
        return newFuture;
      }
    }
    return future;
  }

  bool isRuning(Future future) {
    return _queue.indexWhere((e) => e == _map[future]) != -1;
  }

  void dispose(Future future) {
    var fun = _map[future];
    var completer = _funComponentMap[fun];
    completer?.completeError(Exception('提前结束Future'));
    _queue.removeWhere((element) => fun == element);
    _funComponentMap.remove(fun);
    _map.remove(future);
    if (_queue.isEmpty) {
      for (var completer in _waiting) {
        if (!completer.isCompleted) {
          completer.complete();
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
    final fun = _queue.removeAt(0);
    Future.sync(() => fun()).then((value) {
      _runningCount--;
      _map.removeWhere((key, value) => value == fun);
      final completer = _funComponentMap[fun];
      _funComponentMap.remove(fun);
      if (completer != null) {
        if (!completer.isCompleted) completer.complete(value);
      }
      _runNext();
    });
  }

  Future awaitAll() async {
    Completer completer = Completer();
    _waiting.add(completer);
    return completer.future;
  }
}
