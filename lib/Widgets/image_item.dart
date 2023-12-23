import 'dart:async';
import 'dart:io';

import 'package:encrypt_gallery/core/app_tool.dart';
import 'package:encrypt_gallery/core/core.dart';
import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageItem extends StatefulWidget {
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
  ImageItem({
    super.key,
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

  @override
  _ImageItemState createState() => _ImageItemState();
}

class _ImageItemState extends State<ImageItem> {
  Image loading = Image.asset('images/load_image.png');
  Image? _image;

  String? fileName;

  Future initImage() async {
    fileName = getPathName(widget.path);
    var cachePath = await getTempDir();
    var cacheName = getSha256(widget.path + widget.pwd);
    var imgFile = File('${cachePath.absolute.path}/$cacheName');

    if (imgFile.existsSync()) {
      try {
        var cache = Image.file(imgFile);
        setState(() {
          _image = cache;
        });
        return;
      } catch (e) {
        if (kDebugMode) {
          print('缩略图读取失败');
        }
      }
    }
    var image = await compute(
        loadImageProvider,
        LoadArg(
            path: widget.path,
            pwd: widget.pwd,
            cachePath: cachePath.absolute.path));

    if (image == null) {
      setState(() {
        loading = Image.asset('images/error_image.png');
      });
      return;
    }

    setState(() {
      _image = Image(
        image: image,
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
      );
    });
    return;
  }

  @override
  void didUpdateWidget(oldWidget) {
    if (widget.path != oldWidget.path) initImage();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 50), () {
      initImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return loading;
    }
    return GestureDetector(
      child: _image,
    );
  }
}
