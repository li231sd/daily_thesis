import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/press_button.dart';
import '../widgets/reveal.dart';

/// Shown once, immediately after onboarding, to introduce streak tracking
/// before the user lands on the main paper feed.
class StreakIntroScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const StreakIntroScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(),

                  // ── Eyebrow & Editorial Headline ─────────────────────────
                  Reveal(
                    delay: const Duration(milliseconds: 0),
                    child: _Eyebrow('DAILY THESIS'),
                  ),
                  const SizedBox(height: 12),
                  Reveal(
                    delay: const Duration(milliseconds: 80),
                    child: Text(
                      'Build a habit of\neveryday reading.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Reveal(
                    delay: const Duration(milliseconds: 140),
                    child: Text(
                      'Read for at least 1 full minute each day to grow your streak and unlock weekly freeze protection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Visual Habit Hero Card ────────────────────────────────
                  Reveal(
                    delay: const Duration(milliseconds: 220),
                    child: _HabitHeroCard(palette: palette),
                  ),

                  const Spacer(),

                  // ── Main Action CTA ───────────────────────────────────────
                  Reveal(
                    delay: const Duration(milliseconds: 320),
                    child: PressButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onContinue();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: palette.buttonPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Start Reading Today',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: palette.buttonPrimaryText,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: palette.buttonPrimaryText.withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Visual Hero Card ───────────────────────────────────────────────────────

class _HabitHeroCard extends StatelessWidget {
  final AppPalette palette;

  const _HabitHeroCard({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.deepOrange,
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                '1 Day Streak',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Visual 7-day pill bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDayPill('M', isCompleted: true),
              _buildDayPill('T', isCurrent: true),
              _buildDayPill('W'),
              _buildDayPill('T'),
              _buildDayPill('F'),
              _buildDayPill('S'),
              _buildDayPill('S', isReward: true),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 15,
                color: palette.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '1 min/day • 7 days unlocks 1 Streak Freeze',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayPill(
    String day, {
    bool isCompleted = false,
    bool isCurrent = false,
    bool isReward = false,
  }) {
    Color bg = palette.buttonSecondary;
    Color border = palette.buttonSecondaryBorder.withValues(alpha: 0.4);
    Widget content = Text(
      day,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: palette.textSecondary,
      ),
    );

    if (isCompleted) {
      bg = palette.textPrimary.withValues(alpha: 0.1);
      border = palette.textPrimary.withValues(alpha: 0.2);
      content = Icon(Icons.check_rounded, size: 14, color: palette.textPrimary);
    } else if (isCurrent) {
      bg = Colors.deepOrange;
      border = Colors.deepOrange;
      content = const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.white);
    } else if (isReward) {
      bg = Colors.lightBlue.shade50.withValues(alpha: 0.5);
      border = Colors.lightBlue.shade200;
      content = Icon(Icons.ac_unit_rounded, size: 13, color: Colors.lightBlue.shade400);
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          child: Center(child: content),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? palette.textPrimary : palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppPalette.of(context).textTertiary,
          letterSpacing: 2.5,
        ),
      );
}
