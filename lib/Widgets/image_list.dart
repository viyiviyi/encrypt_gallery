import 'dart:io';
import 'dart:math';

import 'package:encrypt_gallery/Widgets/image_item.dart';
import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:encrypt_gallery/model/dirs_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageList extends StatefulWidget {
  late String pathName;
  final String path;
  final String pwd;
  ImageList(this.path, {Key? key, required this.pwd}) : super(key: key) {
    pathName = path.substring(path.lastIndexOf(RegExp(r'/|\\')) + 1);
  }

  @override
  _ImageListState createState() => _ImageListState();
}

class _ImageListState extends State<ImageList> {
  var imagePaths = <String>[];
  var dencodeIng = false;
  Future loadImage() async {
    var dir = Directory(widget.path);
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
    setState(() {});
  }

  void dencodeAll() {
    setState(() {
      dencodeIng = true;
    });
    compute(dencryptAllImage,
            LoadArg(path: widget.path, pwd: widget.pwd, cachePath: ''))
        .then((value) {
      setState(() {
        dencodeIng = false;
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadImage();
  }

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.height;
    var wCount = w / min((200 + 20), w / 2);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pathName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == '1') {
                if (dencodeIng) return;
                dencodeAll();
              } else if (value == '2') {
                deleteImageDir(widget.path);
                Navigator.pop(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: '1',
                child: Text('解密全部文件${dencodeIng ? '(进行中)' : ''}'),
              ),
              const PopupMenuItem<String>(
                value: '2',
                child: Text('删除此相册(不删除文件)'),
              ),
            ],
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: wCount.toInt(),
        children: List.generate(
          imagePaths.length,
          (index) => Container(
            padding: const EdgeInsets.only(bottom: 10),
            child: Center(
              child: ServerImage(
                path: imagePaths[index],
                pwd: widget.pwd,
                height: h / 2,
                fit: BoxFit.fitHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
