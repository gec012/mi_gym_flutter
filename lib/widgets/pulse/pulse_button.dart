import 'package:flutter/material.dart';
import 'package:mi_gym_flutter/theme/app_colors.dart';

class PulseButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;
  final Widget? icon;
  final double? width;
  final bool isLoading;
  final Color? backgroundColor;

  const PulseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    this.icon,
    this.width,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? (isSecondary ? AppColors.surfaceDark : AppColors.primary),
      foregroundColor: isSecondary ? Colors.white : Colors.white,
      minimumSize: Size(width ?? double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // rounded-2xl
        side: isSecondary ? BorderSide(color: AppColors.slate800) : BorderSide.none,
      ),
      elevation: 0,
    );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
    );
  }
}
