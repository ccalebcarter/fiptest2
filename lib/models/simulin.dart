// models/simulin.dart

import '../utils/enums.dart';

class Simulin {
  final String name;
  final SimulinType type;
  bool isAssigned;
  int level;
  int experience;

  Simulin({
    required this.name,
    required this.type,
    this.isAssigned = false,
    this.level = 1,
    this.experience = 0,
  });

  void gainExperience(int amount) {
    experience += amount;
    if (experience >= 100 * level) {
      level++;
      experience = 0;
    }
  }
}