import 'dart:async';

class DependingFuture {
  dynamic futureFunc;
  Future<dynamic> future;
  List<String> dependsOn;
}

class FutureFlowControl {
  Map<String, DependingFuture> _futures = new Map();
  Map<String, dynamic> _results = new Map();
  String _curKey = '';
  Completer<Map<String, dynamic>> _completer = new Completer();

  FutureFlowControl add(String key,
      {Future<dynamic> futureFunc(Map<String, dynamic> resultMap),
        Future<dynamic> future}) {
    this._curKey = key;
    if (futureFunc != null) this._futures[key]?.futureFunc = futureFunc;
    if (future != null) this._futures[key]?.future = future;
    return this;
  }

  FutureFlowControl dependsOn(List<String> keys) {
    if (_curKey.length > 0 && this._futures[_curKey] != null)
      this._futures[_curKey].dependsOn = keys;
    return this;
  }

  Future<Map<String, dynamic>> run() async {
    _runPossible();
    return this._completer.future;
  }

  void _runPossible() {
    _futures.forEach((key, depFuture) {
      if (depFuture.dependsOn.length == 0 && _results[key] == null) {
        if(depFuture.future != null)
          depFuture.future.then((val) => _whenCompleted(key, val));
        if (depFuture.futureFunc != null)
          depFuture.futureFunc(_results).then((val) => _whenCompleted(key, val));
      }
    });
  }

  void _whenCompleted(String key, dynamic val) {
    _futures.forEach((key, depFuture) {
      depFuture.dependsOn.removeWhere((k) => k == key);
    });
    this._results[key] = val;
    if (this._results.length < this._futures.length)
      this._runPossible();
    else
      this._completer.complete(this._results);
  }
}