// screens/game_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_state.dart';
import '../models/simulin.dart'; // Add this import
import '../models/field.dart';
import '../models/plot.dart';
import '../widgets/hexagon_tile.dart';
import '../widgets/simulin_widget.dart';
import '../widgets/organic_box_painter.dart';
import '../widgets/simulin_assignment_card.dart';
import '../services/game_logic.dart';
import '../utils/constants.dart';
import '../utils/enums.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameState gameState;
  late double hexSize;
  List<Offset?> robotPositions = [];
  late List<AnimationController> _controllers;
  bool isSimulinsActive = false;
  String debugInfo = '';
  int currentFieldIndex = 0;

  @override
  void initState() {
    super.initState();
    gameState = GameState();
    _controllers = [];
  }

  void resetGame() {
    setState(() {
      gameState = GameState();
      robotPositions = [];
      _controllers = [];
      isSimulinsActive = false;
      currentFieldIndex = 0;
      debugInfo = 'Game reset';
    });
  }

  void plantCrop(int fieldIndex, int row, int col) {
    setState(() {
      if (GameLogic.plantCrop(
          gameState, fieldIndex, row, col, CropType.tulip)) {
        debugInfo =
            'Crop planted at ($row, $col) in ${gameState.fields[fieldIndex].name}';
      } else {
        debugInfo =
            'Cannot plant at ($row, $col) in ${gameState.fields[fieldIndex].name}. State: ${gameState.fields[fieldIndex].plots[row][col].state}';
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
              title: Text('Assign Simulins', style: TextStyle(fontSize: 24)),
              content: SimulinAssignmentCard(
                availableSimulins: gameState.availableSimulins,
                onAssign: (List<Simulin> selected) {
                  setState(() {
                    gameState.assignedSimulins = selected;
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
                  child: Text('Start Working'),
                  onPressed: gameState.assignedSimulins.length == 3
                      ? () {
                          Navigator.of(context).pop();
                          startSimulins();
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

  void startSimulins() {
    Field currentField = gameState.fields[currentFieldIndex];
    List<Offset> plantedPlots = [];
    for (int row = 0; row < currentField.rows; row++) {
      for (int col = 0; col < currentField.cols; col++) {
        if (currentField.plots[row][col].state == PlotState.planted) {
          plantedPlots.add(_getHexagonCenter(row, col));
        }
      }
    }

    if (plantedPlots.isEmpty) {
      showNoPlantedPlotsDialog();
      return;
    }

    setState(() {
      robotPositions = List.generate(
          gameState.assignedSimulins.length, (_) => plantedPlots.first);
      _controllers = List.generate(
        gameState.assignedSimulins.length,
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
              GameLogic.workOnAllPlots(gameState, currentFieldIndex, index);
              if (_controllers.every((controller) => controller.isCompleted)) {
                finishSimulinsWork();
              }
            }
          }),
      );
      isSimulinsActive = true;
      debugInfo = 'Simulins started working';
    });

    for (var controller in _controllers) {
      controller.forward();
    }
  }

  void showNoPlantedPlotsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Planted Crops', style: TextStyle(fontSize: 24)),
          content: Text(
              'There are no planted crops to work on. Please plant some crops first.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void finishSimulinsWork() {
    setState(() {
      isSimulinsActive = false;
      robotPositions = [];
      for (var simulin in gameState.availableSimulins) {
        simulin.isAssigned = false;
      }
      debugInfo = 'Simulins finished working';
    });
    showWorkSummary();
  }

  void showWorkSummary() {
    int treatedPlots = 0;
    int harvestedPlots = 0;
    Field currentField = gameState.fields[currentFieldIndex];

    for (int row = 0; row < currentField.rows; row++) {
      for (int col = 0; col < currentField.cols; col++) {
        Plot plot = currentField.plots[row][col];
        if (plot.treatedBy.isNotEmpty) {
          treatedPlots++;
        }
        if (plot.state == PlotState.harvested) {
          harvestedPlots++;
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Work Complete', style: TextStyle(fontSize: 24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('The Simulins have finished their work!'),
              SizedBox(height: 10),
              Text('Treated plots: $treatedPlots'),
              Text('Harvested plots: $harvestedPlots'),
              Text(
                  'Credits earned: ${harvestedPlots * GameConstants.HARVEST_REWARD}'),
              SizedBox(height: 10),
              ...gameState.assignedSimulins.map((simulin) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SimulinIcon(type: simulin.type, size: 24),
                      Text(
                          '${simulin.name}: Level ${simulin.level} (${simulin.experience}/100 XP)'),
                    ],
                  )),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                advanceDay();
              },
            ),
          ],
        );
      },
    );
  }

  void advanceDay() {
    setState(() {
      GameLogic.advanceDay(gameState);
      debugInfo = 'Advanced to day ${gameState.day}';
    });
    if (gameState.day > GameConstants.SEASON_LENGTH) {
      endSeason();
    }
  }

  void endSeason() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Season Complete', style: TextStyle(fontSize: 24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Congratulations! You have completed the ${GameConstants.SEASON_LENGTH}-day season.'),
              SizedBox(height: 10),
              Text('Final Credits: ${gameState.credits}'),
              Text('Fields Managed: ${gameState.fields.length}'),
              Text('Simulins Owned: ${gameState.availableSimulins.length}'),
              Text(
                  'Contracts Completed: ${gameState.activeContracts.where((contract) => contract.isComplete).length}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Start New Season'),
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
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
        return Colors.brown[200]!;
      case PlotState.planted:
        return Colors.green[300]!;
      case PlotState.watered:
        return Colors.blue[200]!;
      case PlotState.fertilized:
        return Colors.purple[200]!;
      case PlotState.harvested:
        return Colors.yellow[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    hexSize = (screenSize.width * 0.8) /
        ((gameState.fields[currentFieldIndex].cols * 1.5 + 0.5) * 1.2);
    final boardWidth =
        (gameState.fields[currentFieldIndex].cols * 1.5 + 0.5) * hexSize;
    final boardHeight =
        (gameState.fields[currentFieldIndex].rows * sqrt(3) + 1) * hexSize;

    return Scaffold(
      backgroundColor: GameConstants.BACKGROUND_COLOR,
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 0,
        title: Text(
          'Farming in Purria',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Day: ${gameState.day}/${GameConstants.SEASON_LENGTH}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Credits: ${gameState.credits}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  child: Text('Next Day'),
                  onPressed: advanceDay,
                ),
              ],
            ),
          ),
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
                        gameState.fields[currentFieldIndex].rows,
                        (row) => List.generate(
                          gameState.fields[currentFieldIndex].cols,
                          (col) => Positioned(
                            left: (col * 1.5 + 0.5) * hexSize,
                            top: (row * sqrt(3) +
                                    (col % 2 == 1 ? sqrt(3) / 2 : 0) +
                                    0.5) *
                                hexSize,
                            child: GestureDetector(
                              onTap: () =>
                                  plantCrop(currentFieldIndex, row, col),
                              child: HexagonTile(
                                size: hexSize,
                                color: _getColorForState(gameState
                                    .fields[currentFieldIndex]
                                    .plots[row][col]
                                    .state),
                                state: gameState.fields[currentFieldIndex]
                                    .plots[row][col].state,
                                treatedBy: gameState.fields[currentFieldIndex]
                                    .plots[row][col].treatedBy,
                                health: gameState.fields[currentFieldIndex]
                                    .plots[row][col].health,
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
                                  simulin: gameState.assignedSimulins[index],
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
            child: Text(debugInfo, style: TextStyle(color: Colors.green[800])),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isSimulinsActive)
            FloatingActionButton(
              onPressed: showSimulinAssignmentCard,
              tooltip: 'Assign Simulins',
              backgroundColor: Colors.blue,
              child: const Icon(Icons.group_add),
            ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Game Menu', style: TextStyle(fontSize: 24)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          child: Text('View Contracts'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            showContractsDialog();
                          },
                        ),
                        ElevatedButton(
                          child: Text('Shop'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            showShopDialog();
                          },
                        ),
                        ElevatedButton(
                          child: Text('Reset Game'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            resetGame();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            tooltip: 'Game Menu',
            backgroundColor: Colors.green,
            child: const Icon(Icons.menu),
          ),
        ],
      ),
    );
  }

  void showContractsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Active Contracts', style: TextStyle(fontSize: 24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: gameState.activeContracts
                .map((contract) => ListTile(
                      title: Text(contract.description),
                      subtitle: Text(
                          'Progress: ${contract.currentQuantity}/${contract.targetQuantity}'),
                      trailing: Text('${contract.rewardCredits} credits'),
                    ))
                .toList(),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showShopDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Shop', style: TextStyle(fontSize: 24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                    'Buy New Field (${GameConstants.NEW_FIELD_COST} credits)'),
                onTap: () {
                  if (GameLogic.purchaseField(gameState)) {
                    setState(() {});
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('New field purchased!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Not enough credits!')));
                  }
                },
              ),
              ListTile(
                title: Text(
                    'Buy New Simulin (${GameConstants.NEW_SIMULIN_COST} credits)'),
                onTap: () {
                  if (GameLogic.purchaseSimulin(gameState)) {
                    setState(() {});
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('New Simulin purchased!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Not enough credits!')));
                  }
                },
              ),
            ],
          ),
        );
      },
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
