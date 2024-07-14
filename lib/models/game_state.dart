// models/game_state.dart

import '../utils/constants.dart';
import 'field.dart';
import 'simulin.dart';
import 'contract.dart';
import '../utils/enums.dart';

class GameState {
  int day = 1;
  int credits = GameConstants.INITIAL_CREDITS;
  List<Field> fields = [];
  List<Simulin> availableSimulins = [];
  List<Simulin> assignedSimulins = [];
  List<Contract> activeContracts = [];

  GameState() {
    // Initialize with one field and some basic Simulins
    fields.add(Field(name: "Starter Field", rows: 5, cols: 5));
    availableSimulins = [
      Simulin(name: "WaterBot 1", type: SimulinType.water),
      Simulin(name: "FertilizerBot", type: SimulinType.fertilizer),
      Simulin(name: "SeederBot", type: SimulinType.seeding),
      Simulin(name: "HarvesterBot", type: SimulinType.harvesting),
      Simulin(name: "PestControlBot", type: SimulinType.pestControl),
    ];
    // Add an initial contract
    activeContracts.add(Contract(
      description: "Grow 10 tulips",
      cropType: CropType.tulip,
      targetQuantity: 10,
      rewardCredits: 500,
    ));
  }

  void advanceDay() {
    day++;
    // Additional logic for daily updates can be added here
  }
}