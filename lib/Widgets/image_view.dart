import 'dart:io';
import 'dart:math';

import 'package:encrypt_gallery/Widgets/common/image_editor.dart';
import 'package:encrypt_gallery/Widgets/common/image_info.dart';
import 'package:encrypt_gallery/Widgets/common/image_page.dart';
import 'package:encrypt_gallery/core/app_tool.dart';
import 'package:encrypt_gallery/core/core.dart';
import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:encrypt_gallery/model/dirs_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:image/image.dart' as img;
import 'package:photo_view/photo_view_gallery.dart';

class ImageView extends StatefulWidget {
  final List<String> paths;
  late int index;
  final String psw;
  Function(int idx)? onDeleteItem;
  ImageView(
      {Key? key,
      required this.paths,
      required this.index,
      required this.psw,
      this.onDeleteItem})
      : super(key: key);

  @override
  _ImageViewState createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  String imagePath = '';
  String fileName = '';
  Map<String, String> info = {};
  late PageController _pageController;
  bool showActions = true;
  var delloading = false;
  showImage() {
    setState(() {
      imagePath = widget.paths[widget.index];
      fileName = getPathName(imagePath);
    });
  }

  @override
  void initState() {
    super.initState();
    imagePath = widget.paths[widget.index];
    fileName = getPathName(imagePath);
    _pageController = PageController(initialPage: widget.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  nextImage() {
    loadNext(widget.index, widget.index + 1);
    widget.index += 1;
    if (widget.index >= widget.paths.length) {
      widget.index = 0;
      _pageController.jumpToPage(widget.index);
    }
    showImage();
    _pageController.animateToPage(widget.index,
        duration: const Duration(milliseconds: 420), curve: Curves.easeInOut);
  }

  previousImage() {
    loadNext(widget.index, widget.index - 1);
    widget.index -= 1;
    if (widget.index <= 0) {
      widget.index = widget.paths.length - 1;
      _pageController.jumpToPage(widget.index);
    }
    showImage();
    _pageController.animateToPage(widget.index,
        duration: const Duration(milliseconds: 420), curve: Curves.easeInOut);
  }

  showInfoModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('图片信息 (点击可复制)'),
          content: EnImageInfo(
            imagePath: imagePath,
            psw: widget.psw,
          ),
          actions: [
            TextButton(
              child: const Text('关闭'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
          ],
        );
      },
    );
  }

  void saveImage() {
    FilePicker.platform
        .saveFile(fileName: fileName, type: FileType.image)
        .then((path) {
      if (path != null) {
        loadImageProvider(LoadArg(path: imagePath, pwd: widget.psw))
            .then((result) {
          var image = result.image;
          if (image == null) return;
          File(path).writeAsBytesSync(img.encodePng(image));
        });
      }
    });
  }

  void loadNext(int currentIndex, int nextIndex) {
    getTempDir().then((cachePath) {
      var d = currentIndex < nextIndex ? 1 : -1;
      for (var i = 0; i < 5; i++) {
        // 预加载后面几张图片
        var idx = currentIndex + (i + 1) * d;
        if (d > 0 && idx >= widget.paths.length) {
          return;
        } else if (d < 0 && idx < 0) {
          return;
        }
        var cPath = widget.paths[idx];
        loadImageProvider(LoadArg(
                path: cPath,
                pwd: widget.psw,
                cachePath: cachePath.absolute.path))
            .then((result) {});
      }
    });
  }

  void moveImage(bool move) {
    getAllImageDir().then((values) {
      var dirs = values;
      dirs.sort((l, r) => l.rootPath.compareTo(r.rootPath));
      setState(() {
        delloading = true;
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('移动图片'),
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: const Text('请选择目标目录，如果原图片已加密，将会使用目标目录的密码加密保存。'),
                  ),
                  Expanded(
                    flex: 1,
                    child: ListView(
                      children: [
                        ...dirs.map((dir) {
                          return GestureDetector(
                            onTap: () {
                              if (File('${dir.rootPath}/$fileName')
                                  .existsSync()) {
                                Navigator.pop(context);
                                showToast('目标目录已存在同名文件，取消移动',
                                    context: context,
                                    axis: Axis.horizontal,
                                    alignment: Alignment.center,
                                    position: StyledToastPosition.center);
                                return;
                              }
                              loadImageProvider(
                                      LoadArg(path: imagePath, pwd: widget.psw))
                                  .then((result) {
                                var image = result.image;
                                if (image == null) return;
                                Future.value(() {
                                  if (image.textData?['Dencrypt'] == 'true') {
                                    return encryptImage(image, dir.psw);
                                  }
                                  return image;
                                }).then((imageVal) {
                                  var eImg = imageVal();
                                  if (eImg == null) return;
                                  File('${dir.rootPath}/$fileName')
                                      .writeAsBytesSync(img.encodePng(eImg));
                                  if (move) {
                                    if (widget.onDeleteItem != null) {
                                      widget.onDeleteItem!(widget.index);
                                    }
                                    loadNext(widget.index, widget.index + 1);
                                    if (widget.paths.isEmpty) {
                                      Navigator.of(context).pop(null);
                                      return Navigator.of(context).pop(null);
                                    }
                                    widget.paths.removeAt(widget.index);
                                    if (widget.index >= widget.paths.length) {
                                      widget.index = 0;
                                    }
                                  }
                                  Navigator.of(context).pop(null);
                                  showImage();
                                });
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.all(10),
                              constraints: BoxConstraints(
                                  minWidth: min(
                                      MediaQuery.of(context).size.width, 300)),
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
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: const Text('取消'))
            ],
          );
        },
      ).then((value) => setState(() {
            delloading = false;
            _pageController = PageController(initialPage: widget.index);
          }));
    });
  }

  delImage() {
    setState(() {
      delloading = true;
    });
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
                if (widget.onDeleteItem != null) {
                  widget.onDeleteItem!(widget.index);
                }
                widget.paths.removeAt(widget.index);
                if (widget.paths.isEmpty) {
                  Navigator.of(context).pop(null);
                  return Navigator.of(context).pop(null);
                }
                loadNext(widget.index, widget.index + 1);
                if (widget.index >= widget.paths.length) widget.index = 0;
                showImage();
                Navigator.of(context).pop(null);
              },
            ),
          ],
        );
      },
    ).then((value) => setState(() {
          delloading = false;
          _pageController = PageController(initialPage: widget.index);
        }));
  }

  @override
  Widget build(BuildContext context) {
    // 显示和隐藏状态栏
    SystemChrome.setEnabledSystemUIMode(
        showActions ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky);
    return Scaffold(
      appBar: null,
      body: Stack(
        alignment: Alignment.center,
        // 设置填充方式展接受父类约束最大值
        fit: StackFit.expand,
        children: [
          delloading
              ? EnImagePage(
                  // 在删除的时候仅显示当前图片，删除完成后可以重绘pageview，解决pageview不刷新问题
                  imagePath: imagePath,
                  psw: widget.psw,
                  onTap: () {
                    setState(() {
                      showActions = !showActions;
                    });
                  },
                )
              : PhotoViewGallery.builder(
                  pageController: _pageController,
                  itemCount: widget.paths.length,
                  allowImplicitScrolling: true,
                  onPageChanged: (index) {
                    loadNext(widget.index, index);
                    widget.index = index;
                    showImage();
                  },
                  builder: ((context, index) {
                    return PhotoViewGalleryPageOptions.customChild(
                      child: EnImagePage(
                        imagePath: widget.paths[index],
                        psw: widget.psw,
                        onTap: () {
                          setState(() {
                            showActions = !showActions;
                          });
                        },
                      ),
                    );
                  }),
                ),
          Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height / 2 - 40 - 40,
            child: Opacity(
              opacity: showActions ? 1 : 0,
              child: IconButton(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                iconSize: 40,
                icon: const Icon(
                  Icons.arrow_left_rounded,
                  color: Colors.white60,
                ),
                onPressed: () {
                  previousImage();
                },
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 40 - 40,
            right: 0,
            child: Opacity(
              opacity: showActions ? 1 : 0,
              child: IconButton(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                iconSize: 40,
                icon: const Icon(
                  Icons.arrow_right_rounded,
                  color: Colors.white60,
                ),
                onPressed: () {
                  nextImage();
                },
              ),
            ),
          ),
          Visibility(
            visible: showActions,
            child: Positioned(
              bottom: 20,
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        delloading = true;
                      });
                      navigatorPage(
                        context,
                        ImageEditor(imagePath: imagePath, psw: widget.psw),
                      ).then((path) {
                        delloading = false;
                        if (path != null) {
                          widget.paths.insert(widget.index + 1, path as String);
                          widget.index += 1;
                          _pageController =
                              PageController(initialPage: widget.index);
                          showImage();
                        }
                        setState(() {});
                      });
                    },
                    icon: const Icon(Icons.photo_size_select_large_outlined),
                  ),
                  IconButton(
                    onPressed: () {
                      moveImage(true);
                    },
                    icon: const Icon(Icons.move_to_inbox_outlined),
                  ),
                  ...(Platform.isWindows || Platform.isLinux
                      ? [
                          IconButton(
                            onPressed: () {
                              saveImage();
                            },
                            icon: const Icon(Icons.save_as_outlined),
                          )
                        ]
                      : []),
                  IconButton(
                    onPressed: () {
                      delImage();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: showActions,
            child: Positioned(
              top: Platform.isAndroid || Platform.isIOS ? 30 : 0,
              left: 0,
              height: 50,
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_outlined)),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${widget.index + 1}/${widget.paths.length} $fileName',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      switch (value) {
                        case '1':
                          showInfoModal(context);
                          break;
                        case '2':
                          saveImage();
                          break;
                        case '3':
                          delImage();
                          break;
                        default:
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: '1',
                        child: Text('查看图片信息'),
                      ),
                      ...(Platform.isWindows || Platform.isLinux
                          ? [
                              const PopupMenuItem<String>(
                                value: '2',
                                child: Text('保存图片'),
                              )
                            ]
                          : []),
                      const PopupMenuItem<String>(
                        value: '3',
                        child: Text('删除'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
