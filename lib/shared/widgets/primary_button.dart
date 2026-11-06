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

  /// Null disables the button, for a form that is not ready to submit.
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = outline ? AppColors.gold : AppColors.black;
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: enabled ? foreground : AppColors.secondaryText(context),
    );

    return PressableScale(
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: outline
                ? AppColors.surface(context)
                : AppColors.goldBright,
            // styleFrom's explicit background wins over the theme's disabled
            // colour, so the disabled look has to be spelled out too.
            disabledBackgroundColor: AppColors.subtle(context),
            side: BorderSide(
              color: enabled
                  ? (outline ? AppColors.gold : AppColors.goldBright)
                  : AppColors.subtle(context),
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
                  color: enabled
                      ? foreground
                      : AppColors.secondaryText(context),
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
