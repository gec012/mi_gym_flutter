import 'package:flutter/material.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';

class PulseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? color;
  final Border? border;
  final bool hasShadow;

  const PulseCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.color,
    this.border,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24), // rounded-3xl
        border: border ?? Border.all(color: AppColors.slate800.withValues(alpha: 0.5)),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
