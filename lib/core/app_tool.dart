import 'package:flutter/material.dart';

Future<dynamic> navigatorPage(BuildContext context, StatefulWidget page) {
  return Navigator.of(context)
      .push(MaterialPageRoute(builder: (context) => page));
}

int? toInt(dynamic input) {
  try {
    if (input == null) return null;
    if (input.runtimeType == int) return input;
    if (input.runtimeType == String) return int.parse(input);
    return 0;
  } catch (e) {
    return 0;
  }
}
