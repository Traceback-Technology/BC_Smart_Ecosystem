import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Draws the route with small curved corners.
/// Smoothing affects only the displayed line, not routing or distances.
class RoutePainter extends CustomPainter {
  final List<Offset> points;

  RoutePainter(this.points);

  // SVG units. Short segments automatically receive smaller curves.
  static const double cornerRadius = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Remove consecutive duplicate points to avoid division by zero.
    final clean = <Offset>[];
    for (final point in points) {
      if (clean.isEmpty || (point - clean.last).distanceSquared > 0.000001) {
        clean.add(point);
      }
    }

    if (clean.length < 2) {
      return;
    }

    final paint = Paint()
      ..color = BcColors.blue
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(clean.first.dx, clean.first.dy);

    for (var i = 1; i < clean.length - 1; i++) {
      final previous = clean[i - 1];
      final corner = clean[i];
      final next = clean[i + 1];

      final incoming = corner - previous;
      final outgoing = next - corner;

      final incomingLength = incoming.distance;
      final outgoingLength = outgoing.distance;

      // Limit trimming to 40% of either segment, so adjacent
      // curves cannot overlap or reverse the connecting line.
      final trim = math.min(
        cornerRadius,
        math.min(incomingLength * 0.4, outgoingLength * 0.4),
      );

      final curveStart = corner - incoming * (trim / incomingLength);
      final curveEnd = corner + outgoing * (trim / outgoingLength);

      path.lineTo(curveStart.dx, curveStart.dy);
      path.quadraticBezierTo(corner.dx, corner.dy, curveEnd.dx, curveEnd.dy);
    }

    // Preserve the exact start and destination endpoints.
    path.lineTo(clean.last.dx, clean.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
