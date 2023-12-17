import 'dart:io';

import 'package:encrypt_gallery/core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

class LoadArg {
  String? cachePath;
  String path;
  String pwd;
  LoadArg({required this.path, required this.pwd, this.cachePath});
}

ImageProvider? loadImageProvider(LoadArg config) {
  var image = loadImage(config);
  if (image == null) {
    return null;
  }
  // 保存缩列图
  if (config.cachePath != null && config.cachePath != '') {
    var thumbnail = img.copyResize(image, width: 200);
    var cacheName = getSha256(config.path);
    var imgFile = File('${config.cachePath}/$cacheName');
    imgFile.writeAsBytesSync(img.encodePng(thumbnail));
  }
  return MemoryImage(img.encodePng(image));
}

img.Image? loadImage(LoadArg config) {
  var file = File(config.path);
  if (!file.existsSync()) {
    if (kDebugMode) {
      print('文件 ${config.path} 不存在');
    }
    return null;
  }
  // dencrypt_output 是解密后的文件保存目录
  var lIdx = config.path.lastIndexOf(RegExp(r'/|\\'));
  var fileName = config.path.substring(lIdx + 1);
  var dir = config.path.substring(0, lIdx);
  var eFile = File('$dir/dencrypt_output/$fileName');

  if (eFile.existsSync()) {
    return img.decodeImage(eFile.readAsBytesSync());
  }

  var image = img.decodeImage(file.readAsBytesSync());
  if (image == null) {
    if (kDebugMode) {
      print('文件 ${config.path} 读取失败');
    }
    return null;
  }
  var startTime = DateTime.now();
  image = dencryptImage(image, config.pwd) ?? image;
  if (kDebugMode) {
    print('encrypt: ${DateTime.now().difference(startTime).inMilliseconds}');
  }
  return image;
}

ImageProvider imageToImageProvider(img.Image image) {
  return MemoryImage(img.encodePng(image));
}

void dencryptAllImage(LoadArg config) {
  var path = config.path;
  var dir = Directory(path);
  var outputDir = Directory('$path/dencrypt_output');
  if (!dir.existsSync()) return;
  if (!outputDir.existsSync()) outputDir.createSync();
  for (var file in dir.listSync()) {
    if (!RegExp(r'(.png|.jpg|.jpeg|.webp)$').hasMatch(file.path)) continue;
    var stat = file.statSync();
    if (stat.type != FileSystemEntityType.file) continue;
    var fileName =
        file.path.substring(file.path.lastIndexOf(RegExp(r'/|\\')) + 1);
    var outputPath = '${outputDir.path}/$fileName';
    if (File(outputPath).existsSync()) continue;
    var image = img.decodeImage(File(file.path).readAsBytesSync());
    if (image == null) continue;
    image = dencryptImage(image, config.pwd);
    if (image == null) continue;
    File(outputPath).writeAsBytesSync(img.encodePng(image));
  }
}

void encryptAllImage(LoadArg config) {
  var path = config.path;
  var dir = Directory(path);
  var outputDir = Directory('$path/encrypt_output');
  if (!dir.existsSync()) return;
  if (!outputDir.existsSync()) outputDir.createSync();
  for (var file in dir.listSync()) {
    if (!RegExp(r'(.png|.jpg|.jpeg|.webp)$').hasMatch(file.path)) continue;
    var stat = file.statSync();
    if (stat.type != FileSystemEntityType.file) continue;
    var fileName =
        file.path.substring(file.path.lastIndexOf(RegExp(r'/|\\')) + 1);
    var outputPath = '${outputDir.path}/$fileName';
    if (File(outputPath).existsSync()) continue;
    var image = img.decodeImage(File(file.path).readAsBytesSync());
    if (image == null) continue;
    image = encryptImage(image, config.pwd);
    if (image == null) continue; // 表示不需要解密
    File(outputPath).writeAsBytesSync(img.encodePng(image));
  }
}
