import 'dart:io';
import 'dart:ui';

import 'package:encrypt_gallery/core/hive_box.dart';
import 'package:encrypt_gallery/model/backgound_tasks.dart';
import 'package:encrypt_gallery/model/provider_status.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'Widgets/gallery.dart';

Future<bool> _checkPermission() async {
  // 先对所在平台进行判断
  if (Platform.isAndroid) {
    await Permission.storage.request();
    await Permission.photos.request();
    await Permission.accessMediaLocation.request();
  } else {
    return true;
  }
  return false;
}

Future _initApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _checkPermission();
  initHive();
}

void main() {
  _initApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkStatus()),
        ChangeNotifierProvider(create: (_) => BackgroundTask()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      title: '图片解密',
      theme: ThemeData.dark(),
      home: const Gallery(),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods like buildOverscrollIndicator and buildScrollbar
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
