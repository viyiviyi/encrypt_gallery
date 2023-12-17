import 'dart:io';

import 'package:encrypt_gallery/model/dirs_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Widgets/gallery.dart';

Future<bool> _checkPermission() async {
  // 先对所在平台进行判断
  if (Platform.isAndroid) {
    await Permission.storage.request();
  } else {
    return true;
  }
  return false;
}

_initApp() async {
  await _checkPermission();
  WidgetsFlutterBinding.ensureInitialized();
  Hive.initFlutter('encrypt_gallery');
  Hive.registerAdapter(ImageDirAdapter());
}

void main() {
  _initApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '图片解密',
      theme: ThemeData.dark(),
      home: const Gallery(),
    );
  }
}
