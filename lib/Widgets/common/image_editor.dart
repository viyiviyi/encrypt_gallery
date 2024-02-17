import 'dart:async';
import 'dart:io';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:encrypt_gallery/core/image_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:loading_animation_widget/loading_animation_widget.dart';

enum EditMode { crop, resize }

class ImageEditor extends StatefulWidget {
  final String imagePath;
  final String psw;
  late bool hasEncrypt = false;
  ImageEditor({
    Key? key,
    required this.imagePath,
    required this.psw,
  }) : super(key: key);

  @override
  _ImageEditorState createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  Uint8List? data;
  late CropController _controller;
  late int width = 1;
  late int height = 1;
  Crop? crop;
  bool loading = false;
  Completer<LoadResult>? _completer;
  EditMode mode = EditMode.crop;
  double scale = 0.9;
  double rate = 0;
  double screenRate = 16 / 9;
  bool change = true;

  @override
  void initState() {
    super.initState();
    _controller = CropController();
    _completer = loadImageProvider(LoadArg(
      path: widget.imagePath,
      pwd: widget.psw,
    ));
    _completer?.future.then((result) {
      if (result.image != null) {
        width = result.image!.width;
        height = result.image!.height;
        widget.hasEncrypt = result.image?.textData?['Dencrypt'] == 'true';
        compute((image) => img.encodeBmp(image), result.image!).then((value) {
          data = value;
          crop = Crop(
            image: data!,
            initialArea: Rect.fromCenter(
              center: Offset(width / 2, height / 2),
              width: width * scale,
              height: height * scale,
            ),
            aspectRatio: rate == 0 ? null : rate,
            controller: _controller,
            onCropped: (image) {
              saveImage(image);
            },
          );
          setState(() {});
        });
      }
    });
  }

  @override
  void dispose() {
    if (_completer != null) {
      loadImageProviderDisable(widget.imagePath, _completer!);
    }
    super.dispose();
  }

  void saveImage(Uint8List image) {
    if (loading) return;
    loading = true;
    setState(() {});
    var i = 1;
    var exIdx = widget.imagePath.lastIndexOf('.');
    var ex = widget.imagePath.substring(exIdx);
    var savePath = '${widget.imagePath.substring(0, exIdx)}_$i$ex';
    while (true) {
      i++;
      savePath = savePath = '${widget.imagePath.substring(0, exIdx)}_$i$ex';
      if (File(savePath).existsSync()) {
        continue;
      } else {
        break;
      }
    }
    compute(
      saveUint8ListImage,
      SaveUint8ListImageArgs(
          savePath: savePath,
          data: image,
          psw: widget.hasEncrypt ? widget.psw : null),
    ).then((value) => Navigator.pop(context, savePath));
  }

  Widget loadingWidget() {
    return Center(
      child: SizedBox(
        width: 100,
        child: LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.white60, size: 50),
      ),
    );
  }

  void initCrop() {
    var w = width * scale;
    var h = height * scale;
    if (w > h && rate != 0) {
      w = h * rate;
    }
    if (w < h && rate != 0) {
      h = w / rate;
    }
    if (h > height * scale) {
      h = height * scale;
      w = h * rate;
    }
    if (w > width * scale) {
      w = width * scale;
      h = w / rate;
    }
    _controller.aspectRatio = rate == 0 ? null : rate;
    _controller.area = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: w,
      height: h,
    );
  }

  Widget editImg() {
    return Stack(
      alignment: Alignment.center,
      // 设置填充方式展接受父类约束最大值
      fit: StackFit.expand,
      children: [
        crop ?? loadingWidget(),
        Visibility(
          visible: loading,
          child: Positioned(
            child: Center(
              child: loadingWidget(),
            ),
          ),
        )
      ],
    );
  }

  Widget topUtil() {
    return Container();
  }

  Widget bottomUtil() {
    screenRate =
        MediaQuery.of(context).size.width / MediaQuery.of(context).size.height;
    if (mode == EditMode.crop) {
      return Container(
        padding: const EdgeInsets.all(5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  rate = 0;
                  setState(() => initCrop());
                },
                child: Text(
                  '自由',
                  style: rate == 0 ? TextStyle(color: Colors.green[200]) : null,
                ),
              ),
              TextButton(
                onPressed: () {
                  rate = width / height;
                  setState(() => initCrop());
                },
                child: Text(
                  '原图',
                  style: rate == width / height
                      ? TextStyle(color: Colors.green[200])
                      : null,
                ),
              ),
              TextButton(
                onPressed: () {
                  rate = screenRate;
                  setState(() => initCrop());
                },
                child: Text(
                  '全屏',
                  style: rate == screenRate
                      ? TextStyle(color: Colors.green[200])
                      : null,
                ),
              ),
              TextButton(
                onPressed: () {
                  rate = 9 / 16;
                  setState(() => initCrop());
                },
                child: Text(
                  '9:16',
                  style: rate == 9 / 16
                      ? TextStyle(color: Colors.green[200])
                      : null,
                ),
              ),
              TextButton(
                onPressed: () {
                  rate = 16 / 9;
                  setState(() => initCrop());
                },
                child: Text(
                  '16:9',
                  style: rate == 16 / 9
                      ? TextStyle(color: Colors.green[200])
                      : null,
                ),
              ),
              TextButton(
                onPressed: () {
                  rate = 1;
                  setState(() => initCrop());
                },
                child: Text(
                  '1:1',
                  style: rate == 1 ? TextStyle(color: Colors.green[200]) : null,
                ),
              ),
              TextButton(
                onPressed: () {
                  rate = 3 / 4;
                  setState(() => initCrop());
                },
                child: Text(
                  '3:4',
                  style: rate == 3 / 4
                      ? TextStyle(color: Colors.green[200])
                      : null,
                ),
              ),
              TextButton(
                onPressed: () {
                  rate = 4 / 3;
                  setState(() => initCrop());
                },
                child: Text(
                  '4:3',
                  style: rate == 4 / 3
                      ? TextStyle(color: Colors.green[200])
                      : null,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑图片'),
        actions: [
          // MaterialButton(
          //   onPressed: () {
          //     _controller.crop();
          //   },
          //   child: const Icon(Icons.done),
          // ),
          MaterialButton(
            onPressed: () {
              _controller.crop();
            },
            child: const Icon(Icons.done),
          )
        ],
      ),
      body: Column(
        children: [
          topUtil(),
          Expanded(flex: 1, child: editImg()),
          bottomUtil(),
        ],
      ),
    );
  }
}
