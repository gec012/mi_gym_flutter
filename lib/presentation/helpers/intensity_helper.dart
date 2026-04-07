import 'package:flutter/material.dart';
import 'package:mi_gym_flutter/domain/entities/gym_class_entity.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';

class IntensityHelper {
  static String getLabel(ClassIntensity intensity) {
    switch (intensity) {
      case ClassIntensity.low:
        return 'Low';
      case ClassIntensity.medium:
        return 'Medium';
      case ClassIntensity.high:
        return 'High';
    }
  }

  static Color getColor(ClassIntensity intensity) {
    switch (intensity) {
      case ClassIntensity.low:
        return AppColors.success;
      case ClassIntensity.medium:
        return AppColors.primary;
      case ClassIntensity.high:
        return AppColors.intense;
    }
  }
}
