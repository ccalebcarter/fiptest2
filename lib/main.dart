import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

enum PlotState { empty, planted, watered }

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
  Offset? robotPosition;
  late AnimationController _controller;
  int currentRow = 0;
  int currentCol = 0;
  bool isWatering = false;
  int wateredPlants = 0;
  int score = 0;
  String debugInfo = '';

  @override
  void initState() {
    super.initState();
    resetBoard();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        waterCurrentPlot();
        moveToNextPlot();
      }
    });
  }

  void resetBoard() {
    board =
        List.generate(rows, (_) => List.generate(cols, (_) => PlotState.empty));
    wateredPlants = 0;
    score = 0;
    isWatering = false;
    robotPosition = null;
    currentRow = 0;
    currentCol = 0;
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

  void startWatering() {
    setState(() {
      currentRow = 0;
      currentCol = -1;
      isWatering = true;
      wateredPlants = 0;
      debugInfo = 'Started watering';
    });
    moveToNextPlot();
  }

  void waterCurrentPlot() {
    setState(() {
      if (board[currentRow][currentCol] == PlotState.planted) {
        board[currentRow][currentCol] = PlotState.watered;
        wateredPlants++;
        score++;
        debugInfo = 'Watered plot at ($currentRow, $currentCol)';
      } else {
        debugInfo =
            'Skipped plot at ($currentRow, $currentCol). State: ${board[currentRow][currentCol]}';
      }
    });
  }

  void moveToNextPlot() {
    if (findNextPlantedPlot()) {
      final start = robotPosition ?? _getHexagonCenter(currentRow, currentCol);
      final end = _getHexagonCenter(currentRow, currentCol);

      _controller.reset();
      _controller.forward();

      _controller.addListener(() {
        setState(() {
          robotPosition = Offset.lerp(start, end, _controller.value);
        });
      });
      debugInfo = 'Moving to ($currentRow, $currentCol)';
    } else {
      finishWatering();
    }
  }

  bool findNextPlantedPlot() {
    int startRow = currentRow;
    int startCol = currentCol;
    do {
      currentCol++;
      if (currentCol >= cols) {
        currentCol = 0;
        currentRow++;
        if (currentRow >= rows) {
          currentRow = 0;
        }
      }
      if (board[currentRow][currentCol] == PlotState.planted) {
        debugInfo = 'Found next planted plot at ($currentRow, $currentCol)';
        return true;
      }
    } while (currentRow != startRow || currentCol != startCol);
    debugInfo = 'No more planted plots found';
    return false;
  }

  void finishWatering() {
    setState(() {
      isWatering = false;
      robotPosition = null;
      debugInfo = 'Finished watering';
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Watering Complete',
              style: GoogleFonts.dancingScript(fontSize: 24)),
          content:
              Text('The robot has finished watering $wateredPlants plants!'),
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
              '2. Press water drop to start watering\n'
              '3. Spider waters planted tulips (blue)\n'
              '4. Refresh button resets the game',
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
                      if (robotPosition != null)
                        Positioned(
                          left: robotPosition!.dx - hexSize / 2,
                          top: robotPosition!.dy - hexSize / 2,
                          child: RobotWidget(size: hexSize),
                        ),
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
              onPressed: startWatering,
              tooltip: 'Start Watering',
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
    _controller.dispose();
    super.dispose();
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

class RobotWidget extends StatelessWidget {
  final double size;

  const RobotWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text('🕷️', style: TextStyle(fontSize: size * 0.6)),
      ),
    );
  }
}
