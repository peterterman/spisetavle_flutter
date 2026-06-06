import 'dart:io';

class AppSizes {
  static double get _factor => Platform.isIOS ? 1.10 : 1.00;

  static double get title => 22.0 * _factor;
  static double get heading => 18.0 * _factor;
  static double get normal => 16.0 * _factor;
  static double get small => 14.0 * _factor;

  static const nutrientLabelWidth = 140.0;
  static const nutrientValueWidth = 35.0;
  static const nutrientGoalWidth = 50.0;
}
