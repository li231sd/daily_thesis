import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/interest_matcher.dart';
import '../theme/app_theme.dart';

class InterestPicker extends StatelessWidget {
  final Set<String> selectedLabels;
  final ValueChanged<String> onToggle;

  const InterestPicker({
    super.key,
    required this.selectedLabels,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in InterestMatcher.groupedOptions.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 20),
            child: Text(
              entry.key.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in entry.value)
                _InterestChip(
                  label: option.label,
                  selected: selectedLabels.contains(option.label),
                  onTap: () => onToggle(option.label),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? palette.chipSelectedBackground : palette.chipUnselectedBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? palette.chipSelectedBorder : palette.chipUnselectedBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: '-apple-system',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? palette.chipSelectedText : palette.chipUnselectedText,
          ),
        ),
      ),
    );
  }
}
