import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart';

String getRange(String input,int offset,{int rangeLen = 4}){
  offset = offset % input.length;
  input = input+input;
  return input.substring(offset,offset+rangeLen);
}

String getSha256(String input){
  var bytes = utf8.encode(input);
  var digest  = sha256.convert(bytes);
  return '$digest';
}

List<T> shuffleArr<T>(List<T> arr, String key) {
  String shaKey = getSha256(key);
  int keyLen = shaKey.length;
  int arrLen = arr.length;
  int keyOffset = 0;

  for (int i = 0; i < arrLen; i++) {
    int toIndex = int.parse(getRange(shaKey, keyOffset, rangeLen:8), radix:16) % (arrLen - i);
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

List<List<T>> encryptImageV2<T>(List<List<T>> arr, String psw) {
  int width = arr[0].length;
  int height = arr.length;
  List<int> xArr = List.generate(width, (index) => index);
  shuffleArr(xArr, psw);
  List<int> yArr = List.generate(height, (index) => index);
  shuffleArr(yArr, getSha256(psw));

  for (int y = 0; y < height; y++) {
    var _y = yArr[y];
    var temp = arr[y];
    arr[y] = arr[_y];
    arr[_y] = temp;
  }
  for (int y = 0; y < height; y++) {
    var row = arr[y];
    for (int x = 0; x < width; x++) {
      var _x = xArr[x];
      var temp = row[x];
      row[x] = row[_x];
      row[_x] = temp;
    }
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
  for (int y = height-1; y >=0; y--) {
    var _y = yArr[y];
    var temp = arr[y];
    arr[y] = arr[_y];
    arr[_y] = temp;
  }
  for (int y = height-1; y >= 0; y--) {
    var row = arr[y];
    for (int x = width-1; x >=0; x--) {
      var _x = xArr[x];
      var temp = row[x];
      row[x] = row[_x];
      row[_x] = temp;
    }
  }

  return arr;
}

Image encryptImage(Image image,String pwd){
  var width = image.width;
  var height = image.height;
  if((image.textData!=null && image.textData!.containsKey('Encrypt')) || image.textData?['Encrypt']!='pixel_shuffle_2') {
    var imgArr = List.generate(
        height, (y) => List.generate(width, (x) => image.getPixel(x, y)));
    imgArr = encryptImageV2(imgArr, pwd);
    var newImg = Image(
        width: width, height: height, numChannels: image.numChannels);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        newImg.setPixel(x, y, imgArr[y][x]);
      }
    }
    if(image.textData==null){
      image.textData = {"Encrypt":"pixel_shuffle_2"};
    }else{
      image.textData!['Encrypt'] = 'pixel_shuffle_2';
    }
    return newImg;
  }
  return image;
}

Image dencryptImage(Image image,String pwd){
  var width = image.width;
  var height = image.height;
  if(image.textData?['Encrypt']=='pixel_shuffle_2') {
    var imgArr = List.generate(
        height, (y) => List.generate(width, (x) => image.getPixel(x, y)));
    imgArr = dencryptImageV2(imgArr, pwd);
    var newImg = Image(
        width: width, height: height, numChannels: image.numChannels);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        newImg.setPixel(x, y, imgArr[y][x]);
      }
    }
    image.textData?.remove('Encrypt');
    return newImg;
  }
  return image;
}