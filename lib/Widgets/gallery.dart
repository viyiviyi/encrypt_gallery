import 'dart:io';
import 'dart:math';

import 'package:encrypt_gallery/Widgets/common/modal_add_dir.dart';
import 'package:encrypt_gallery/Widgets/image_item.dart';
import 'package:encrypt_gallery/Widgets/image_list.dart';
import 'package:encrypt_gallery/core/app_tool.dart';
import 'package:encrypt_gallery/core/image_utils.dart';
import 'package:encrypt_gallery/model/dirs_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Gallery extends StatefulWidget {
  const Gallery({Key? key}) : super(key: key);

  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  List<ImageDir> dirs = [];
  bool showAvator = false;

  void initDirs() async {
    getAllImageDir().then((values) {
      setState(() {
        dirs = values;
        dirs.sort((l, r) => l.rootPath.compareTo(r.rootPath));
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initDirs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('相册列表'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                showAvator = !showAvator;
              });
            },
            icon: const Icon(Icons.photo_size_select_large_rounded),
          ),
          const SizedBox(
            width: 15,
          ),
          IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    var modal = AddDirModal();
                    return AlertDialog(
                      title: const Text('新增文件夹'),
                      content: modal,
                      actions: <Widget>[
                        TextButton(
                          child: const Text('取消'),
                          onPressed: () => Navigator.of(context).pop(null),
                        ),
                        TextButton(
                          child: const Text('确定'),
                          onPressed: () {
                            var dir = ImageDir(
                                rootPath: modal.dir.rootPath,
                                psw: modal.dir.psw);
                            if (dir.rootPath != '') {
                              dirs.add(dir);
                              createOrUpdateImageDir(dir);
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                ).then((value) => setState(() {}));
              },
              icon: const Icon(Icons.add_photo_alternate_outlined))
        ],
      ),
      body: SingleChildScrollView(
        child: Wrap(
          children: [
            ...dirs.map((dir) {
              return GestureDetector(
                onTap: () {
                  navigatorPage(context, ImageList(dir))
                      .then((value) => initDirs());
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(10),
                  width: MediaQuery.of(context).size.width /
                          ((MediaQuery.of(context).size.width /
                                  (min(MediaQuery.of(context).size.width - 1,
                                      400)))
                              .floor()) -
                      20,
                  // constraints: BoxConstraints(
                  //   minWidth: min(MediaQuery.of(context).size.width, 400),
                  // ),
                  decoration: BoxDecoration(
                    color: Colors.black87.withOpacity(.3),
                    borderRadius: const BorderRadius.all(
                        Radius.circular(10)), // 设置圆角半径为10
                    boxShadow: [
                      BoxShadow(
                        // 添加阴影效果
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 5, // 阴影扩散程度，值越大阴影越大，值为0时没有阴影效果
                        blurRadius: 7, // 阴影模糊程度，值越大阴影越模糊，值为0时没有阴影效果
                        offset: const Offset(0, 3), // 阴影偏移量，x正数向右偏移，y正数向下偏移
                      ),
                    ],
                  ),
                  child: Flex(
                    direction: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(
                        visible: showAvator &&
                            Directory(dir.rootPath)
                                .listSync()
                                .where((f) => pathIsImage(f.path))
                                .isNotEmpty,
                        child: Container(
                          height: 80,
                          width: 80,
                          margin: const EdgeInsets.only(right: 10),
                          child: ImageItem(
                            height: 80,
                            width: 80,
                            path: Directory(dir.rootPath)
                                .listSync()
                                .where((f) => pathIsImage(f.path))
                                .first
                                .path,
                            pwd: dir.psw,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              getPathName(dir.rootPath),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(dir.rootPath)
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('使用帮助'),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('这是一个与另外一个sd插件配套的软件，用于预览和解密被加密的png图片。'),
                  const Text(
                      '项目地址：https://github.com/viyiviyi/sd-encrypt-image'),
                  TextButton(
                      onPressed: () {
                        launchUrl(
                            Uri.parse(
                                'https://github.com/viyiviyi/sd-encrypt-image'),
                            mode: LaunchMode.externalApplication);
                      },
                      child: const Text('查看项目')),
                  const Text(
                      '使用时在页面右上角选择需要查看的文件夹，并输入密码，密码用于解密和加密，每个目录可以配置独立的密码，可以预览里面的图片，如果图片是加密的，受限于执行效率，解密可能需要一段时间，请勿快速来回滑动列表，可能导致非常卡顿。'),
                  const Text('解密和加密功能在图片列表的右上角。'),
                  const Text('解密和加密均不会修改源图片，将会在图片目录创建解密和加密的专属目录进行存放。'),
                  const Text('如果图片已经被加密或解密不会重复加密或解密。'),
                  const Text('可以在图片详情页右上角查看图片参数。'),
                  const Text(
                      '图片详情页的图片删除功能在删除后会回到图片列表，列表内的图片还存在，这个问题暂时不能解决，是页面刷新的问题，滚动列表后才会加载正确的列表。'),
                  const Text(
                      '此项目的地址：https://github.com/viyiviyi/encrypt_gallery'),
                  TextButton(
                      onPressed: () {
                        launchUrl(
                            mode: LaunchMode.externalApplication,
                            Uri.parse(
                                'https://github.com/viyiviyi/encrypt_gallery'));
                      },
                      child: const Text('查看项目')),
                  const Text(
                      '如果使用中有什么问题，可以在git提交issues，或者加这个Q群@群主反馈 816545732'),
                  const Text(
                      '如果使用得还算满意，能打赏一杯奶茶的话能为我提供不小的帮助。爱发电主页：https://afdian.net/a/yiyiooo ( •̅_•̅ )'),
                  TextButton(
                      onPressed: () {
                        launchUrl(
                            mode: LaunchMode.externalApplication,
                            Uri.parse('https://afdian.net/a/yiyiooo'));
                      },
                      child: const Text('查看页面 ( •̅_•̅ )')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
