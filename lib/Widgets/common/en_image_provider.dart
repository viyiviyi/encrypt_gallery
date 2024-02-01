import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show Codec, ImmutableBuffer;

import 'package:encrypt_gallery/core/app_tool.dart';
import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DecryptedImage extends ImageProvider<DecryptedImage> {
  final String imagePath;
  final String psw;
  final double scale;
  const DecryptedImage(
      {required this.imagePath, required this.psw, this.scale = 1.0});

  @override
  Future<DecryptedImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<DecryptedImage>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
      DecryptedImage key, DecoderBufferCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      informationCollector: () sync* {
        yield ErrorDescription('Decoder for $key');
        yield ErrorDescription('Codec provider: $decode');
        yield DiagnosticsProperty<ImageProvider>('Image provider', this);
      },
    );
  }

  Future<ui.Codec> _loadAsync(
      DecryptedImage key, DecoderBufferCallback decode) async {
    assert(key == this);
    getTempDir().then((cachePath) async {
      var thumbnailPath =
          getThumbnailPath(cachePath.absolute.path, imagePath, psw);
      var imgFile = File(thumbnailPath);
      if (imgFile.existsSync()) {
        try {
          var bytes = await imgFile.readAsBytes();
          decode(await ui.ImmutableBuffer.fromUint8List(bytes));
          return;
        } catch (e) {
          if (kDebugMode) {
            print('缩略图读取失败');
          }
        }
      }
    });
    return loadImageProvider(LoadArg(path: imagePath, pwd: psw))
        .future
        .then((result) async {
      if (result.image != null) {
        final Uint8List bytes = await compute(imgToUint8List, result.image!);
        if (bytes.lengthInBytes == 0) {
          PaintingBinding.instance.imageCache.evict(key);
          throw StateError(
              '$imagePath is empty and cannot be loaded as an image.');
        }
        return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
      } else {
        throw StateError(
            '$imagePath is empty and cannot be loaded as an image.');
      }
    });
  }
}
