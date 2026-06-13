import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/shared/widgets/pressable_scale.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outline = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: outline ? AppColors.gold : AppColors.black,
    );

    return PressableScale(
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: outline ? AppColors.white : AppColors.goldBright,
            side: BorderSide(
              color: outline ? AppColors.gold : AppColors.goldBright,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 19,
                  color: outline ? AppColors.gold : AppColors.black,
                ),
                const SizedBox(width: 10),
              ],
              Text(label, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}
