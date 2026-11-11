import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/widgets/df_button.dart';
import 'package:deepfitness/core/widgets/df_card.dart';
import 'package:flutter/material.dart';

/// The reasons offered first, so most skips take one tap.
const _presetReasons = <String>[
  'Equipment was busy',
  'Injury or pain',
  'Running short of time',
  'Too difficult today',
];

/// Asks why an exercise is being skipped.
///
/// Returns the reason, or null if the member backed out. The document
/// requires a reason on every skip: it is what keeps a skipped exercise
/// readable in a report instead of an unexplained gap.
Future<String?> showSkipReasonSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    // Level 2 surface with its own border, so it reads as floating
    // above the cards rather than merging with them.
    backgroundColor: AppColors.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      side: BorderSide(color: AppColors.surfaceContainerHighest),
    ),
    builder: (context) => const _SkipReasonSheet(),
  );
}

class _SkipReasonSheet extends StatefulWidget {
  const _SkipReasonSheet();

  @override
  State<_SkipReasonSheet> createState() => _SkipReasonSheetState();
}

class _SkipReasonSheetState extends State<_SkipReasonSheet> {
  final _otherController = TextEditingController();
  String? _selected;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  String get _reason =>
      _selected == _otherLabel ? _otherController.text.trim() : (_selected ?? '');

  static const _otherLabel = 'Another reason';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Radii.full),
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          Text(
            'WHY ARE YOU SKIPPING THIS?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Insets.xs),
          Text(
            'The plan still moves on, so you are never stuck. The reason '
            'is what makes this readable in your report later.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Insets.md),
          // Plain tiles rather than RadioListTile: the radio group API has
          // churned across Flutter versions and this needs no part of it.
          for (final reason in [..._presetReasons, _otherLabel])
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: DfCard(
                onTap: () => setState(() => _selected = reason),
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.md,
                  vertical: Insets.md,
                ),
                colour: AppColors.surfaceContainer,
                borderColour: _selected == reason
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(
                      _selected == reason
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: _selected == reason
                          ? AppColors.primaryContainer
                          : AppColors.outline,
                    ),
                    const SizedBox(width: Insets.md),
                    Expanded(child: Text(reason)),
                  ],
                ),
              ),
            ),
          if (_selected == _otherLabel)
            TextField(
              controller: _otherController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Tell us briefly'),
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: Insets.md),
          DfPrimaryButton(
            label: 'Skip and move on',
            trailingIcon: Icons.skip_next,
            // Disabled until there is something to record, because a skip
            // without a reason is exactly what the rule is there to stop.
            // Disabled until there is a reason, because a skip without
            // one is exactly what the rule exists to stop.
            onPressed: _reason.isEmpty
                ? null
                : () => Navigator.of(context).pop(_reason),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
