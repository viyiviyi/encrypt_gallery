import 'package:flutter/widgets.dart';

class WorkStatus with ChangeNotifier {
  var dencodeIng = false;
  var encodeIng = false;
  var paths = <String, bool>{};

  void setDencodeIng(bool isIng) {
    dencodeIng = isIng;
    notifyListeners();
  }

  void setEncodeIng(bool isIng) {
    encodeIng = isIng;
    notifyListeners();
  }

  void addPath(String path) {
    paths[path] = true;
    notifyListeners();
  }

  bool isRun(String path) {
    return paths[path] ?? false;
  }

  void delPath(String path) {
    if (paths.containsKey(path)) paths.remove(path);
    notifyListeners();
  }
}
