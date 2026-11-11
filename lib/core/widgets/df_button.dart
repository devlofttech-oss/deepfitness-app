import 'package:deepfitness/app/colors.dart';
import 'package:flutter/material.dart';

/// The primary call to action: full width, 52 high, solid accent, near
/// black uppercase condensed label.
///
/// The accent is scarce by design, so there is at most one of these on a
/// screen at a time.
class DfPrimaryButton extends StatelessWidget {
  const DfPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon = Icons.arrow_forward,
    this.showTrailingIcon = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData trailingIcon;
  final bool showTrailingIcon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onPrimaryContainer,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label.toUpperCase()),
                if (showTrailingIcon) ...[
                  const SizedBox(width: Insets.sm),
                  Icon(trailingIcon, size: 18),
                ],
              ],
            ),
    );
  }
}

/// The secondary action: dark fill, 1px border, white label.
class DfSecondaryButton extends StatelessWidget {
  const DfSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: Insets.sm),
          ],
          Text(label.toUpperCase()),
        ],
      ),
    );
  }
}
