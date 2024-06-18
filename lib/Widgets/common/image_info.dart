import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:image/image.dart' as img;

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
  TextStyle contentTextStyle = const TextStyle(
      color: Colors.white54, fontSize: 16, fontWeight: FontWeight.normal);
  TextStyle titleTextStyle = const TextStyle(
      color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold);

  img.Image? image;

  @override
  void initState() {
    super.initState();
    img.decodeImageFile(widget.imagePath).then((result) {
      if (result == null) return;
      image = result;
      if (result.textData != null) {
        result.textData!.forEach((key, value) {
          if (key == 'EncryptPwdSha') {
          } else if (key == 'Encrypt' && value.startsWith('pixel_shuffle')) {
            info['是否加密'] = '是';
          } else {
            try {
              if (value.startsWith('ey')) {
                var val = utf8.decode(base64.decode(value));
                var jsonData = json.decode(val);
                (jsonData as Map<String, dynamic>).forEach((key, value) {
                  info[key] = value.toString();
                });
                info[key] = val;
              } else {
                info[key] = value;
              }
            } catch (e) {
              info[key] = value;
            }
          }
        });
      }
      if (result.hasExif) {
        result.exif.directories.forEach((key, value) {
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
          Visibility(
            visible: image != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '大小: ',
                  style: titleTextStyle,
                ),
                Text(
                  '${image?.width} x ${image?.height}',
                  style: contentTextStyle,
                )
              ],
            ),
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
                        Clipboard.setData(ClipboardData(text: value)).then(
                            (value) => showToast('已复制到剪切板', context: context));
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

Map<String, String> checkInfo(MapEntry<String, String> input) {
  var reg = RegExp('${infoKeys.join(':|')}:');
  Map<String, String> map = {};
  int i = 0;
  String lastVal = '';
  String lastKey = input.key;
  while (true) {
    if (input.value.startsWith(reg, i)) {
      if (lastVal.isNotEmpty) {
        map[lastKey] = lastVal;
        lastVal = '';
        // lastKey = input.value.substring(i,)
      }
    } else {
      lastVal += input.value.substring(i, i + 1);
    }

    if (++i >= input.value.length) break;
  }
  return map;
}

const infoKeys = [
  'Negative prompt',
  'Steps',
  'Sampler',
  'CFG scale',
  'Seed',
  'Size',
  'Model',
  'Denoising strength',
  'Clip skip',
  'ENSD',
  'Hires prompt',
  'Hires upscale',
  'Hires steps',
  'Hires upscaler',
  'SGM noise multiplier',
  'VAE Encoder',
  'Version'
];
