import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

enum PlotState { empty, planted, watered }

enum SimulinType { water, fertilizer, seeding, harvesting, pestDisease }

class Simulin {
  final String name;
  final SimulinType type;
  bool isAssigned;

  Simulin({required this.name, required this.type, this.isAssigned = false});
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farming in Purria',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: GoogleFonts.dancingScriptTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const HexagonalBoard(),
    );
  }
}

class HexagonalBoard extends StatefulWidget {
  const HexagonalBoard({super.key});

  @override
  State<HexagonalBoard> createState() => _HexagonalBoardState();
}

class _HexagonalBoardState extends State<HexagonalBoard>
    with TickerProviderStateMixin {
  static const int rows = 5;
  static const int cols = 5;
  static const Color darkGreen = Color(0xFF006400);
  late double hexSize;
  late List<List<PlotState>> board;
  late List<List<List<SimulinType>>> treatedBy;
  List<Offset?> robotPositions = [];
  late List<AnimationController> _controllers;
  bool isWatering = false;
  int wateredPlants = 0;
  Map<SimulinType, int> score = {for (var type in SimulinType.values) type: 0};
  String debugInfo = '';
  List<Simulin> availableSimulins = [
    Simulin(name: "WaterBot 1", type: SimulinType.water),
    Simulin(name: "WaterBot 2", type: SimulinType.water),
    Simulin(name: "FertilizerBot", type: SimulinType.fertilizer),
    Simulin(name: "SeederBot", type: SimulinType.seeding),
    Simulin(name: "HarvesterBot", type: SimulinType.harvesting),
    Simulin(name: "PestControlBot", type: SimulinType.pestDisease),
  ];
  List<Simulin> assignedSimulins = [];
  List<List<Offset>> simulinPaths = [];

  @override
  void initState() {
    super.initState();
    resetBoard();
  }

  void resetBoard() {
    board =
        List.generate(rows, (_) => List.generate(cols, (_) => PlotState.empty));
    treatedBy = List.generate(rows, (_) => List.generate(cols, (_) => []));
    wateredPlants = 0;
    score = {for (var type in SimulinType.values) type: 0};
    isWatering = false;
    robotPositions = [];
    _controllers = [];
    assignedSimulins = [];
    for (var simulin in availableSimulins) {
      simulin.isAssigned = false;
    }
    debugInfo = 'Board reset';
    setState(() {});
  }

  void plantTulip(int row, int col) {
    setState(() {
      if (board[row][col] == PlotState.empty) {
        board[row][col] = PlotState.planted;
        debugInfo = 'Tulip planted at ($row, $col)';
      } else {
        debugInfo = 'Cannot plant at ($row, $col). State: ${board[row][col]}';
      }
    });
  }

  void showSimulinAssignmentCard() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Assign Simulins',
                  style: GoogleFonts.dancingScript(fontSize: 24)),
              content: SimulinAssignmentCard(
                availableSimulins: availableSimulins,
                onAssign: (List<Simulin> selected) {
                  setState(() {
                    assignedSimulins = selected;
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Start Watering'),
                  onPressed: assignedSimulins.length == 3
                      ? () {
                          Navigator.of(context).pop();
                          startWatering();
                        }
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  void startWatering() {
    List<Offset> plantedPlots = [];
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (board[row][col] == PlotState.planted) {
          plantedPlots.add(_getHexagonCenter(row, col));
        }
      }
    }

    if (plantedPlots.isEmpty) {
      showNoPlantedPlotsDialog();
      return;
    }

    setState(() {
      robotPositions =
          List.generate(assignedSimulins.length, (_) => plantedPlots.first);
      simulinPaths = List.generate(
          assignedSimulins.length, (_) => List.from(plantedPlots));
      _controllers = List.generate(
        assignedSimulins.length,
        (index) => AnimationController(
          duration: Duration(milliseconds: 500 * plantedPlots.length),
          vsync: this,
        )
          ..addListener(() {
            setState(() {
              double animationValue = _controllers[index].value;
              int currentSegment =
                  (animationValue * (plantedPlots.length - 1)).floor();
              double segmentProgress =
                  (animationValue * (plantedPlots.length - 1)) - currentSegment;

              if (currentSegment < plantedPlots.length - 1) {
                robotPositions[index] = Offset.lerp(
                  plantedPlots[currentSegment],
                  plantedPlots[currentSegment + 1],
                  segmentProgress,
                );
              } else {
                robotPositions[index] = plantedPlots.last;
              }
            });
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              waterAllPlots(index);
              if (_controllers.every((controller) => controller.isCompleted)) {
                finishWatering();
              }
            }
          }),
      );
      isWatering = true;
      wateredPlants = 0;
      score = {for (var type in SimulinType.values) type: 0};
      debugInfo = 'Started watering';
    });

    // Start all animations simultaneously
    for (var controller in _controllers) {
      controller.forward();
    }
  }

  void waterAllPlots(int simulinIndex) {
    int treatedPlots = 0;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (board[row][col] == PlotState.planted ||
            board[row][col] == PlotState.watered) {
          board[row][col] = PlotState.watered;
          if (!treatedBy[row][col]
              .contains(assignedSimulins[simulinIndex].type)) {
            treatedBy[row][col].add(assignedSimulins[simulinIndex].type);
            treatedPlots++;
          }
          debugInfo =
              'Watered plot at ($row, $col) with simulin ${assignedSimulins[simulinIndex].name}';
        }
      }
    }
    score[assignedSimulins[simulinIndex].type] = treatedPlots;
    wateredPlants = treatedPlots;
    setState(() {});
  }

  void showNoPlantedPlotsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Planted Tulips',
              style: GoogleFonts.dancingScript(fontSize: 24)),
          content: Text(
              'There are no planted tulips to water. Please plant some tulips first.'),
          actions: <Widget>[
            TextButton(
              child: Text('Reset Game'),
              onPressed: () {
                Navigator.of(context).pop();
                resetBoard();
              },
            ),
          ],
        );
      },
    );
  }

  void finishWatering() {
    setState(() {
      isWatering = false;
      robotPositions = [];
      for (var simulin in availableSimulins) {
        simulin.isAssigned = false;
      }
      debugInfo = 'Finished watering';
    });
    showScoreCard();
  }

  void showScoreCard() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Watering Complete',
              style: GoogleFonts.dancingScript(fontSize: 72)),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'The simulins have finished watering $wateredPlants plants!',
                    style: TextStyle(fontSize: 24)),
                SizedBox(height: 30),
                ...assignedSimulins.map((simulin) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SimulinIcon(type: simulin.type, size: 72),
                          Text('${score[simulin.type]} plots',
                              style: TextStyle(fontSize: 36)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(fontSize: 24)),
              onPressed: () {
                Navigator.of(context).pop();
                resetBoard();
              },
            ),
          ],
        );
      },
    );
  }

  Offset _getHexagonCenter(int row, int col) {
    double x = (col * 1.5 + 1) * hexSize;
    double y = (row * sqrt(3) + (col % 2 == 1 ? sqrt(3) / 2 : 0) + 1) * hexSize;
    return Offset(x, y);
  }

  Color _getColorForState(PlotState state) {
    switch (state) {
      case PlotState.empty:
        return Colors.brown;
      case PlotState.planted:
        return Colors.green;
      case PlotState.watered:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    hexSize = (screenSize.width * 0.8) / ((cols * 1.5 + 0.5) * 1.2);
    final boardWidth = (cols * 1.5 + 0.5) * hexSize;
    final boardHeight = (rows * sqrt(3) + 1) * hexSize;

    return Scaffold(
      backgroundColor: const Color(0xFFE0EAD8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Farming in Purria',
          style: GoogleFonts.dancingScript(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 80,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Instructions:',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '1. Tap hexagons to plant tulips (green)\n'
              '2. Press water drop to assign simulins\n'
              '3. Assign 3 simulins to start watering\n'
              '4. Simulins water planted tulips (blue)\n'
              '5. Refresh button resets the game',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: darkGreen,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: OrganicBoxPainter(),
                    child: Stack(
                      children: [
                        ...List.generate(
                          rows,
                          (row) => List.generate(
                            cols,
                            (col) => Positioned(
                              left: (col * 1.5 + 0.5) * hexSize,
                              top: (row * sqrt(3) +
                                      (col % 2 == 1 ? sqrt(3) / 2 : 0) +
                                      0.5) *
                                  hexSize,
                              child: GestureDetector(
                                onTap: () => plantTulip(row, col),
                                child: HexagonTile(
                                  size: hexSize,
                                  color: _getColorForState(board[row][col]),
                                  state: board[row][col],
                                  treatedBy: treatedBy[row][col],
                                ),
                              ),
                            ),
                          ),
                        ).expand((element) => element),
                        ...robotPositions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final position = entry.value;
                          return position != null
                              ? Positioned(
                                  left: position.dx - hexSize / 2,
                                  top: position.dy - hexSize / 2,
                                  child: SimulinWidget(
                                    size: hexSize,
                                    simulin: assignedSimulins[index],
                                  ),
                                )
                              : const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                Text('Debug: $debugInfo', style: TextStyle(color: darkGreen)),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isWatering)
            FloatingActionButton(
              onPressed: showSimulinAssignmentCard,
              tooltip: 'Assign Simulins',
              backgroundColor: Colors.lightBlue,
              child: const Icon(Icons.water_drop),
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: resetBoard,
            tooltip: 'Reset Game',
            backgroundColor: Colors.green,
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

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
      case SimulinType.pestDisease:
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

class SimulinWidget extends StatelessWidget {
  final double size;
  final Simulin simulin;

  const SimulinWidget({super.key, required this.size, required this.simulin});

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

class OrganicBoxPainter extends CustomPainter {
  final Random _rng = Random(42); // Fixed seed for consistency

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final backgroundPaint = Paint()
      ..color = Colors.brown[200]! // Light brown background
      ..style = PaintingStyle.fill;

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw border
    final paint = Paint()
      ..color = Colors.brown.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final rect = Rect.fromLTWH(size.width * 0.05, size.height * 0.05,
        size.width * 0.9, size.height * 0.98 // Extended to 98% of height
        );

    path.moveTo(rect.left, rect.top);

    // Top side
    _drawOrganicLine(path, rect.topLeft, rect.topRight);

    // Right side
    _drawOrganicLine(path, rect.topRight, rect.bottomRight);

    // Bottom side
    _drawOrganicLine(path, rect.bottomRight, rect.bottomLeft);

    // Left side
    _drawOrganicLine(path, rect.bottomLeft, rect.topLeft);

    canvas.drawPath(path, paint);
  }

  void _drawOrganicLine(Path path, Offset start, Offset end) {
    final length = (end - start).distance;
    final numSegments =
        (length / 20).round(); // One control point every ~20 pixels

    for (int i = 0; i < numSegments; i++) {
      final t = (i + 1) / numSegments;
      final point = Offset.lerp(start, end, t)!;

      final normalX = -(end.dy - start.dy) / length;
      final normalY = (end.dx - start.dx) / length;

      final offset =
          (_rng.nextDouble() - 0.5) * 10; // Random offset between -5 and 5
      final controlPoint =
          Offset(point.dx + normalX * offset, point.dy + normalY * offset);

      if (i == 0) {
        path.quadraticBezierTo(
            controlPoint.dx, controlPoint.dy, point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HexagonTile extends StatelessWidget {
  final double size;
  final Color color;
  final PlotState state;
  final List<SimulinType> treatedBy;

  const HexagonTile({
    super.key,
    required this.size,
    required this.color,
    required this.state,
    required this.treatedBy,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * sqrt(3)),
      painter: HexagonPainter(color: color),
      child: state == PlotState.watered
          ? Stack(
              children: treatedBy.asMap().entries.map((entry) {
                final index = entry.key;
                final type = entry.value;
                return Positioned(
                  left: size * 0.2 + index * size * 0.2,
                  top: size * 0.3,
                  child: SimulinIcon(type: type, size: size * 0.4),
                );
              }).toList(),
            )
          : null,
    );
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
