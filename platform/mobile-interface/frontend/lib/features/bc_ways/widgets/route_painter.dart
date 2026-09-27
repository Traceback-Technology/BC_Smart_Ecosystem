import 'package:flutter/material.dart';

import '../models/node.dart';

class RoutePainter extends CustomPainter {
  final List<Node> path;

  const RoutePainter(this.path);

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final paint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final route = Path();

    route.moveTo(path.first.x, path.first.y);

    for (int i = 1; i < path.length; i++) {
      route.lineTo(path[i].x, path[i].y);
    }

    canvas.drawPath(route, paint);
  }

  @override
  bool shouldRepaint(RoutePainter oldDelegate) =>
      oldDelegate.path != path;
}