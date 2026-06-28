import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 54,
    this.background,
    this.iconColor,
  });

  final IconData icon;
  final double size;
  final Color? background;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? AppColors.chipBackground(context),
        borderRadius: BorderRadius.circular(size * .24),
      ),
      child: Icon(icon, color: iconColor ?? AppColors.gold, size: size * .42),
    );
  }
}
