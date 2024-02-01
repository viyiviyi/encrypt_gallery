import 'dart:async';

import 'package:encrypt_gallery/core/encrypt_image.datr.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EnImageInfo extends StatefulWidget {
  final String imagePath;
  final String psw;
  const EnImageInfo({Key? key, required this.imagePath, required this.psw})
      : super(key: key);

  @override
  _EnImageInfoState createState() => _EnImageInfoState();
}

class _EnImageInfoState extends State<EnImageInfo> {
  Map<String, String> info = {};
  Completer<LoadResult>? _completer;
  TextStyle contentTextStyle = const TextStyle(
      color: Colors.white54, fontSize: 16, fontWeight: FontWeight.normal);
  TextStyle titleTextStyle = const TextStyle(
      color: Colors.white70, fontSize: 18, fontWeight: FontWeight.normal);
  @override
  void initState() {
    super.initState();
    _completer =
        loadImageProvider(LoadArg(path: widget.imagePath, pwd: widget.psw));
    _completer?.future.then((result) {
      var image = result.image;
      if (image == null) return;
      if (image.textData != null) {
        image.textData!.forEach((key, value) {
          info[key] = value;
        });
      }
      if (image.hasExif) {
        image.exif.directories.forEach((key, value) {
          if (info.containsKey(key)) {
            info[key] =
                '${info[key]!}\n\n${value.data.values.map((e) => e.toString()).join('\n')}';
          }
        });
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    if (_completer != null) {
      loadImageProviderDisable(widget.imagePath, _completer!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '路径: ',
                style: titleTextStyle,
              ),
              Text(
                widget.imagePath,
                style: contentTextStyle,
              )
            ],
          ),
          ...info.keys.map((key) {
            var value = info[key];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$key:',
                  style: titleTextStyle,
                ),
                Text.rich(
                  TextSpan(
                    text: value!,
                    style: contentTextStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已复制到剪切板')));
                      },
                  ),
                )
              ],
            );
          }).toList()
        ],
      ),
    );
  }
}
