// widgets/simulin_assignment_card.dart

import 'package:flutter/material.dart';
import '../models/simulin.dart';
import 'simulin_widget.dart';

class SimulinAssignmentCard extends StatefulWidget {
  final List<Simulin> availableSimulins;
  final Function(List<Simulin>) onAssign;

  const SimulinAssignmentCard({
    Key? key,
    required this.availableSimulins,
    required this.onAssign,
  }) : super(key: key);

  @override
  _SimulinAssignmentCardState createState() => _SimulinAssignmentCardState();
}

class _SimulinAssignmentCardState extends State<SimulinAssignmentCard> {
  List<Simulin?> assignedSimulins = List.filled(3, null);
  Simulin? selectedSimulin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            return SimulinCircle(simulin: assignedSimulins[index]);
          }),
        ),
        SizedBox(height: 20),
        DropdownButton<Simulin>(
          hint: Text('Select a Simulin'),
          value: selectedSimulin,
          onChanged: (Simulin? newValue) {
            setState(() {
              selectedSimulin = newValue;
            });
          },
          items: widget.availableSimulins
              .where((simulin) => !assignedSimulins.contains(simulin))
              .map<DropdownMenuItem<Simulin>>((Simulin simulin) {
            return DropdownMenuItem<Simulin>(
              value: simulin,
              child: Text(simulin.name),
            );
          }).toList(),
        ),
        ElevatedButton(
          child: Text('Assign'),
          onPressed: selectedSimulin != null
              ? () {
                  setState(() {
                    int emptyIndex = assignedSimulins.indexOf(null);
                    if (emptyIndex != -1) {
                      assignedSimulins[emptyIndex] = selectedSimulin;
                      selectedSimulin = null;
                      widget.onAssign(
                          assignedSimulins.whereType<Simulin>().toList());
                    }
                  });
                }
              : null,
        ),
      ],
    );
  }
}

class SimulinCircle extends StatelessWidget {
  final Simulin? simulin;

  const SimulinCircle({Key? key, this.simulin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey),
        color: simulin != null ? Colors.white : Colors.grey.shade200,
      ),
      child: simulin != null
          ? Center(
              child: SimulinIcon(type: simulin!.type, size: 40),
            )
          : null,
    );
  }
}
