import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Draws the resolved route as a rounded blue line over the campus map.
class RoutePainter extends CustomPainter {
  final List<Offset> points;
  RoutePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = BcColors.blue
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) => oldDelegate.points != points;
}
