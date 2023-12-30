import 'package:flutter/widgets.dart';

class WorkStatus with ChangeNotifier {
  var dencodeIng = false;
  var encodeIng = false;
  void setDencodeIng(bool isIng) {
    dencodeIng = isIng;
    notifyListeners();
  }

  void setEncodeIng(bool isIng) {
    encodeIng = isIng;
    notifyListeners();
  }
}
