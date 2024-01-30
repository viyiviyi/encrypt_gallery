import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

String getRange(String input, int offset, {int rangeLen = 4}) {
  offset = offset % input.length;
  input = input + input;
  return input.substring(offset, offset + rangeLen);
}

String getSha256(String input) {
  var bytes = utf8.encode(input);
  var digest = sha256.convert(bytes);
  return '$digest';
}

List<T> shuffleArr<T>(List<T> arr, String key) {
  String shaKey = getSha256(key);
  int keyLen = shaKey.length;
  int arrLen = arr.length;
  int keyOffset = 0;

  for (int i = 0; i < arrLen; i++) {
    int toIndex =
        int.parse(getRange(shaKey, keyOffset, rangeLen: 8), radix: 16) %
            (arrLen - i);
    keyOffset += 1;
    if (keyOffset >= keyLen) {
      keyOffset = 0;
    }
    var temp = arr[i];
    arr[i] = arr[toIndex];
    arr[toIndex] = temp;
  }

  return arr;
}

List<List<T>> dencryptImageV2<T>(List<List<T>> arr, String psw) {
  int width = arr[0].length;
  int height = arr.length;
  List<int> xArr = List.generate(width, (index) => index);
  shuffleArr(xArr, psw);
  List<int> yArr = List.generate(height, (index) => index);
  shuffleArr(yArr, getSha256(psw));

  // 1920*1080 耗时10几毫秒
  for (int y = height - 1; y >= 0; y--) {
    var y0 = yArr[y];
    var temp = arr[y];
    arr[y] = arr[y0];
    arr[y0] = temp;
  }
  for (int y = height - 1; y >= 0; y--) {
    var row = arr[y];
    for (int x = width - 1; x >= 0; x--) {
      var x0 = xArr[x];
      var temp = row[x];
      row[x] = row[x0];
      row[x0] = temp;
    }
  }

  return arr;
}

Image? encryptImage(Image image, String pwd) {
  var width = image.width;
  var height = image.height;
  if (image.textData == null ||
      !image.textData!.containsKey('Encrypt') ||
      image.textData?['Encrypt'] != 'pixel_shuffle_2') {
    List<int> xArr = List.generate(width, (index) => index);
    shuffleArr(xArr, pwd);
    List<int> yArr = List.generate(height, (index) => index);
    shuffleArr(yArr, getSha256(pwd));
    List<int> xArr0 = List.generate(width, (index) => index);
    List<int> yArr0 = List.generate(height, (index) => index);

    for (int y = 0; y < height; y++) {
      var y0 = yArr[y];
      var temp = yArr0[y];
      yArr0[y] = yArr0[y0];
      yArr0[y0] = temp;
    }
    for (int x = 0; x < width; x++) {
      var x0 = xArr[x];
      var temp = xArr0[x];
      xArr0[x] = xArr0[x0];
      xArr0[x0] = temp;
    }
    var newImg = Image(
        width: width,
        height: height,
        numChannels: image.numChannels,
        exif: image.exif,
        textData: image.textData,
        format: image.format);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        newImg.setPixel(x, y, image.getPixel(xArr0[x], yArr0[y]));
      }
    }
    if (newImg.textData == null) {
      newImg.textData = {
        "Encrypt": "pixel_shuffle_2",
        "EncryptPwdSha": getSha256('${pwd}Encrypt') //保存一个用于校验密码是否正确是密码哈希值
      };
    } else {
      newImg.textData!['Encrypt'] = 'pixel_shuffle_2';
      newImg.textData!['EncryptPwdSha'] = getSha256('${pwd}Encrypt');
    }
    return newImg;
  }
  return null;
}

Image? dencryptImage(Image image, String pwd) {
  var width = image.width;
  var height = image.height;
  if (image.textData?['Encrypt'] == 'pixel_shuffle_2') {
    // 当存在密码哈希属性时检查密码哈希属性的值与当前密码的哈希值是否一致，不一致就不解密
    if (image.textData?['EncryptPwdSha'] != null &&
        image.textData?['EncryptPwdSha'] != getSha256('${pwd}Encrypt')) {
      if (kDebugMode) {
        print('密码错误');
      }
      return null;
    }

    List<int> xArr = List.generate(width, (index) => index);
    shuffleArr(xArr, pwd);
    List<int> yArr = List.generate(height, (index) => index);
    shuffleArr(yArr, getSha256(pwd));
    List<int> xArr0 = List.generate(width, (index) => index);
    List<int> yArr0 = List.generate(height, (index) => index);

    for (int y = height - 1; y >= 0; y--) {
      var y0 = yArr[y];
      var temp = yArr0[y];
      yArr0[y] = yArr0[y0];
      yArr0[y0] = temp;
    }
    for (int x = width - 1; x >= 0; x--) {
      var x0 = xArr[x];
      var temp = xArr0[x];
      xArr0[x] = xArr0[x0];
      xArr0[x0] = temp;
    }
    var newImg = Image(
        width: width,
        height: height,
        numChannels: image.numChannels,
        exif: image.exif,
        textData: image.textData,
        format: image.format);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        newImg.setPixel(x, y, image.getPixel(xArr0[x], yArr0[y]));
      }
    }
    newImg.textData?.remove('Encrypt');
    newImg.textData!['Dencrypt'] = 'true';
    return newImg;
  } else {
    if (kDebugMode) {
      print('非加密图片，无需解密');
    }
  }
  return null;
}
