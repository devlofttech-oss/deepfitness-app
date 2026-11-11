import 'package:deepfitness/app/colors.dart';
import 'package:flutter/material.dart';

/// A Level 1 surface: flat fill, 1px border, 8px corners.
///
/// The design system rejects drop shadows — under gym lighting a blur
/// washes out and costs contrast — so depth here is tonal layering plus
/// the border, and nothing else.
class DfCard extends StatelessWidget {
  const DfCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Insets.md),
    this.onTap,
    this.colour = AppColors.surfaceContainerLow,
    this.borderColour = AppColors.surfaceContainerHigh,
    this.radius = Radii.base,
    this.leadingAccent = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color colour;
  final Color borderColour;
  final double radius;

  /// Draws the accent bar down the left edge, used to mark the one item
  /// that is up next.
  final bool leadingAccent;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);

    return Material(
      color: colour,
      borderRadius: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(
              color: leadingAccent ? AppColors.primaryContainer : borderColour,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leadingAccent)
                const SizedBox(
                  width: 4,
                  child: ColoredBox(color: AppColors.primaryContainer),
                ),
              Expanded(child: Padding(padding: padding, child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

/// An uppercase condensed label, the system's workhorse for anything
/// that is not a sentence.
class DfLabel extends StatelessWidget {
  const DfLabel(
    this.text, {
    super.key,
    this.colour = AppColors.onSurfaceVariant,
    this.size = DfLabelSize.small,
  });

  final String text;
  final Color colour;
  final DfLabelSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final style = switch (size) {
      DfLabelSize.small => theme.labelSmall,
      DfLabelSize.medium => theme.labelMedium,
      DfLabelSize.large => theme.labelLarge,
    };

    return Text(text.toUpperCase(), style: style?.copyWith(color: colour));
  }
}

enum DfLabelSize { small, medium, large }

/// A pill. Unselected is a bordered dark chip; selected is solid accent
/// with near-black text, which is the only place a large fill of the
/// yellow is allowed.
class DfChip extends StatelessWidget {
  const DfChip({
    super.key,
    required this.label,
    this.selected = false,
    this.icon,
    this.onTap,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(Radii.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.full),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.full),
            border: Border.all(
              color: selected
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerHigh,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: Insets.xs),
              ],
              DfLabel(
                label,
                colour: selected
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A metric: a big condensed numeral over a compact uppercase caption.
class DfStat extends StatelessWidget {
  const DfStat({
    super.key,
    required this.value,
    required this.caption,
    this.suffix,
    this.icon,
    this.valueColour = AppColors.onSurface,
  });

  final String value;
  final String caption;
  final String? suffix;
  final IconData? icon;
  final Color valueColour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.primaryContainer),
          const SizedBox(height: Insets.sm),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: theme.displayMedium?.copyWith(color: valueColour),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 2),
              Text(
                suffix!,
                style: theme.headlineMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: Insets.xs),
        DfLabel(caption),
      ],
    );
  }
}

/// A section heading with an optional trailing action.
class DfSectionHeader extends StatelessWidget {
  const DfSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: DfLabel(trailing!, colour: AppColors.primaryContainer),
            ),
        ],
      ),
    );
  }
}

/// The empty and error state used across the member screens.
class DfMessage extends StatelessWidget {
  const DfMessage({
    super.key,
    required this.title,
    required this.body,
    this.icon,
  });

  final String title;
  final String body;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 40, color: AppColors.outline),
              const SizedBox(height: Insets.md),
            ],
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Insets.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      ),
    );
  }
}
