import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ArxivDisclaimer extends StatelessWidget {
  const ArxivDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.warningSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: palette.warningBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: palette.warningIcon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This paper is sourced from arXiv and may not have undergone formal peer review.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: palette.warningText,
                fontFamily: '-apple-system',
              ),
            ),
          ),
        ],
      ),
    );
  }
}