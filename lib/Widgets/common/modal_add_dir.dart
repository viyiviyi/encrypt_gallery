import 'package:encrypt_gallery/core/app_tool.dart';
import 'package:encrypt_gallery/core/core.dart';
import 'package:encrypt_gallery/model/dirs_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

class AddDirModal extends StatefulWidget {
  ImageDir dir = ImageDir(rootPath: '', psw: '');
  AddDirModal({super.key});

  @override
  State<AddDirModal> createState() => _AddDirModalState();
}

class _AddDirModalState extends State<AddDirModal> {
  String remoteBaseUrl = '';
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 200,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 2),
      child: Column(
        children: [
          Visibility(
            visible: false,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: '共享路径'),
                  onChanged: (value) {
                    if (value == '') return;
                    setState(() {
                      remoteBaseUrl = value;
                    });
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: '访问账号'),
                  onChanged: (value) {
                    if (value == '') return;
                    setState(() {
                      widget.dir.authUser = value;
                    });
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: '访问密码'),
                  onChanged: (value) {
                    if (value == '') return;
                    setState(() {
                      widget.dir.authPsw = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Text(widget.dir.rootPath),
          Container(
            alignment: Alignment.bottomRight,
            child: TextButton(
              onPressed: () {
                checkManageExternalStoragePermission().then((status) {
                  if (status) {
                    FilePicker.platform.getDirectoryPath().then((value) {
                      setState(() {
                        widget.dir.rootPath = value ?? '';
                      });
                    });
                  } else {}
                  showToast('没有访问权限', context: context);
                });
              },
              child: const Text('选择目录'),
            ),
          ),
          TextField(
            decoration: const InputDecoration(labelText: '密码'),
            onChanged: (value) {
              if (value == '') return;
              setState(() {
                widget.dir.psw = getSha256(value);
              });
            },
          ),
        ],
      ),
    );
  }
}
