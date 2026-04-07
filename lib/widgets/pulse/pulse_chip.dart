import 'package:flutter/material.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';

class PulseChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? color;
  final Color? activeColor;

  const PulseChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.color,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? (activeColor ?? AppColors.primary) : (color ?? AppColors.surfaceDark),
          borderRadius: BorderRadius.circular(30), // rounded-full
          border: isActive ? null : Border.all(color: AppColors.slate800),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.slate400,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
