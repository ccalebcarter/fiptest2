// services/game_logic.dart

import 'dart:math';
import '../models/game_state.dart';
import '../models/field.dart';
import '../models/plot.dart';
import '../models/simulin.dart';
import '../models/contract.dart';
import '../utils/enums.dart';
import '../utils/constants.dart';

class GameLogic {
  static void advanceDay(GameState gameState) {
    gameState.day++;
    updateCropStates(gameState);
    checkContracts(gameState);
  }

  static void updateCropStates(GameState gameState) {
    for (var field in gameState.fields) {
      for (var row in field.plots) {
        for (var plot in row) {
          if (plot.state != PlotState.empty && plot.state != PlotState.harvested) {
            // Decrease crop health if not tended
            plot.health = max(0, plot.health - 10);
            
            // Progress crop growth if healthy
            if (plot.health > 50) {
              switch (plot.state) {
                case PlotState.planted:
                  plot.state = PlotState.watered;
                  break;
                case PlotState.watered:
                  plot.state = PlotState.fertilized;
                  break;
                case PlotState.fertilized:
                  plot.state = PlotState.harvested;
                  break;
                default:
                  break;
              }
            }
            
            // Reset treated by for the new day
            plot.treatedBy.clear();
          }
        }
      }
    }
  }

  static void checkContracts(GameState gameState) {
    List<Contract> completedContracts = gameState.activeContracts.where((contract) => contract.isComplete).toList();
    for (var contract in completedContracts) {
      gameState.credits += contract.rewardCredits;
      gameState.activeContracts.remove(contract);
    }
  }

  static void workOnAllPlots(GameState gameState, int fieldIndex, int simulinIndex) {
    Field currentField = gameState.fields[fieldIndex];
    for (int row = 0; row < currentField.rows; row++) {
      for (int col = 0; col < currentField.cols; col++) {
        Plot plot = currentField.plots[row][col];
        if (plot.state == PlotState.planted || plot.state == PlotState.watered) {
          SimulinType simulinType = gameState.assignedSimulins[simulinIndex].type;
          if (!plot.treatedBy.contains(simulinType)) {
            plot.treatedBy.add(simulinType);
            gameState.assignedSimulins[simulinIndex].gainExperience(10);
            
            switch (simulinType) {
              case SimulinType.water:
                if (plot.state == PlotState.planted) {
                  plot.state = PlotState.watered;
                }
                break;
              case SimulinType.fertilizer:
                if (plot.state == PlotState.watered) {
                  plot.state = PlotState.fertilized;
                }
                break;
              case SimulinType.harvesting:
                if (plot.state == PlotState.fertilized) {
                  plot.state = PlotState.harvested;
                  gameState.credits += GameConstants.HARVEST_REWARD;
                  for (var contract in gameState.activeContracts) {
                    if (contract.cropType == plot.cropType) {
                      contract.currentQuantity++;
                    }
                  }
                }
                break;
              default:
                break;
            }
          }
        }
      }
    }
  }

  static bool plantCrop(GameState gameState, int fieldIndex, int row, int col, CropType cropType) {
    Field field = gameState.fields[fieldIndex];
    if (field.plots[row][col].state == PlotState.empty) {
      field.plots[row][col].state = PlotState.planted;
      field.plots[row][col].cropType = cropType;
      return true;
    }
    return false;
  }

  static bool purchaseField(GameState gameState) {
    if (gameState.credits >= GameConstants.NEW_FIELD_COST) {
      gameState.credits -= GameConstants.NEW_FIELD_COST;
      gameState.fields.add(Field(name: "New Field ${gameState.fields.length + 1}", rows: 5, cols: 5));
      return true;
    }
    return false;
  }

  static bool purchaseSimulin(GameState gameState) {
    if (gameState.credits >= GameConstants.NEW_SIMULIN_COST) {
      gameState.credits -= GameConstants.NEW_SIMULIN_COST;
      gameState.availableSimulins.add(Simulin(
        name: "New Simulin ${gameState.availableSimulins.length + 1}",
        type: SimulinType.values[Random().nextInt(SimulinType.values.length)],
      ));
      return true;
    }
    return false;
  }
}