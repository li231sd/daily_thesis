import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Enum representing the status of a specific day in the weekly calendar
enum DayStreakStatus {
  completed, // Day target met (Orange Fire)
  frozen,    // Day saved by Streak Freeze (Blue Ice)
  missed,    // Missed day or prior day without activity (Grey X)
  future,    // Future day not reached yet
}

class StreakBadge extends StatelessWidget {
  final int currentStreak;
  final int freezesAvailable;
  final bool atRisk;

  /// Optional map of weekday indices (0 = Monday, 6 = Sunday) to status.
  /// If not provided, it infers status based on current streak & atRisk flag.
  final Map<int, DayStreakStatus>? weeklyStatuses;

  const StreakBadge({
    super.key,
    required this.currentStreak,
    required this.freezesAvailable,
    this.atRisk = false,
    this.weeklyStatuses,
  });

  void _showStreakInfoModal(BuildContext context) {
    HapticFeedback.lightImpact();
    final palette = AppPalette.of(context);
    final flameColor = atRisk ? palette.textSecondary : Colors.deepOrange;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
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
                  // Drag Handle
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

                  // Header Status Block
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

                  // Visual 7-Day Activity Bar
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
                  _buildWeeklyTracker(palette),

                  const SizedBox(height: 20),

                  // Freeze Protection Pill / Card
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

                  // Secondary Close Action
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
          ),
        );
      },
    );
  }

  /// Evaluates status for each day (0 = Monday, 6 = Sunday)
  DayStreakStatus _getDayStatus(int dayIndex, int todayIndex) {
    if (weeklyStatuses != null && weeklyStatuses!.containsKey(dayIndex)) {
      return weeklyStatuses![dayIndex]!;
    }

    if (dayIndex > todayIndex) {
      return DayStreakStatus.future;
    }

    if (dayIndex == todayIndex) {
      return atRisk ? DayStreakStatus.missed : DayStreakStatus.completed;
    }

    // Default fallback calculation for past days:
    // If streak covers this past day, count as completed; otherwise missed.
    final daysAgo = todayIndex - dayIndex;
    final effectiveStreak = atRisk ? currentStreak : currentStreak - 1;

    if (daysAgo <= effectiveStreak) {
      return DayStreakStatus.completed;
    }

    return DayStreakStatus.missed;
  }

  /// Builds a visual 7-day streak progress bar (M T W T F S S)
  Widget _buildWeeklyTracker(AppPalette palette) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = (DateTime.now().weekday - 1) % 7;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isToday = index == todayIndex;
        final status = _getDayStatus(index, todayIndex);

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
            circleColor = Colors.lightBlue.shade50;
            borderColor = Colors.lightBlue.shade300;
            textColor = palette.textPrimary;
            child = Icon(
              Icons.ac_unit_rounded,
              size: 15,
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

          case DayStreakStatus.future:
            circleColor = palette.buttonSecondary;
            borderColor = palette.buttonSecondaryBorder.withValues(alpha: 0.3);
            textColor = palette.textSecondary;
            child = Text(
              days[index],
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
                  color: isToday && status != DayStreakStatus.missed
                      ? flameColorForState()
                      : borderColor,
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Center(child: child),
            ),
            const SizedBox(height: 6),
            Text(
              days[index],
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

  Color flameColorForState() {
    return atRisk ? Colors.grey : Colors.deepOrange;
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
