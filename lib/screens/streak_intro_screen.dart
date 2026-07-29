import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/press_button.dart';
import '../widgets/reveal.dart';

/// Shown once, immediately after onboarding, to explain how streaks work
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
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Reveal(
                    delay: const Duration(milliseconds: 0),
                    child: _Eyebrow('BUILD THE HABIT'),
                  ),
                  const SizedBox(height: 16),
                  Reveal(
                    delay: const Duration(milliseconds: 80),
                    child: _Headline('Keep your\nstreak alive.'),
                  ),
                  const SizedBox(height: 12),
                  Reveal(
                    delay: const Duration(milliseconds: 140),
                    child: Text(
                      'A little reading, every day.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  Reveal(
                    delay: const Duration(milliseconds: 220),
                    child: _InfoRow(
                      icon: Icons.timer_outlined,
                      title: '1 Minute Daily Read',
                      description:
                          'Spend at least 1 minute in the app reading papers each day to maintain your streak.',
                      palette: palette,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Reveal(
                    delay: const Duration(milliseconds: 280),
                    child: _InfoRow(
                      icon: Icons.ac_unit_rounded,
                      iconColor: Colors.lightBlue.shade400,
                      title: 'Earn Ice Every Week',
                      description:
                          'Complete a 7-day streak to automatically earn 1 Streak Freeze.',
                      palette: palette,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Reveal(
                    delay: const Duration(milliseconds: 340),
                    child: _InfoRow(
                      icon: Icons.shield_outlined,
                      iconColor: Colors.amber.shade700,
                      title: 'Automatic Protection',
                      description:
                          'Miss a day and a freeze is consumed automatically to protect your streak.',
                      palette: palette,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Reveal(
                    delay: const Duration(milliseconds: 420),
                    child: _PrimaryButton(
                      label: 'Got It',
                      onPressed: onContinue,
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

// ─── Local presentation components (matches onboarding's editorial style) ──

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

class _Headline extends StatelessWidget {
  final String text;
  const _Headline(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppPalette.of(context).textPrimary,
          height: 1.2,
          letterSpacing: -0.6,
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String description;
  final AppPalette palette;

  const _InfoRow({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.description,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? palette.textPrimary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: iconColor ?? palette.textPrimary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return PressButton(
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: palette.buttonPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: palette.buttonPrimaryText,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
