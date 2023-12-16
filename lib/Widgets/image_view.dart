import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageView extends StatefulWidget {
  final String fileName;
  final Uint8List data;
  const ImageView({Key? key, required this.data, required this.fileName})
      : super(key: key);

  @override
  _ImageViewState createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Container(
        child: PhotoView(
          imageProvider: MemoryImage(widget.data),
        ),
      ),
    );
  }
}
