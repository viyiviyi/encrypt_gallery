import 'dart:convert';

import 'package:encrypt_gallery/core/core.dart';
import 'package:encrypt_gallery/core/hive_box.dart';
import 'package:hive/hive.dart';

class ImageDir {
  String rootPath;
  String psw;
  ImageDir({required this.rootPath, required this.psw});

  static ImageDir fromJson(dynamic data) {
    ImageDir imageDir = ImageDir(rootPath: data['rootPath'], psw: data['psw']);
    return imageDir;
  }

  dynamic toJson() {
    return {
      'rootPath': this.rootPath,
      'psw': this.psw,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class ImageDirAdapter extends TypeAdapter<ImageDir> {
  @override
  final typeId = 1;

  @override
  ImageDir read(BinaryReader reader) {
    var d = reader.read();
    return ImageDir.fromJson(d);
  }

  @override
  void write(BinaryWriter writer, ImageDir obj) {
    writer.write(obj.toJson());
  }
}

Future<Box<ImageDir>>? _imageDirDb;

Future<Box<ImageDir>> getBox() {
  if (_imageDirDb != null) return _imageDirDb!;
  _imageDirDb = initHive().then((value) => Hive.openBox<ImageDir>('ImageDirs'));
  return _imageDirDb!;
}

Future<List<ImageDir>> getAllImageDir() {
  return getBox().then((box) {
    return box.values.toList();
  });
}

Future deleteImageDir(String path) {
  var key = getSha256(path);
  return getBox().then((box) {
    if (box.containsKey(key)) box.delete(key);
  });
}

Future createOrUpdateImageDir(ImageDir imageDir) {
  var key = getSha256(imageDir.rootPath);
  return getBox().then((box) {
    box.put(key, imageDir);
  });
}
