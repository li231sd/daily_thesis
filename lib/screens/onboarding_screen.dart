import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/interest_matcher.dart';
import '../services/profile_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/interest_picker.dart';
import '../widgets/press_button.dart';
import 'streak_intro_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { name, confirm, interests, done }

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  _Step _step = _Step.name;
  final _nameController = TextEditingController();
  final Set<String> _selectedInterests = {};
  final _storage = ProfileStorage();

  late AnimationController _fadeCtrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  late AnimationController _checkCtrl;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.03), // Slightly reduced for a premium, subtle glide
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fadeCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  Future<void> _transitionTo(_Step next) async {
    await _fadeCtrl.reverse();
    if (!mounted) return;

    if (next != _Step.confirm) _checkCtrl.reset();

    setState(() => _step = next);

    if (next == _Step.confirm) {
      _fadeCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _checkCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) _transitionTo(_Step.interests);
      return;
    }

    _fadeCtrl.forward();
  }

  void _onNameNext() {
    if (_nameController.text.trim().isEmpty) return;
    _transitionTo(_Step.confirm);
  }

  void _toggleInterest(String label) {
    setState(() {
      _selectedInterests.contains(label)
          ? _selectedInterests.remove(label)
          : _selectedInterests.add(label);
    });
  }

  Future<void> _finish() async {
    if (_selectedInterests.isEmpty) return;
    await _fadeCtrl.reverse();
    if (!mounted) return;

    final interests = _selectedInterests.toList();
    final matchedSubjects = InterestMatcher.subjectsForSelections(interests);

    await _storage.save(UserProfile(
      name: _nameController.text.trim(),
      interests: interests,
      matchedSubjects: matchedSubjects,
    ));

    if (!mounted) return;

    // Dedicated full-screen streak explainer, shown before the final
    // onboarding completion state and before the main paper feed.
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => StreakIntroScreen(
          onContinue: () => Navigator.of(context).pop(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final isPopping = animation.status == AnimationStatus.reverse;

          // When entering (push): starts off-screen RIGHT and slides LEFT to center (0,0)
          // When exiting (pop): slides from center (0,0) off-screen LEFT
          final begin = isPopping ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (!mounted) return;
    setState(() => _step = _Step.done);
    await _fadeCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    widget.onComplete();
  }

  Widget _envelope({required Widget child}) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: child,
      ),
    );
  }

  // ─── Step: enter name ─────────────────────────────────────────────────────

  Widget _nameStep() => _envelope(
        child: Column(
          key: const ValueKey('name'),
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Eyebrow('WELCOME'),
            const SizedBox(height: 16),
            _Headline('What should\nwe call you?'),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: TextStyle(
                fontSize: 22,
                color: AppPalette.of(context).textPrimary,
                letterSpacing: -0.3,
              ),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: TextStyle(
                  fontSize: 22,
                  color: AppPalette.of(context).textTertiary,
                  letterSpacing: -0.3,
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppPalette.of(context).border, width: 1),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppPalette.of(context).textPrimary, width: 1),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppPalette.of(context).border, width: 1),
                ),
              ),
              onSubmitted: (_) => _onNameNext(),
            ),
            const SizedBox(height: 48),
            _PrimaryButton(label: 'Continue', onPressed: _onNameNext),
          ],
        ),
      );

  // ─── Step: name confirmed ─────────────────────────────────────────────────

  Widget _confirmStep() => _envelope(
        child: Column(
          key: const ValueKey('confirm'),
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _checkCtrl,
              builder: (context, _) => CustomPaint(
                size: const Size(64, 64),
                painter: _CheckPainter(_checkCtrl.value, AppPalette.of(context).textPrimary),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Nice to meet you,\n${_nameController.text.trim()}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppPalette.of(context).textPrimary,
                height: 1.4,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      );

  // ─── Step: pick interests (Optimized Layout) ──────────────────────────────

  Widget _interestsStep() => _envelope(
        child: Column(
          key: const ValueKey('interests'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40), // Pushes content down elegantly from SafeArea
            _Eyebrow('PERSONALIZE'),
            const SizedBox(height: 16),
            _Headline('What do you\nlike to read about?'),
            const SizedBox(height: 12),
            Text(
              'Pick as many as you like.',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppPalette.of(context).textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Scrollable area featuring an editorial shader-fade effect
            Expanded(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent
                    ],
                    stops: const [0.0, 0.04, 0.94, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 20), // Keeps chips from clipping near edges
                  child: InterestPicker(
                    selectedLabels: _selectedInterests,
                    onToggle: _toggleInterest,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _PrimaryButton(
              label: 'Get Started',
              onPressed: _selectedInterests.isEmpty ? null : _finish,
            ),
            const SizedBox(height: 24), // Extra bottom padding for clean UI anchoring
          ],
        ),
      );

  // ─── Step: done ───────────────────────────────────────────────────────────

  Widget _doneStep() => _envelope(
        child: Column(
          key: const ValueKey('done'),
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Eyebrow('ALL SET'),
            const SizedBox(height: 16),
            _Headline('Your daily\nthesis awaits.'),
          ],
        ),
      );

  // ─── Root ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    Widget body;
    switch (_step) {
      case _Step.name:
        body = _nameStep();
        break;
      case _Step.confirm:
        body = _confirmStep();
        break;
      case _Step.interests:
        body = _interestsStep();
        break;
      case _Step.done:
        body = _doneStep();
        break;
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440), // Snugger width yields premium editorial readability
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40), // Increased margins for enhanced luxury negative space
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared Premium Small Components ──────────────────────────────────────────

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
          letterSpacing: 2.5, // Generous track spacing matches premium design patterns
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
          fontSize: 32, // Marginally larger for stronger visual hierarchy
          fontWeight: FontWeight.w700,
          color: AppPalette.of(context).textPrimary,
          height: 1.2,
          letterSpacing: -0.6,
        ),
      );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final palette = AppPalette.of(context);
    return PressButton(
      onPressed: onPressed ?? () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: 54, // Added slight height to look structural and intentional
        decoration: BoxDecoration(
          color: disabled
              ? palette.buttonPrimary.withValues(alpha: 0.15)
              : palette.buttonPrimary,
          borderRadius: BorderRadius.circular(8), // Subtly softer curves
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: palette.buttonPrimaryText.withValues(alpha: disabled ? 0.35 : 1.0),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Checkmark painter ────────────────────────────────────────────────────────

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CheckPainter(this.progress, this.color);

  static const _circleFraction = 0.6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.25 // Slightly finer lines feel cleaner and premium
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final circleP = (progress / _circleFraction).clamp(0.0, 1.0);
    if (circleP > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708,
        6.28319 * circleP,
        false,
        paint,
      );
    }

    final checkP =
        ((progress - _circleFraction) / (1 - _circleFraction)).clamp(0.0, 1.0);
    if (checkP > 0) {
      final path = Path()
        ..moveTo(size.width * 0.32, size.height * 0.50)
        ..lineTo(size.width * 0.45, size.height * 0.62)
        ..lineTo(size.width * 0.68, size.height * 0.38);

      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * checkP),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress || old.color != color;
}
