import 'package:encrypt_gallery/Widgets/image_list.dart';
import 'package:encrypt_gallery/Widgets/modal_add_dir.dart';
import 'package:encrypt_gallery/core/app_tool.dart';
import 'package:encrypt_gallery/model/dirs_model.dart';
import 'package:flutter/material.dart';

class Gallery extends StatefulWidget {
  const Gallery({Key? key}) : super(key: key);

  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  List<ImageDir> dirs = [];

  void initDirs() async {
    getAllImageDir().then((values) {
      print(values.length);
      setState(() {
        dirs = values;
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
                  navigatorPage(context, ImageList(dir.rootPath, pwd: dir.psw))
                      .then((value) => initDirs());
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(10),
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
                  // width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dir.rootPath),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        '解密输出目录：${dir.rootPath}/dencrypt_output',
                        style: const TextStyle(color: Colors.white54),
                      ),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('这是一个与另外一个sd插件配套的软件，用于预览和解密被加密的png图片。'),
                TextButton(onPressed: () {}, child: const Text('查看项目')),
                const Text(''),
              ],
            )
          ],
        ),
      ),
    );
  }
}
