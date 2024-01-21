import 'package:encrypt_gallery/core/core.dart';
import 'package:encrypt_gallery/model/dirs_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AddDirModal extends StatefulWidget {
  ImageDir dir = ImageDir(rootPath: '', psw: '');
  AddDirModal({super.key});

  @override
  State<AddDirModal> createState() => _AddDirModalState();
}

class _AddDirModalState extends State<AddDirModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height / 2),
      child: Column(
        children: [
          Offstage(
            offstage: true,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: '共享路径'),
                  onChanged: (value) {
                    if (value == '') return;
                    setState(() {
                      widget.dir.psw = getSha256(value);
                    });
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: '访问账号'),
                  onChanged: (value) {
                    if (value == '') return;
                    setState(() {
                      widget.dir.psw = getSha256(value);
                    });
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: '访问密码'),
                  onChanged: (value) {
                    if (value == '') return;
                    setState(() {
                      widget.dir.psw = getSha256(value);
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
                FilePicker.platform.getDirectoryPath().then((value) {
                  setState(() {
                    widget.dir.rootPath = value ?? '';
                  });
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
