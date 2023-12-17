import 'dart:io';

import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:photo_view/photo_view.dart';

class ImageView extends StatefulWidget {
  final String path;
  final String psw;
  const ImageView({Key? key, required this.path, required this.psw})
      : super(key: key);

  @override
  _ImageViewState createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  ImageProvider? data;
  String fileName = '';
  Map<String, String> info = {};
  TextStyle contentTextStyle = const TextStyle(
      color: Colors.white54, fontSize: 16, fontWeight: FontWeight.normal);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fileName =
        widget.path.substring(widget.path.lastIndexOf(RegExp(r'/|\\')) + 1);
    compute(loadImage, LoadArg(path: widget.path, pwd: widget.psw))
        .then((image) {
      if (image == null) return;
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
      compute(imageToImageProvider, image).then((img) {
        setState(() {
          data = img;
        });
      });
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
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('图片信息'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '路径: ',
                                      style: contentTextStyle,
                                    ),
                                    Text(
                                      widget.path,
                                      style: contentTextStyle,
                                    )
                                  ],
                                ),
                                ...info.keys.map((key) {
                                  var value = info[key];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$key:',
                                        style: contentTextStyle,
                                      ),
                                      Text(
                                        value!,
                                        style: contentTextStyle,
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
                  break;
                case '2':
                  break;
                case '3':
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
                                File(widget.path).delete().then((value) {
                                  Navigator.of(context).pop(null);
                                  Navigator.of(context).pop(null);
                                });
                              },
                            ),
                          ],
                        );
                      });
                  break;
                default:
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: '1',
                child: Text('查看图片信息'),
              ),
              // const PopupMenuItem<String>(
              //   value: '2',
              //   child: Text('设为封面'),
              // ),
              const PopupMenuItem<String>(
                value: '3',
                child: Text('删除'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
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
    );
  }
}
