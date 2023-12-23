import 'package:flutter/material.dart';

class GridBuilder extends StatefulWidget {
  GridBuilder({
    super.key,
    this.onLongPress,
    this.onTap,
    required this.renderItem,
    required this.count,
    required this.crossAxisCount,
  });
  final int crossAxisCount;
  final int count;
  final Widget Function(int idx) renderItem;
  final Function(int idx)? onLongPress;
  final Function(int idx)? onTap;

  @override
  GridBuilderState createState() => GridBuilderState();
}

class GridBuilderState extends State<GridBuilder> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        itemCount: widget.count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            mainAxisSpacing: 5, crossAxisCount: widget.crossAxisCount),
        itemBuilder: (_, int index) {
          return InkWell(
            onTap: () {
              if (widget.onTap != null) widget.onTap!(index);
            },
            onLongPress: () {
              if (widget.onLongPress != null) widget.onLongPress!(index);
            },
            child: widget.renderItem(index),
          );
        });
  }
}
