// widgets/simulin_widget.dart

import 'package:flutter/material.dart';
import '../utils/enums.dart';
import '../models/simulin.dart';

class SimulinWidget extends StatelessWidget {
  final double size;
  final Simulin simulin;

  const SimulinWidget({Key? key, required this.size, required this.simulin})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: SimulinIcon(type: simulin.type, size: size * 0.6),
      ),
    );
  }
}

class SimulinIcon extends StatelessWidget {
  final SimulinType type;
  final double size;

  const SimulinIcon({Key? key, required this.type, required this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color color;

    switch (type) {
      case SimulinType.water:
        iconData = Icons.water_drop;
        color = Colors.blue;
        break;
      case SimulinType.fertilizer:
        iconData = Icons.eco;
        color = Colors.green;
        break;
      case SimulinType.seeding:
        iconData = Icons.grass;
        color = Colors.brown;
        break;
      case SimulinType.harvesting:
        iconData = Icons.agriculture;
        color = Colors.orange;
        break;
      case SimulinType.pestControl:
        iconData = Icons.bug_report;
        color = Colors.red;
        break;
    }

    return Icon(
      iconData,
      size: size,
      color: color,
    );
  }
}
