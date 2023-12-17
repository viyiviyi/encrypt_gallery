import 'dart:io';
import 'dart:math';

import 'package:encrypt_gallery/Widgets/image_item.dart';
import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:encrypt_gallery/model/dirs_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_dir/open_dir.dart';

import '../core/app_tool.dart';
import 'image_view.dart';

var _dencodeIng = false;
var _encodeIng = false;

class ImageList extends StatefulWidget {
  late String pathName;
  final ImageDir imageDir;
  ImageList(this.imageDir, {Key? key}) : super(key: key) {
    pathName = imageDir.rootPath
        .substring(imageDir.rootPath.lastIndexOf(RegExp(r'/|\\')) + 1);
  }

  @override
  _ImageListState createState() => _ImageListState();
}

class _ImageListState extends State<ImageList> {
  var imagePaths = <String>[];
  Future loadImages() async {
    imagePaths = [];
    var dir = Directory(widget.imageDir.rootPath);
    if (await dir.exists()) {
      for (var value in dir.listSync()) {
        if (RegExp(r'(.png|.jpg|.jpeg|.webp)$').hasMatch(value.path)) {
          var stat = await value.stat();
          if (stat.type == FileSystemEntityType.file) {
            imagePaths.add(value.path);
          }
        }
      }
    }
    setState(() {
      imagePaths = [...imagePaths];
    });
  }

  void dencodeAll() {
    setState(() {
      _dencodeIng = true;
    });
    compute(
        dencryptAllImage,
        LoadArg(
          path: widget.imageDir.rootPath,
          pwd: widget.imageDir.psw,
        )).then((value) {
      setState(() {
        _dencodeIng = false;
      });
    });
  }

  void encodeAll() {
    setState(() {
      _encodeIng = true;
    });
    compute(
        encryptAllImage,
        LoadArg(
          path: widget.imageDir.rootPath,
          pwd: widget.imageDir.psw,
        )).then((value) {
      setState(() {
        _encodeIng = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.height;
    var wCount = w / min((200 + 20), w / 2);
    var len = imagePaths.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pathName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case '1':
                  if (_dencodeIng) return;
                  dencodeAll();
                  break;
                case '2':
                  deleteImageDir(widget.imageDir);
                  Navigator.pop(context);
                  break;
                case '3':
                  final openDirPlugin = OpenDir();
                  openDirPlugin.openNativeDir(path: widget.imageDir.rootPath);
                  break;
                case '4':
                  final openDirPlugin = OpenDir();
                  openDirPlugin.openNativeDir(
                      path: '${widget.imageDir.rootPath}/dencrypt_output');
                  break;
                case '5':
                  if (_encodeIng) return;
                  encodeAll();
                  break;
                case '6':
                  final openDirPlugin = OpenDir();
                  openDirPlugin.openNativeDir(
                      path: '${widget.imageDir.rootPath}/encrypt_output');
                  break;
                default:
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: '1',
                child: Text('解密全部图片${_dencodeIng ? '(进行中)' : ''}'),
              ),
              const PopupMenuItem<String>(
                value: '2',
                child: Text('删除此相册(不删除文件)'),
              ),
              ...(Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                  ? [
                      const PopupMenuItem<String>(
                        value: '3',
                        child: Text('打开相册目录'),
                      ),
                      const PopupMenuItem<String>(
                        value: '4',
                        child: Text('打开解密输出目录'),
                      )
                    ]
                  : [],
              PopupMenuItem<String>(
                value: '5',
                child: Text('加密全部图片${_encodeIng ? '(进行中)' : ''}'),
              ),
              ...(Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                  ? [
                      const PopupMenuItem<String>(
                        value: '6',
                        child: Text('打开加密输出目录'),
                      ),
                    ]
                  : [],
            ],
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.only(bottom: 40, top: 10),
        child: GridView.count(
          crossAxisCount: wCount.toInt(),
          children: imagePaths
              .map(
                (path) => Container(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Center(
                    child: ImageItem(
                      path: path,
                      pwd: widget.imageDir.psw,
                      height: h / 2,
                      fit: BoxFit.fitHeight,
                      onTap: () => {
                        navigatorPage(
                            context,
                            ImageView(
                              path: path,
                              psw: widget.imageDir.psw,
                            )).then((value) {
                          if (value != null) {
                            setState(() {
                              imagePaths = imagePaths
                                  .where((path) => path != value)
                                  .toList();
                            });
                          }
                        })
                      },
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
