import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 54,
    this.background = AppColors.goldSoft,
    this.iconColor = AppColors.gold,
  });

  final IconData icon;
  final double size;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * .24),
      ),
      child: Icon(icon, color: iconColor, size: size * .42),
    );
  }
}
