import 'dart:io';

import 'package:encrypt_gallery/core/app_tool.dart';
import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:photo_view/photo_view.dart';

class ImageView extends StatefulWidget {
  final List<String> paths;
  late int index;
  final String psw;
  ImageView(
      {Key? key, required this.paths, required this.index, required this.psw})
      : super(key: key);

  @override
  _ImageViewState createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  String imagePath = '';
  ImageProvider? data;
  img.Image? image;
  String fileName = '';

  Map<String, String> info = {};
  TextStyle contentTextStyle = const TextStyle(
      color: Colors.white54, fontSize: 16, fontWeight: FontWeight.normal);
  TextStyle titleTextStyle = const TextStyle(
      color: Colors.white70, fontSize: 18, fontWeight: FontWeight.normal);

  showImage() {
    data = null;
    image = null;
    info = {};
    imagePath = widget.paths[widget.index];
    fileName = getPathName(imagePath);
    setState(() {});
    getTempDir().then((cachePath) {
      if (image != null) return;
      var thumbnailPath =
          getThumbnailPath(cachePath.absolute.path, imagePath, widget.psw);
      var imgFile = File(thumbnailPath);
      if (imgFile.existsSync()) {
        try {
          setState(() {
            data = FileImage(imgFile);
          });
          return;
        } catch (e) {
          if (kDebugMode) {
            print('缩略图读取失败');
          }
        }
      }
    });
    var prvIdx = widget.index;
    loadImageProviderDisable(widget.paths[
        widget.index - 2 < 0 ? widget.paths.length - 2 : widget.index - 2]);
    loadImageProviderDisable(widget
        .paths[widget.index + 2 >= widget.paths.length ? 1 : widget.index + 2]);
    loadImageProvider(LoadArg(path: imagePath, pwd: widget.psw)).then((result) {
      if (prvIdx != widget.index) return;
      if (result.imageProvider != null) {
        setState(() {
          data = result.imageProvider;
        });
      }
      var image = result.image;
      if (image == null) return;
      this.image = image;
      if (image.textData != null) {
        image.textData!.forEach((key, value) {
          info[key] = value;
        });
      }
      if (image.hasExif) {
        image.exif.directories.forEach((key, value) {
          if (info.containsKey(key)) {
            info[key] =
                '${info[key]!}\n\n${value.data.values.map((e) => e.toString()).join('\n')}';
          }
        });
      }
      setState(() {});
    });
    loadImageProvider(LoadArg(
        path: widget.paths[
            widget.index - 1 < 0 ? widget.paths.length - 1 : widget.index - 1],
        pwd: widget.psw));
    loadImageProvider(LoadArg(
        path: widget.paths[
            widget.index + 1 >= widget.paths.length ? 0 : widget.index + 1],
        pwd: widget.psw));
  }

  @override
  void dispose() {
    // TODO: implement dispose
    loadImageProviderDisable(imagePath);
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    showImage();
    super.initState();
  }

  delImage() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('删除提示'),
            content: const Text('将会从磁盘中删除文件'),
            actions: [
              TextButton(
                child: const Text('取消'),
                onPressed: () => Navigator.of(context).pop(null),
              ),
              TextButton(
                child: const Text('确认'),
                onPressed: () {
                  File(imagePath).delete().then((value) {
                    Navigator.of(context).pop(imagePath);
                    Navigator.of(context).pop(imagePath);
                  });
                },
              ),
            ],
          );
        });
  }

  nextImage() {
    widget.index += 1;
    if (widget.index >= widget.paths.length) widget.index = 0;
    showImage();
  }

  previousImage() {
    widget.index -= 1;
    if (widget.index <= 0) widget.index = widget.paths.length - 1;
    showImage();
  }

  showInfoModal(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('图片信息 (点击可复制)'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '路径: ',
                        style: titleTextStyle,
                      ),
                      Text(
                        imagePath,
                        style: contentTextStyle,
                      )
                    ],
                  ),
                  ...info.keys.map((key) {
                    var value = info[key];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$key:',
                          style: titleTextStyle,
                        ),
                        Text.rich(
                          TextSpan(
                            text: value!,
                            style: contentTextStyle,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Clipboard.setData(ClipboardData(text: value));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('已复制到剪切板')));
                              },
                          ),
                        )
                      ],
                    );
                  }).toList()
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('关闭'),
                onPressed: () => Navigator.of(context).pop(null),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case '1':
                  showInfoModal(context);
                  break;
                case '2':
                  FilePicker.platform
                      .saveFile(fileName: fileName, type: FileType.image)
                      .then((path) {
                    if (path != null && image != null) {
                      File(path).writeAsBytesSync(img.encodePng(image!));
                    }
                  });
                  break;
                case '3':
                  delImage();
                  break;
                default:
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: '1',
                child: Text('查看图片信息'),
              ),
              const PopupMenuItem<String>(
                value: '2',
                child: Text('保存图片'),
              ),
              const PopupMenuItem<String>(
                value: '3',
                child: Text('删除'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        // 设置填充方式展接受父类约束最大值
        fit: StackFit.expand,
        children: [
          Container(
            child: data != null
                ? PhotoView(
                    imageProvider: data,
                  )
                : Center(
                    child: Column(
                      children: [
                        Image.asset('images/load_image.png'),
                        LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.white60, size: 50)
                      ],
                    ),
                  ),
          ),
          Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height / 2 - 40 - 20,
            child: IconButton(
              iconSize: 40,
              icon: const Icon(Icons.arrow_left_rounded),
              onPressed: () {
                previousImage();
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 40 - 20,
            right: 0,
            child: IconButton(
              iconSize: 40,
              icon: const Icon(Icons.arrow_right_rounded),
              onPressed: () {
                nextImage();
              },
            ),
          ),
        ],
      ),
    );
  }
}
