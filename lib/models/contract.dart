// models/contract.dart

import '../utils/enums.dart';

class Contract {
  final String description;
  final CropType cropType;
  final int targetQuantity;
  final int rewardCredits;
  int currentQuantity;

  Contract({
    required this.description,
    required this.cropType,
    required this.targetQuantity,
    required this.rewardCredits,
    this.currentQuantity = 0,
  });

  bool get isComplete => currentQuantity >= targetQuantity;
}