import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/streak_data.dart';
import '../theme/app_theme.dart';

enum DayStreakStatus {
  completed,
  frozen,
  missed,
  pending, // today, not logged yet — neutral, not a failure
  future,
}

class StreakBadge extends StatelessWidget {
  final StreakData streakData;

  const StreakBadge({
    super.key,
    required this.streakData,
  });

  int get currentStreak => streakData.currentStreak;
  int get freezesAvailable => streakData.freezesAvailable;
  bool get atRisk => streakData.atRisk;

  void _showStreakInfoModal(BuildContext context) {
    HapticFeedback.lightImpact();
    final palette = AppPalette.of(context);
    final flameColor = atRisk ? palette.textSecondary : Colors.deepOrange;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // REMOVED SafeArea here so the background stretches to the very bottom
        return Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 30,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            // The MediaQuery padding handles the safe area perfectly inside the modal
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
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

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: flameColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: flameColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$currentStreak Day Streak',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            atRisk
                                ? 'Read a paper today to keep your streak active'
                                : 'You\'re on track! Keep reading daily.',
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

                const SizedBox(height: 24),

                Text(
                  'WEEKLY ACTIVITY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildWeeklyTracker(context, palette),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: palette.buttonSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: palette.buttonSecondaryBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.ac_unit_rounded,
                        size: 18,
                        color: Colors.lightBlue.shade400,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          freezesAvailable > 0
                              ? '$freezesAvailable Freeze Available (Auto-protects missed days)'
                              : '0 Freezes Remaining (Earn 1 every 7-day streak)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: palette.buttonSecondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: palette.buttonSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Back to Reading',
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

  /// Maps specific Date instances of current week to exact DayStreakStatus from history
  DayStreakStatus _getDayStatusForDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate.isAfter(today)) {
      return DayStreakStatus.future;
    }

    final key = StreakData.dateKey(date);
    final status = streakData.history[key];

    switch (status) {
      case DayStatus.completed:
        return DayStreakStatus.completed;
      case DayStatus.frozen:
        return DayStreakStatus.frozen;
      case DayStatus.missed:
        return DayStreakStatus.missed;
      case null:
        return targetDate.isAtSameMomentAs(today)
            ? DayStreakStatus.pending
            : DayStreakStatus.missed;
    }
  }

  Widget _buildWeeklyTracker(BuildContext context, AppPalette palette) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();

    // Calculate Monday date for current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = monday.add(Duration(days: index));
        final isToday = date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;

        final status = _getDayStatusForDate(date);

        Color circleColor;
        Color borderColor;
        Color textColor;
        Widget child;

        switch (status) {
          case DayStreakStatus.completed:
            circleColor = Colors.deepOrange.withValues(alpha: 0.15);
            borderColor = Colors.deepOrange;
            textColor = palette.textPrimary;
            child = const Icon(
              Icons.local_fire_department_rounded,
              size: 16,
              color: Colors.deepOrange,
            );
            break;

          case DayStreakStatus.frozen:
            // MATCHES completed (fire) design pattern
            circleColor = Colors.lightBlue.shade400.withValues(alpha: 0.15);
            borderColor = Colors.lightBlue.shade400;
            textColor = palette.textPrimary;
            child = Icon(
              Icons.ac_unit_rounded,
              size: 16, // Matches the fire size
              color: Colors.lightBlue.shade400,
            );
            break;

          case DayStreakStatus.missed:
            circleColor = palette.buttonSecondary;
            borderColor = palette.border;
            textColor = palette.textSecondary;
            child = Icon(
              Icons.close_rounded,
              size: 16,
              color: Colors.grey.shade500,
            );
            break;

          case DayStreakStatus.pending:
            circleColor = palette.buttonSecondary;
            borderColor = palette.buttonSecondaryBorder.withValues(alpha: 0.3);
            textColor = palette.textSecondary;
            child = Text(
              dayLabels[index],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            );
            break;

          case DayStreakStatus.future:
            circleColor = palette.buttonSecondary;
            borderColor = palette.buttonSecondaryBorder.withValues(alpha: 0.3);
            textColor = palette.textSecondary;
            child = Text(
              dayLabels[index],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            );
            break;
        }

        return Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isToday &&
                          status != DayStreakStatus.missed &&
                          status != DayStreakStatus.pending
                      ? (atRisk ? Colors.grey : Colors.deepOrange)
                      : borderColor,
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Center(child: child),
            ),
            const SizedBox(height: 6),
            Text(
              dayLabels[index],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday ? palette.textPrimary : palette.textSecondary,
              ),
            ),
          ],
        );
      }),
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
                Icon(Icons.local_fire_department_rounded, color: flameColor, size: 20),
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
                  Icon(Icons.ac_unit_rounded, color: Colors.lightBlue.shade300, size: 14),
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
