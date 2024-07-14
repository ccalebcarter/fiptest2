// widgets/organic_box_painter.dart

import 'package:flutter/material.dart';
import 'dart:math';

class OrganicBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final rng = Random();

    void addPoint(double x, double y) {
      x += (rng.nextDouble() - 0.5) * size.width * 0.02;
      y += (rng.nextDouble() - 0.5) * size.height * 0.02;
      if (path.getBounds().isEmpty) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    addPoint(size.width * 0.05, size.height * 0.05);
    addPoint(size.width * 0.95, size.height * 0.05);
    addPoint(size.width * 0.95, size.height * 0.95);
    addPoint(size.width * 0.05, size.height * 0.95);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}