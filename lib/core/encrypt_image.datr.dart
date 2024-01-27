import 'dart:async';
import 'dart:io';

import 'package:encrypt_gallery/core/app_tool.dart';
import 'package:encrypt_gallery/core/core.dart';
import 'package:encrypt_gallery/core/future_queue.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

class LoadArg {
  String? cachePath;
  String path;
  String pwd;
  LoadArg({required this.path, required this.pwd, this.cachePath});
}

class LoadResult {
  img.Image? image;
  ImageProvider? imageProvider;
  LoadResult([this.image, this.imageProvider]);
}

FutureQueue _loadImageProviderQueue = FutureQueue();
Map<String, Future<LoadResult>> _loadImageProviderCache = {}; // 临时保存，防止多次发起请求
Map<String, LoadResult> _history = {};
List<String> _historyKey = [];
Future<LoadResult> loadImageProvider(LoadArg config) async {
  if (_history[config.path] != null) return _history[config.path]!;
  if (_loadImageProviderCache[config.path] != null) {
    return _loadImageProviderCache[config.path]!;
  }
  var future = _loadImageProviderQueue.add<LoadResult>((completer) async {
    if (completer.isCompleted) return;
    var result = await compute(_loadImageProvider, config);
    if (completer.isCompleted) return;
    _history[config.path] = result;
    if (_historyKey.length > 100) {
      _history.remove(_historyKey.removeAt(0));
    }
    completer.complete(result);
  });
  future
      .whenComplete(() => _loadImageProviderCache.remove(config.path)); // 完成时删除
  _loadImageProviderCache[config.path] = future;
  return _loadImageProviderCache[config.path]!;
}

// 丢弃一个请求，用于在组件被销毁时
void loadImageProviderDisable(String imagePath) {
  if (_loadImageProviderCache[imagePath] != null) {
    _loadImageProviderQueue.dispose(_loadImageProviderCache[imagePath]!);
    _loadImageProviderCache.remove(imagePath);
  }
}

LoadResult _loadImageProvider(LoadArg config) {
  var image = loadImage(config);
  if (image == null) {
    return LoadResult();
  }
  // 保存缩列图
  if (config.cachePath != null && config.cachePath != '') {
    var thumbnailWidth = 512;
    if (image.width > image.height) {
      // 如果是宽图，则让缩略图的高保持在200
      thumbnailWidth = 512 * image.width ~/ image.height;
    }
    var thumbnail = img.copyResize(image, width: thumbnailWidth);
    var thumbnailPath =
        getThumbnailPath(config.cachePath!, config.path, config.pwd);
    var imgFile = File(thumbnailPath);
    imgFile.writeAsBytesSync(
        img.encodeJpg(thumbnail, quality: 80, chroma: img.JpegChroma.yuv420));
  }
  var provider = imageToImageProvider(image);
  return LoadResult(image, provider);
}

Uint8List imgToUint8List(img.Image image) {
  return img.encodeJpg(image, quality: 100, chroma: img.JpegChroma.yuv444);
}

// 加载图片Image对象
img.Image? loadImage(LoadArg config) {
  File file = File(config.path);
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
    var image = img.decodeImage(eFile.readAsBytesSync());
    return image;
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

Future dencryptAllImage(Map<String, String> config) async {
  var path = config['inputPath'];
  var outputPath = config['outputPath'];
  var password = config['password'];
  if (path == null || outputPath == null || password == null) return;
  var dir = Directory(path);
  var outputDir = Directory(outputPath);
  // var outputDir = Directory('$path/dencrypt_output');
  if (!dir.existsSync()) return;
  if (!outputDir.existsSync()) outputDir.createSync();
  FutureQueue queue = FutureQueue(8);
  for (var file in dir.listSync()) {
    if (!RegExp(r'(.png|.jpg|.jpeg|.webp)$').hasMatch(file.path)) continue;
    var stat = file.statSync();
    if (stat.type != FileSystemEntityType.file) continue;
    var fileName =
        file.path.substring(file.path.lastIndexOf(RegExp(r'/|\\')) + 1);
    var outputPath = '${outputDir.path}/$fileName';
    if (File(outputPath).existsSync()) continue;
    queue.add((completer) async {
      await compute(_denctyptImage, {
        'imagePath': file.path,
        'password': password,
        'savePath': outputPath
      });
      completer.complete();
    });

    // var image = img.decodeImage(File(file.path).readAsBytesSync());
    // if (image == null) continue;
    // image = dencryptImage(image, password);
    // if (image == null) continue;
    // File(outputPath).writeAsBytesSync(img.encodePng(image));
  }
  return queue.awaitAll();
}

void _denctyptImage(Map<String, String> input) {
  var image = img.decodeImage(File(input['imagePath']!).readAsBytesSync());
  if (image == null) return;
  image = dencryptImage(image, input['password']!);
  if (image == null) return;
  File(input['savePath']!).writeAsBytesSync(img.encodePng(image));
}

Future encryptAllImage(Map<String, String> config) async {
  var path = config['inputPath'];
  var outputPath = config['outputPath'];
  var password = config['password'];
  if (path == null || outputPath == null || password == null) return;
  var dir = Directory(path);
  var outputDir = Directory(outputPath);
  // var outputDir = Directory('$path/encrypt_output');
  if (!dir.existsSync()) return;
  if (!outputDir.existsSync()) outputDir.createSync();
  FutureQueue queue = FutureQueue(8);
  for (var file in dir.listSync()) {
    if (!RegExp(r'(.png|.jpg|.jpeg|.webp)$').hasMatch(file.path)) continue;
    var stat = file.statSync();
    if (stat.type != FileSystemEntityType.file) continue;
    var fileName =
        file.path.substring(file.path.lastIndexOf(RegExp(r'/|\\')) + 1);
    var outputPath = '${outputDir.path}/$fileName';
    if (File(outputPath).existsSync()) continue;
    queue.add((completer) async {
      await compute(_enctyptImage, {
        'imagePath': file.path,
        'password': password,
        'savePath': outputPath
      });
      completer.complete();
    });
    // var image = img.decodeImage(File(file.path).readAsBytesSync());
    // if (image == null) continue;
    // image = encryptImage(image, password);
    // if (image == null) continue; // 表示不需要解密
    // File(outputPath).writeAsBytesSync(img.encodePng(image));
  }
  return queue.awaitAll();
}

void _enctyptImage(Map<String, String> input) {
  var image = img.decodeImage(File(input['imagePath']!).readAsBytesSync());
  if (image == null) return;
  image = dencryptImage(image, input['password']!);
  if (image == null) return;
  File(input['savePath']!).writeAsBytesSync(img.encodePng(image));
}
