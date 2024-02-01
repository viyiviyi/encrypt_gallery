import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt_gallery/core/core.dart';
import 'package:image/image.dart' as img;

class SaveImageArgs {
  final String savePath;
  final String? psw;
  final img.Image image;
  SaveImageArgs({
    this.psw,
    required this.savePath,
    required this.image,
  });
}

/// 请勿传入已经加密的图片
void saveImageToFile(SaveImageArgs args) {
  var im = args.image;
  if (args.psw != null) {
    im = encryptImage(im, args.psw!) ?? im;
  } else {
    im.textData?.remove('Dencrypt');
    im.textData?.remove('EncryptPwdSha');
  }
  File(args.savePath).writeAsBytesSync(img.encodePng(im));
}

class SaveUint8ListImageArgs {
  final String savePath;
  final String? psw;
  final Uint8List data;
  SaveUint8ListImageArgs(
      {required this.savePath, this.psw, required this.data});
}

void saveUint8ListImage(SaveUint8ListImageArgs args) {
  var im = img.decodePng(args.data)!;
  if (args.psw != null) {
    im = encryptImage(im, args.psw!) ?? im;
  }
  File(args.savePath).writeAsBytesSync(img.encodePng(im));
}
