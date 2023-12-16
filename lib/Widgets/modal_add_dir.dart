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
    return SizedBox(
      width: 400,
      child: Column(
        children: [
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
