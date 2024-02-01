import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:encrypt_gallery/core/image_utils.dart';
import 'package:encrypt_gallery/model/dirs_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:image/image.dart' as img;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class FileMgtModal extends StatefulWidget {
  final String fileName;
  final String imagePath;
  final String psw;

  const FileMgtModal({
    Key? key,
    required this.fileName,
    required this.imagePath,
    required this.psw,
  }) : super(key: key);

  @override
  _FileMgtModalState createState() => _FileMgtModalState();
}

class _FileMgtModalState extends State<FileMgtModal> {
  List<ImageDir>? dirs;
  bool encrypt = true;
  Completer<LoadResult>? completer;
  img.Image? image;
  bool isDeleted = false;

  @override
  void initState() {
    super.initState();
    completer =
        loadImageProvider(LoadArg(path: widget.imagePath, pwd: widget.psw));
    completer?.future.then((result) {
      setState(() {
        image = result.image;
        encrypt = result.image?.textData?['Dencrypt'] == 'true';
      });
      getAllImageDir().then((values) {
        setState(() {
          dirs = values;
          dirs?.sort((l, r) => l.rootPath.compareTo(r.rootPath));
        });
      });
    });
  }

  @override
  void dispose() {
    if (completer != null) {
      loadImageProviderDisable(widget.imagePath, completer!);
    }
    super.dispose();
  }

  Future<bool> saveImage(bool isMove, ImageDir dist) async {
    setState(() {
      isDeleted = false;
    });
    if (image == null) {
      Navigator.pop(context);
      showToast('文件加载出错',
          context: context,
          axis: Axis.horizontal,
          alignment: Alignment.center,
          position: StyledToastPosition.center);
      return false;
    }
    if (File('${dist.rootPath}/${widget.fileName}').existsSync()) {
      Navigator.pop(context);
      showToast('目标目录已存在同名文件',
          context: context,
          axis: Axis.horizontal,
          alignment: Alignment.center,
          position: StyledToastPosition.center);
      return false;
    }
    if (dist.psw == widget.psw) {
      if ((image?.textData?['Dencrypt'] == 'true') == encrypt) {
        if (isMove) {
          await File(widget.imagePath)
              .rename('${dist.rootPath}/${widget.fileName}');
          isDeleted = true;
        } else {
          await File(widget.imagePath)
              .copy('${dist.rootPath}/${widget.fileName}');
        }
      }
    } else {
      await compute(
        saveImageToFile,
        SaveImageArgs(
            savePath: '${dist.rootPath}/${widget.fileName}',
            image: image!,
            psw: encrypt ? dist.psw : null),
      );
      if (isMove) {
        await File(widget.imagePath).delete();
        isDeleted = true;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(20),
      // height: 500,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            child: const Text('选择复制或移动图片的目标文件夹'),
          ),
          Expanded(
            flex: 1,
            child: ListView(
              children: [
                ...(image == null
                    ? [
                        LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.white60, size: 50)
                      ]
                    : []),
                ...dirs?.map((dir) {
                      return GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return BottomSheet(
                                onClosing: () {},
                                builder: (context) {
                                  return SizedBox(
                                    width: double.maxFinite,
                                    height: 140,
                                    child: Column(
                                      children: [
                                        Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 30),
                                          child: CheckboxListTile(
                                            value: encrypt,
                                            title: const Text('加密保存'),
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            onChanged: (value) {
                                              setState(() {
                                                encrypt = value ?? true;
                                              });
                                            },
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: InkWell(
                                                child: const Center(
                                                  child: Text('复制'),
                                                ),
                                                onTap: () {
                                                  saveImage(false, dir)
                                                      .then((value) {
                                                    Navigator.pop(
                                                        context, isDeleted);
                                                    if (value == true) {
                                                      Navigator.pop(
                                                          context, isDeleted);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: InkWell(
                                                child: const Center(
                                                  child: Text('移动'),
                                                ),
                                                onTap: () {
                                                  saveImage(true, dir)
                                                      .then((value) {
                                                    Navigator.pop(
                                                        context, isDeleted);
                                                    if (value == true) {
                                                      Navigator.pop(
                                                          context, isDeleted);
                                                    }
                                                  });
                                                },
                                              ),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.all(10),
                          constraints: BoxConstraints(
                              minWidth:
                                  min(MediaQuery.of(context).size.width, 300)),
                          decoration: BoxDecoration(
                            color: Colors.black87.withOpacity(.3),
                            borderRadius: const BorderRadius.all(
                                Radius.circular(10)), // 设置圆角半径为10
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dir.rootPath),
                              const SizedBox(
                                height: 10,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList() ??
                    [],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
