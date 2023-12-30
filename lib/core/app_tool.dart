import 'dart:io';

import 'package:encrypt_gallery/core/consts.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'core.dart';

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

Future<Directory> getTempDir() async {
  return getTemporaryDirectory().then((tempDir) {
    var dir = Directory('${tempDir.path}/$cachePathName');
    if (!dir.existsSync()) {
      dir.createSync();
    }
    return dir;
  });
}

RegExp _p = RegExp(r'/|\\');
String getPathName(String path) {
  return path.substring(path.lastIndexOf(_p) + 1);
}

String getThumbnailPath(String cacheDir, String imagePath, String encryptPwd) {
  var cacheName = getSha256(imagePath + encryptPwd);
  return '$cacheDir/$cacheName';
}
