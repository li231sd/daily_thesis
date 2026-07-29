import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class StreakBadge extends StatelessWidget {
  final int currentStreak;
  final int freezesAvailable;
  final bool atRisk;

  const StreakBadge({
    super.key,
    required this.currentStreak,
    required this.freezesAvailable,
    this.atRisk = false,
  });

  void _showStreakInfoModal(BuildContext context) {
    HapticFeedback.lightImpact();
    final palette = AppPalette.of(context);
    final flameColor = atRisk ? Colors.grey : Colors.deepOrange;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title & Current Status
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: flameColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$currentStreak-Day Streak',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            freezesAvailable > 0
                                ? '$freezesAvailable freeze protection available'
                                : 'No streak freezes remaining',
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: palette.border, height: 1),
                const SizedBox(height: 20),

                // How it works items
                _buildInfoRow(
                  icon: Icons.timer_outlined,
                  title: '1 Minute Daily Read',
                  description:
                      'Spend at least 1 minute in the app reading papers each day to maintain your streak.',
                  palette: palette,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.ac_unit_rounded,
                  iconColor: Colors.lightBlue.shade400,
                  title: 'Earn Ice Every Week',
                  description:
                      'Complete a 7-day streak to automatically earn 1 Streak Freeze (ice).',
                  palette: palette,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.shield_outlined,
                  iconColor: Colors.amber.shade700,
                  title: 'Automatic Protection',
                  description:
                      'If you miss a day, an ice freeze is automatically consumed to protect your hard-earned streak.',
                  palette: palette,
                ),

                const SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: palette.buttonSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Got It',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.buttonSecondaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String description,
    required AppPalette palette,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? palette.textPrimary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? palette.textPrimary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flameColor = atRisk ? Colors.grey : Colors.deepOrange;

    return GestureDetector(
      onTap: () => _showStreakInfoModal(context),
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: 'Streak details',
        child: Semantics(
          label: '$currentStreak day streak. Tap for details.',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department, color: flameColor, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$currentStreak',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: atRisk ? Colors.grey : theme.colorScheme.onSurface,
                  ),
                ),
                if (freezesAvailable > 0) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.ac_unit, color: Colors.lightBlue.shade300, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '$freezesAvailable',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.lightBlue.shade300,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
