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
  List<Offset?> robotPositions = [];
  late List<AnimationController> _controllers;
  List<int> currentRows = [];
  List<int> currentCols = [];
  bool isWatering = false;
  int wateredPlants = 0;
  int score = 0;
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

  @override
  void initState() {
    super.initState();
    resetBoard();
  }

  void resetBoard() {
    board =
        List.generate(rows, (_) => List.generate(cols, (_) => PlotState.empty));
    wateredPlants = 0;
    score = 0;
    isWatering = false;
    robotPositions = [];
    currentRows = [];
    currentCols = [];
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Assign 3 simulins to start watering:'),
                  ...availableSimulins.map((simulin) {
                    return CheckboxListTile(
                      title: Text(simulin.name),
                      value: simulin.isAssigned,
                      onChanged: (bool? value) {
                        setState(() {
                          simulin.isAssigned = value ?? false;
                          if (simulin.isAssigned) {
                            if (assignedSimulins.length < 3) {
                              assignedSimulins.add(simulin);
                            } else {
                              simulin.isAssigned = false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'You can only assign 3 simulins.')),
                              );
                            }
                          } else {
                            assignedSimulins.remove(simulin);
                          }
                        });
                      },
                    );
                  }).toList(),
                ],
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
    setState(() {
      robotPositions = List.generate(assignedSimulins.length, (_) => null);
      currentRows = List.generate(assignedSimulins.length, (_) => 0);
      currentCols = List.generate(assignedSimulins.length, (_) => -1);
      _controllers = List.generate(
        assignedSimulins.length,
        (_) => AnimationController(
          duration: const Duration(milliseconds: 500),
          vsync: this,
        )..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              waterCurrentPlot();
              moveToNextPlot();
            }
          }),
      );
      isWatering = true;
      wateredPlants = 0;
      debugInfo = 'Started watering';
    });
    for (int i = 0; i < assignedSimulins.length; i++) {
      moveToNextPlot(i);
    }
  }

  void waterCurrentPlot() {
    setState(() {
      for (int i = 0; i < assignedSimulins.length; i++) {
        if (currentRows[i] < rows &&
            currentCols[i] < cols &&
            board[currentRows[i]][currentCols[i]] == PlotState.planted) {
          board[currentRows[i]][currentCols[i]] = PlotState.watered;
          wateredPlants++;
          score++;
          debugInfo =
              'Watered plot at (${currentRows[i]}, ${currentCols[i]}) with simulin ${assignedSimulins[i].name}';
        }
      }
    });
  }

  void moveToNextPlot([int simulinIndex = 0]) {
    if (findNextPlantedPlot(simulinIndex)) {
      final start = robotPositions[simulinIndex] ??
          _getHexagonCenter(
              currentRows[simulinIndex], currentCols[simulinIndex]);
      final end = _getHexagonCenter(
          currentRows[simulinIndex], currentCols[simulinIndex]);

      _controllers[simulinIndex].reset();
      _controllers[simulinIndex].forward();

      _controllers[simulinIndex].addListener(() {
        setState(() {
          robotPositions[simulinIndex] =
              Offset.lerp(start, end, _controllers[simulinIndex].value);
        });
      });
      debugInfo =
          'Moving simulin ${assignedSimulins[simulinIndex].name} to (${currentRows[simulinIndex]}, ${currentCols[simulinIndex]})';
    } else if (simulinIndex == assignedSimulins.length - 1) {
      finishWatering();
    }
  }

  bool findNextPlantedPlot(int simulinIndex) {
    int startRow = currentRows[simulinIndex];
    int startCol = currentCols[simulinIndex];
    do {
      currentCols[simulinIndex]++;
      if (currentCols[simulinIndex] >= cols) {
        currentCols[simulinIndex] = 0;
        currentRows[simulinIndex]++;
        if (currentRows[simulinIndex] >= rows) {
          currentRows[simulinIndex] = 0;
        }
      }
      if (board[currentRows[simulinIndex]][currentCols[simulinIndex]] ==
          PlotState.planted) {
        debugInfo =
            'Found next planted plot for simulin ${assignedSimulins[simulinIndex].name} at (${currentRows[simulinIndex]}, ${currentCols[simulinIndex]})';
        return true;
      }
    } while (currentRows[simulinIndex] != startRow ||
        currentCols[simulinIndex] != startCol);
    debugInfo =
        'No more planted plots found for simulin ${assignedSimulins[simulinIndex].name}';
    return false;
  }

  void finishWatering() {
    setState(() {
      isWatering = false;
      robotPositions = [];
      assignedSimulins = [];
      for (var simulin in availableSimulins) {
        simulin.isAssigned = false;
      }
      debugInfo = 'Finished watering';
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Watering Complete',
              style: GoogleFonts.dancingScript(fontSize: 24)),
          content: Text(
              'The simulins have finished watering $wateredPlants plants!'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
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
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Instructions:',
              style: GoogleFonts.dancingScript(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '1. Tap hexagons to plant tulips (green)\n'
              '2. Press water drop to assign simulins\n'
              '3. Assign 3 simulins to start watering\n'
              '4. Simulins water planted tulips (blue)\n'
              '5. Refresh button resets the game',
              style: TextStyle(fontSize: 14, color: darkGreen),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: SizedBox(
                width: boardWidth,
                height: boardHeight,
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
                                        color:
                                            _getColorForState(board[row][col]),
                                      ),
                                    ),
                                  ))).expand((element) => element),
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

class SimulinWidget extends StatelessWidget {
  final double size;
  final Simulin simulin;

  const SimulinWidget({super.key, required this.size, required this.simulin});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color color;

    switch (simulin.type) {
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: size * 0.6,
          color: color,
        ),
      ),
    );
  }
}

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

class HexagonTile extends StatelessWidget {
  final double size;
  final Color color;

  const HexagonTile({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * sqrt(3)),
      painter: HexagonPainter(color: color),
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
