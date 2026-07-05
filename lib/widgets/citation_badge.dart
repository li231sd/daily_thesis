import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CitationBadge extends StatelessWidget {
  final int count;
  const CitationBadge(this.count, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: palette.borderSoft,
          width: 1,
        ),
      ),
      child: Text(
        '$count citations',
        style: TextStyle(
          fontSize: 11,
          fontFamily: '-apple-system',
          color: palette.textSecondary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}