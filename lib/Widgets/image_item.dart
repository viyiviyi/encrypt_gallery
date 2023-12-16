import 'dart:io';

import 'package:encrypt_gallery/Widgets/image_view.dart';
import 'package:encrypt_gallery/core/core.dart';
import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../core/app_tool.dart';

class ServerImage extends StatefulWidget {
  final String cachePath = 'encrypt_image_cache';
  final String path;
  final String pwd;
  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect? centerSlice;
  final bool matchTextDirection;
  final bool gaplessPlayback;
  final bool isAntiAlias;
  final FilterQuality filterQuality;
  final int? cacheWidth;
  final int? cacheHeight;
  ServerImage({
    required this.path,
    required this.pwd,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.isAntiAlias = false,
    this.filterQuality = FilterQuality.low,
    this.cacheHeight,
    this.cacheWidth,
  });

  Future<Directory> getTempDir() async {
    return getTemporaryDirectory().then((tempDir) {
      var dir = Directory('${tempDir.path}/$cachePath');
      if (!dir.existsSync()) {
        dir.createSync();
      }
      return dir;
    });
  }

  @override
  _ServerImageState createState() => _ServerImageState();
}

class _ServerImageState extends State<ServerImage> {
  Image loading = Image.asset('images/load_image.png');
  Image? _image;

  String? fileName;
  Uint8List? imgData;

  Future viewImage(BuildContext context) async {
    var imgData =
        await compute(loadImage, LoadArg(path: widget.path, pwd: widget.pwd));
    if (imgData == null) return;

    await navigatorPage(
        context, ImageView(data: imgData, fileName: fileName ?? ''));
  }

  Future<Image> initImage() async {
    var cachePath = await widget.getTempDir();
    var cacheName = getSha256(widget.path);
    var imgFile = File('${cachePath.absolute.path}/$cacheName');

    if (imgFile.existsSync()) {
      try {
        var cache = Image.file(imgFile);
        return cache;
      } catch (e) {
        if (kDebugMode) {
          print('缩略图读取失败');
        }
      }
    }
    var image = await compute(
        loadImage,
        LoadArg(
            path: widget.path,
            pwd: widget.pwd,
            cachePath: cachePath.absolute.path));

    if (image == null) {
      return Image.asset('images/error_image.png');
    }

    return Image.memory(
      image,
      key: Key(cacheName),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
      gaplessPlayback: widget.gaplessPlayback,
      isAntiAlias: widget.isAntiAlias,
      filterQuality: widget.filterQuality,
      cacheHeight: widget.cacheHeight,
      cacheWidth: widget.cacheWidth,
    );
  }

  @override
  void initState() {
    super.initState();
    initImage().then((value) {
      setState(() {
        _image = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) return loading;
    return GestureDetector(
      onTap: () {
        viewImage(context);
      },
      child: _image,
    );
  }
}
