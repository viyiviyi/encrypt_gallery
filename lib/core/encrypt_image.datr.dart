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

FutureQueue<LoadResult> _loadImageProviderQueue = FutureQueue(3);
// 临时保存，防止多次发起请求
Map<String, List<Completer<LoadResult>>> _loadImageProviderCache = {};
Map<String, Future<LoadResult>> _futureMap = {};
Map<String, LoadResult> _history = {};
List<String> _historyKey = [];
Completer<LoadResult> loadImageProvider(LoadArg config) {
  Completer<LoadResult> completer = Completer<LoadResult>();
  if (_history[config.path] != null) {
    completer.complete(_history[config.path]);
    return completer;
  }
  Future<LoadResult> future;
  if (_loadImageProviderCache[config.path] != null) {
    _loadImageProviderCache[config.path]!.add(completer);
    return completer;
  } else {
    _loadImageProviderCache[config.path] = [completer];
    future = _loadImageProviderQueue.add(() {
      return compute(_loadImageProvider, config).then((result) {
        return result;
      });
    });
    _futureMap[config.path] = future;
    future.then((value) {
      _futureMap.remove(config.path);
      if (value.image != null) {
        _history[config.path] = value;
        _historyKey.add(config.path);
      }
      if (_historyKey.length > 5) {
        _history.remove(_historyKey.removeAt(0));
      }
      _loadImageProviderCache.remove(config.path)?.forEach((completer) {
        completer.complete(value);
      });
    });
  }
  return completer;
}

// 丢弃一个请求，用于在组件被销毁时
void loadImageProviderDisable(
    String imagePath, Completer<LoadResult> delCompleter) {
  if (_loadImageProviderCache[imagePath] != null) {
    var idx = _loadImageProviderCache[imagePath]!.indexOf(delCompleter);
    var completer = _loadImageProviderCache[imagePath]!.removeAt(idx);
    completer.completeError('disable');
    if (_loadImageProviderCache[imagePath]!.isEmpty) {
      _loadImageProviderQueue.dispose(_futureMap.remove(imagePath)!);
    }
    _loadImageProviderCache.remove(imagePath);
  }
}

Future<LoadResult> _loadImageProvider(LoadArg config) async {
  var startTime = DateTime.now();
  var image = await loadImage(config);
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
    Future.sync(() {
      var thumbnail = img.copyResize(image, width: thumbnailWidth);
      var thumbnailPath =
          getThumbnailPath(config.cachePath!, config.path, config.pwd);
      var imgFile = File(thumbnailPath);
      imgFile.writeAsBytesSync(
          img.encodeJpg(thumbnail, quality: 80, chroma: img.JpegChroma.yuv420));
    }).then((value) => null);
  }
  var provider = imageToImageProvider(image);
  if (kDebugMode) {
    print('loadimage: ${DateTime.now().difference(startTime).inMilliseconds}');
  }
  return LoadResult(image, provider);
}

Uint8List imgToUint8List(img.Image image) {
  return img.encodeJpg(image, quality: 100, chroma: img.JpegChroma.yuv444);
}

// 加载图片Image对象
Future<img.Image?> loadImage(LoadArg config) async {
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
    return img.decodeImageFile(eFile.absolute.path);
  }

  var image = await img.decodeImageFile(file.absolute.path).catchError((err) {
    return img
        .decodePngFile(file.absolute.path)
        .then((value) => value)
        .catchError((err) => null);
  });
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
  return MemoryImage(img.encodeBmp(image));
}

Future dencryptAllImage(Map<String, String> config) async {
  var path = config['inputPath'];
  var outputPath = config['outputPath'];
  var password = config['password'];
  if (path == null || outputPath == null || password == null) return;
  var dir = Directory(path);
  var outputDir = Directory(outputPath);
  if (!dir.existsSync()) return;
  if (!outputDir.existsSync()) outputDir.createSync();
  FutureQueue queue = FutureQueue(8);
  for (var file in dir.listSync()) {
    if (!RegExp(r'(.png|.jpg|.jpeg|.webp)$').hasMatch(file.path)) continue;
    var stat = file.statSync();
    if (stat.type != FileSystemEntityType.file) continue;
    var fileName = getPathName(file.absolute.path);
    var outputPath = '${outputDir.path}/$fileName';
    if (File(outputPath).existsSync()) continue;
    queue.add(() async {
      return await compute(_denctyptImage, {
        'imagePath': file.path,
        'password': password,
        'savePath': outputPath
      }).then((value) => null);
    });
  }
  return queue.awaitAll();
}

Future _denctyptImage(Map<String, String> input) async {
  var image = await img.decodeImageFile(input['imagePath']!).catchError((err) {
    return img
        .decodePngFile(input['imagePath']!)
        .then((value) => value)
        .catchError((err) => null);
  });
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
    queue.add(() async {
      return await compute(_enctyptImage, {
        'imagePath': file.path,
        'password': password,
        'savePath': outputPath
      }).then((value) => null);
    });
  }
  return queue.awaitAll();
}

Future _enctyptImage(Map<String, String> input) async {
  var image =
      await img.decodePngFile(input['imagePath']!).catchError((err) => null);
  if (image == null) {
    var im = await img.decodeImageFile(input['imagePath']!);
    if (im == null) return;
    image = img.decodePng(img.encodePng(im));
    if (image == null) return;
  }
  image = encryptImage(image, input['password']!);
  if (image == null) return;
  File(input['savePath']!).writeAsBytesSync(img.encodePng(image));
}
