import 'package:flutter/material.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';

class PulseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double borderRadius;
  final BoxBorder? border;

  const PulseCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius = 24, // Rule: rounded-3xl
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = color ?? AppColors.surfaceDark; // default for dark theme

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Rule: rgba(0,0,0,0.05)
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
