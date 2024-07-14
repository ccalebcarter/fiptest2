// models/plot.dart

import '../utils/enums.dart';

class Plot {
  PlotState state;
  CropType? cropType;
  List<SimulinType> treatedBy;
  int health;

  Plot({
    this.state = PlotState.empty,
    this.cropType,
    this.treatedBy = const [],
    this.health = 100,
  });
}