import 'dart:io';
import 'dart:math';

import 'package:encrypt_gallery/Widgets/common/grid_builder.dart';
import 'package:encrypt_gallery/Widgets/image_item.dart';
import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:encrypt_gallery/model/dirs_model.dart';
import 'package:encrypt_gallery/model/file_sort_type.dart';
import 'package:encrypt_gallery/model/provider_status.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_dir/open_dir.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/app_tool.dart';
import 'image_view.dart';

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
  var imageFiles = <FileSystemEntity>[];
  FileSortType sortType = FileSortType.timeDesc;
  bool loadind = true;

  Future loadImages() async {
    loadind = true;
    imageFiles = [];
    var dir = Directory(widget.imageDir.rootPath);
    if (await dir.exists()) {
      for (var value in dir.listSync()) {
        if (RegExp(r'(.png|.jpg|.jpeg|.webp)$').hasMatch(value.path)) {
          var stat = await value.stat();
          if (stat.type == FileSystemEntityType.file) {
            imageFiles.add(value);
          }
        }
      }
      sortImages();
    }
  }

  sortImages() {
    setState(() {
      switch (sortType) {
        case FileSortType.name:
          imageFiles.sort(
              (l, r) => getPathName(l.path).compareTo(getPathName(r.path)));
          break;
        case FileSortType.nameDesc:
          imageFiles.sort(
              (l, r) => getPathName(r.path).compareTo(getPathName(l.path)));
          break;
        case FileSortType.time:
          imageFiles.sort((l, r) =>
              l.statSync().modified.millisecondsSinceEpoch -
              r.statSync().modified.millisecondsSinceEpoch);
          break;
        case FileSortType.timeDesc:
          imageFiles.sort((l, r) =>
              r.statSync().modified.millisecondsSinceEpoch -
              l.statSync().modified.millisecondsSinceEpoch);
          break;
        default:
      }
      loadind = false;
    });
  }

  Future deleteThumbnail() {
    return getTempDir().then((cachePath) {
      for (var element in imageFiles) {
        var thumbnailPath = getThumbnailPath(cachePath.absolute.path,
            element.absolute.path, widget.imageDir.psw);
        var thumbnail = File(thumbnailPath);
        if (thumbnail.existsSync()) thumbnail.deleteSync();
      }
    });
  }

  void dencodeAll(WorkStatus workStatus) async {
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      FilePicker.platform
          .getDirectoryPath(dialogTitle: '指定解密文件存放目录，请勿指定源目录。')
          .then((value) {
        if (value != null && value != '/' && value != '') {
          workStatus.setDencodeIng(true);
          compute(dencryptAllImage, {
            'inputPath': widget.imageDir.rootPath,
            'outputPath': value,
            'password': widget.imageDir.psw,
          }).then((value) {
            workStatus.setDencodeIng(false);
          });
        }
      });
    } else {
      showToast('没有访问权限', context: context);
    }
  }

  void encodeAll(WorkStatus workStatus) async {
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      FilePicker.platform
          .getDirectoryPath(dialogTitle: '指定加密文件存放目录，请勿指定源目录。')
          .then((value) {
        if (value != null && value != '/' && value != '') {
          workStatus.setEncodeIng(true);
          compute(encryptAllImage, {
            'inputPath': widget.imageDir.rootPath,
            'outputPath': value,
            'password': widget.imageDir.psw,
          }).then((value) {
            workStatus.setEncodeIng(false);
          });
        }
      });
    } else {
      showToast('没有访问权限', context: context);
    }
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
    var workStats = context.watch<WorkStatus>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pathName),
        actions: [
          PopupMenuButton<FileSortType>(
            icon: const Icon(Icons.sort),
            onSelected: (FileSortType value) {
              sortType = value;
              sortImages();
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<FileSortType>>[
              PopupMenuItem<FileSortType>(
                value: FileSortType.timeDesc,
                child: Text(
                    '从新到旧${sortType == FileSortType.timeDesc ? ' 当前' : ''}'),
              ),
              PopupMenuItem<FileSortType>(
                value: FileSortType.time,
                child:
                    Text('从旧到新${sortType == FileSortType.time ? ' 当前' : ''}'),
              ),
              PopupMenuItem<FileSortType>(
                value: FileSortType.name,
                child:
                    Text('从A到Z${sortType == FileSortType.name ? ' 当前' : ''}'),
              ),
              PopupMenuItem<FileSortType>(
                value: FileSortType.nameDesc,
                child: Text(
                    '从Z到A${sortType == FileSortType.nameDesc ? ' 当前' : ''}'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case '1':
                  if (workStats.dencodeIng) return;
                  dencodeAll(workStats);
                  break;
                case '2':
                  deleteThumbnail().then(((value) {
                    deleteImageDir(widget.imageDir);
                    Navigator.pop(context);
                  }));
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
                  if (workStats.encodeIng) return;
                  encodeAll(workStats);
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
                child: Text('解密全部图片${workStats.dencodeIng ? '(进行中)' : ''}'),
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
                child: Text('加密全部图片${workStats.encodeIng ? '(进行中)' : ''}'),
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
      body: loadind
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.white60, size: 50),
            )
          : Container(
              padding: const EdgeInsets.only(
                  bottom: 40, top: 10, left: 20, right: 20),
              child: imageFiles.isEmpty
                  ? const Center(
                      child: Text("未在当前目录找到图片"),
                    )
                  : GridBuilder(
                      count: imageFiles.length,
                      crossAxisCount: wCount.toInt(),
                      renderItem: (int idx) {
                        return Container(
                          padding: const EdgeInsets.all(5),
                          child: ImageItem(
                            key: Key(imageFiles[idx].path),
                            path: imageFiles[idx].path,
                            pwd: widget.imageDir.psw,
                            height: h / 2,
                            fit: BoxFit.fitHeight,
                            filterQuality: FilterQuality.medium,
                          ),
                        );
                      },
                      onTap: (int idx) {
                        navigatorPage(
                            context,
                            ImageView(
                              paths: imageFiles.map((e) => e.path).toList(),
                              index: idx,
                              psw: widget.imageDir.psw,
                              onDeleteItem: (idx) {
                                imageFiles.removeAt(idx).delete();
                              },
                            )).then(
                          (value) {
                            setState(() {});
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
