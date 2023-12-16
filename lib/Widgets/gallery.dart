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
              return Container(
                padding: const EdgeInsets.all(10),
                // width: 300,
                child: GestureDetector(
                  onTap: () {
                    navigatorPage(
                            context, ImageList(dir.rootPath, pwd: dir.psw))
                        .then((value) => initDirs());
                  },
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
                      const SizedBox(
                        height: 15,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
