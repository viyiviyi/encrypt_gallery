import 'package:flutter/widgets.dart';

class _TaskKey {}

class Task {
  bool isEncode = false;
  bool isRun = false;
  bool isDone = false;
  int index = 0;
  final String inputPath;
  final String outputPath;
  final String password;
  Task(
      {required this.inputPath,
      required this.outputPath,
      required this.password});
}

class BackgroundTask with ChangeNotifier {
  final List<Task> taskLis = [];

  bool isRun(String inputPath, String outputPath, bool isEncode) {
    return taskLis.any((element) =>
        element.inputPath == inputPath &&
        element.outputPath == outputPath &&
        element.isEncode == isEncode);
  }

  void addTask(Task task) {
    taskLis.add(task);
    notifyListeners();
  }

  void delTask(Task task) {
    taskLis.remove(task);
    notifyListeners();
  }
}
