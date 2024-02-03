import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:encrypt_gallery/core/core.dart';
import 'package:encrypt_gallery/core/hive_box.dart';
import 'package:encrypt_gallery/model/file_sort_type.dart';
import 'package:hive/hive.dart';

class ImageDir {
  String rootPath;
  String psw;
  String? authUser;
  String? authPsw;
  String? avatorPath;
  FileSortType? sortType;
  ImageDir({required this.rootPath, required this.psw});

  static ImageDir fromJson(dynamic data) {
    ImageDir imageDir = ImageDir(rootPath: data['rootPath'], psw: data['psw']);
    imageDir.authPsw =
        data['authPsw'] != null ? _dencode(data['authPsw']) : null;
    imageDir.authUser = data['authUser'];
    imageDir.sortType = FileSortType.values[data['sortType'] ?? 0];
    imageDir.avatorPath = data['avatorPath'];
    return imageDir;
  }

  static _encode(String input) {
    if (input == '') return;
    final key = Key.fromUtf8('ajjdheu784neurh');
    final iv = IV.fromUtf8('dsdbh7ye');
    final encrypter = Encrypter(Salsa20(key));

    final encrypted = encrypter.encrypt(input, iv: iv);
    return encrypted.base64;
  }

  static _dencode(String input) {
    if (input == '') return;
    final key = Key.fromUtf8('ajjdheu784neurh');
    final iv = IV.fromUtf8('dsdbh7ye');
    final encrypter = Encrypter(Salsa20(key));
    final encrypted = Encrypted.fromUtf8(input);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  }

  dynamic toJson() {
    return {
      'rootPath': rootPath,
      'psw': psw,
      'authUser': authUser,
      'authPsw': authPsw != null ? _encode(authPsw!) : '',
      'sortType': sortType?.index ?? 0,
      'avatorPath': avatorPath,
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

Future deleteImageDir(ImageDir imageDir) {
  var key = getSha256(imageDir.rootPath + imageDir.psw);
  var key2 = getSha256(imageDir.rootPath);
  return getBox().then((box) {
    if (box.containsKey(key2)) box.delete(key2);
    if (box.containsKey(key)) box.delete(key);
  });
}

Future createOrUpdateImageDir(ImageDir imageDir) {
  var key = getSha256(imageDir.rootPath + imageDir.psw);
  return getBox().then((box) {
    box.put(key, imageDir);
  });
}
