import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/widgets/primary_button.dart';
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
    backgroundColor: AppColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          Text(
            'Why are you skipping this?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // Plain tiles rather than RadioListTile: the radio group API has
          // churned across Flutter versions and this needs no part of it.
          for (final reason in [..._presetReasons, _otherLabel])
            InkWell(
              onTap: () => setState(() => _selected = reason),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _selected == reason
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _selected == reason
                          ? AppColors.gold
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 12),
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
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Skip and move on',
            // Disabled until there is something to record, because a skip
            // without a reason is exactly what the rule is there to stop.
            onPressed: _reason.isEmpty
                ? () {}
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
