import 'dart:async';
import 'dart:io';

import 'package:encrypt_gallery/core/app_tool.dart';
import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:photo_view/photo_view.dart';

class EnImagePage extends StatefulWidget {
  final String imagePath;
  final String psw;
  Function? onTap;
  EnImagePage(
      {Key? key, required this.imagePath, required this.psw, this.onTap})
      : super(key: key);

  @override
  _EnImagePageState createState() => _EnImagePageState();
}

class _EnImagePageState extends State<EnImagePage> {
  ImageProvider? data;
  ImageProvider? thumbnail;
  Completer<LoadResult>? _completer;
  int width = 0;

  late PhotoViewControllerBase<PhotoViewControllerValue> controller;
  showImage() async {
    var cachePath = await getTempDir();
    _completer = loadImageProvider(
      LoadArg(
          path: widget.imagePath,
          pwd: widget.psw,
          cachePath: cachePath.absolute.path),
    );
    _completer?.future.then((result) {
      if (result.imageProvider != null) {
        setState(() {
          data = result.imageProvider;
          width = result.image?.width ?? 0;
        });
      }
    });
    var thumbnailPath =
        getThumbnailPath(cachePath.absolute.path, widget.imagePath, widget.psw);
    var imgFile = File(thumbnailPath);
    if (imgFile.existsSync()) {
      try {
        setState(() {
          thumbnail = FileImage(imgFile);
        });
        return;
      } catch (e) {
        if (kDebugMode) {
          print('缩略图读取失败');
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    controller = PhotoViewController();
    showImage();
  }

  @override
  void dispose() {
    if (_completer != null) {
      loadImageProviderDisable(widget.imagePath, _completer!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: (data ?? thumbnail) != null
          ? PhotoView(
              imageProvider: data ?? thumbnail,
              controller: controller,
              onTapDown: (context, details, controllerValue) {
                widget.onTap?.call();
              },
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              loadingBuilder: (context, event) =>
                  Image.asset('images/load_image.png'),
            )
          : InkWell(
              onTapDown: (details) {
                widget.onTap?.call();
              },
              child: SizedBox(
                height: 250,
                child: Column(
                  children: [
                    Image.asset(
                      'images/load_image.png',
                      height: 200,
                    ),
                    LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.white60, size: 50)
                  ],
                ),
              ),
            ),
    );
  }
}
