import 'dart:io';

import 'package:encrypt_gallery/Widgets/common/file_mgt_modal.dart';
import 'package:encrypt_gallery/Widgets/common/image_editor.dart';
import 'package:encrypt_gallery/Widgets/common/image_info.dart';
import 'package:encrypt_gallery/Widgets/common/image_page.dart';
import 'package:encrypt_gallery/core/app_tool.dart';
import 'package:encrypt_gallery/core/encrypt_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:photo_view/photo_view_gallery.dart';

class ImageView extends StatefulWidget {
  final List<String> paths;
  late int index;
  final String psw;
  Function(int idx)? onDeleteItem;
  Function(int idx, String path)? onAdd;
  List<MapEntry<String, Function(int idx, String path)>> actions = [];
  ImageView({
    Key? key,
    required this.paths,
    required this.index,
    required this.psw,
    this.onDeleteItem,
    this.onAdd,
    this.actions = const [],
  }) : super(key: key);

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
  img.Image? image;
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
            .future
            .then((result) {
          var image = result.image;
          if (image == null) return;
          File(path).writeAsBytesSync(img.encodePng(image));
        });
      }
    });
  }

  void moveImage(bool move) {
    setState(() {
      delloading = true;
    });
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return BottomSheet(
            onClosing: () {},
            builder: (context) {
              return FileMgtModal(
                fileName: fileName,
                imagePath: imagePath,
                psw: widget.psw,
              );
            });
      },
    ).then((value) {
      if (value == true) {
        widget.paths.removeAt(widget.index);
        widget.onDeleteItem?.call(widget.index);
      }
      setState(() {
        showImage();
        delloading = false;
        _pageController = PageController(initialPage: widget.index);
      });
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
          renderTopbar(),
          renderBottonbar(),
        ],
      ),
    );
  }

  Widget renderTopbar() {
    return Visibility(
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
                  default:
                    var ls =
                        widget.actions.where((element) => element.key == value);
                    if (ls.isNotEmpty) {
                      ls.first.value(widget.index, imagePath);
                    }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: '1',
                  child: Text('查看图片信息'),
                ),
                ...widget.actions.map((e) => PopupMenuItem<String>(
                      value: e.key,
                      child: Text(e.key),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget renderBottonbar() {
    return Visibility(
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
                loadImageProvider(LoadArg(
                  path: imagePath,
                  pwd: widget.psw,
                )).future.then((result) {
                  navigatorPage(
                    context,
                    ImageEditor(imagePath: imagePath, psw: widget.psw),
                  ).then((path) {
                    delloading = false;
                    if (path != null) {
                      widget.paths.insert(widget.index + 1, path as String);
                      if (widget.onAdd != null) {
                        widget.onAdd!(widget.index + 1, path);
                      }
                      widget.index += 1;
                      showImage();
                    }
                    _pageController = PageController(initialPage: widget.index);
                    setState(() {});
                  });
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
    );
  }
}
