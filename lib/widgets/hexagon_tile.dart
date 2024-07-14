// widgets/hexagon_tile.dart

import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/enums.dart';
import 'simulin_widget.dart';

class HexagonTile extends StatelessWidget {
  final double size;
  final Color color;
  final PlotState state;
  final List<SimulinType> treatedBy;
  final int health;

  const HexagonTile({
    Key? key,
    required this.size,
    required this.color,
    required this.state,
    required this.treatedBy,
    required this.health,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * sqrt(3)),
      painter: HexagonPainter(color: color),
      child: state != PlotState.empty
          ? Stack(
              children: [
                if (state == PlotState.planted)
                  Center(
                      child: Icon(Icons.spa,
                          color: Colors.green[800], size: size * 0.6)),
                if (state == PlotState.watered)
                  Center(
                      child: Icon(Icons.opacity,
                          color: Colors.blue[800], size: size * 0.6)),
                if (state == PlotState.fertilized)
                  Center(
                      child: Icon(Icons.eco,
                          color: Colors.purple[800], size: size * 0.6)),
                if (state == PlotState.harvested)
                  Center(
                      child: Icon(Icons.local_florist,
                          color: Colors.yellow[800], size: size * 0.6)),
                Positioned(
                  bottom: 5,
                  left: 5,
                  child: Container(
                    width: size * 0.2,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _getHealthColor(health),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                ...treatedBy.asMap().entries.map((entry) {
                  final index = entry.key;
                  final type = entry.value;
                  return Positioned(
                    left: size * 0.1 + index * size * 0.2,
                    top: size * 0.1,
                    child: SimulinIcon(type: type, size: size * 0.3),
                  );
                }).toList(),
              ],
            )
          : null,
    );
  }

  Color _getHealthColor(int health) {
    if (health > 75) return Colors.green;
    if (health > 50) return Colors.yellow;
    if (health > 25) return Colors.orange;
    return Colors.red;
  }
}

class HexagonPainter extends CustomPainter {
  final Color color;

  const HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * (pi / 180);
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
