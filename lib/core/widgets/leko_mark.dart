import 'package:flutter/material.dart';

class LekoMark extends StatelessWidget {
  const LekoMark({
    super.key,
    this.size = 28,
    this.color,
    this.semanticLabel = 'Leko',
  });

  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/leko_mark.png',
      width: size,
      height: size,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
      filterQuality: FilterQuality.high,
      semanticLabel: semanticLabel,
    );
  }
}
