// models/field.dart

import 'plot.dart';

class Field {
  final String name;
  final int rows;
  final int cols;
  late List<List<Plot>> plots;

  Field({required this.name, required this.rows, required this.cols}) {
    resetField();
  }

  void resetField() {
    plots = List.generate(rows, (_) => List.generate(cols, (_) => Plot()));
  }
}