import 'dart:io';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:encrypt_gallery/core/image_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:loading_animation_widget/loading_animation_widget.dart';

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
  late int width;
  late int height;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _controller = CropController();
    loadImageProvider(LoadArg(
      path: widget.imagePath,
      pwd: widget.psw,
    )).then((result) {
      if (result.image != null) {
        width = result.image!.width;
        height = result.image!.height;
        widget.hasEncrypt = result.image?.textData?['Dencrypt'] == 'true';
        compute((image) => img.encodePng(image), result.image!).then((value) {
          setState(() {
            data = value;
          });
        });
      }
    });
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
                psw: widget.hasEncrypt ? widget.psw : null))
        .then((value) => Navigator.pop(context, savePath));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑图片'),
        actions: [
          MaterialButton(
              onPressed: () {
                _controller.crop();
              },
              child: const Icon(Icons.done))
        ],
      ),
      body: data == null
          ? loadingWidget()
          : Stack(
              alignment: Alignment.center,
              // 设置填充方式展接受父类约束最大值
              fit: StackFit.expand,
              children: [
                Crop(
                  image: data!,
                  initialArea: Rect.fromCenter(
                      center: Offset(width / 2, height / 2),
                      width: width * 0.9,
                      height: height * 0.9),
                  controller: _controller,
                  onCropped: (image) {
                    saveImage(image);
                  },
                ),
                Visibility(
                  visible: loading,
                  child: Positioned(
                    child: Center(
                      child: loadingWidget(),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
