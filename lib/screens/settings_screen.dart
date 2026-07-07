import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/interest_matcher.dart';
import '../services/profile_storage.dart';
import '../services/theme_mode_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/interest_picker.dart';
import '../widgets/press_button.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onSaved;

  const SettingsScreen({super.key, required this.profile, required this.onSaved});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late Set<String> _selectedInterests;
  late ThemeMode _themeMode;
  final _storage = ProfileStorage();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _selectedInterests = widget.profile.interests.toSet();
    _themeMode = ThemeModeController.instance.notifier.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleInterest(String label) {
    setState(() {
      if (_selectedInterests.contains(label)) {
        _selectedInterests.remove(label);
      } else {
        _selectedInterests.add(label);
      }
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    setState(() => _themeMode = mode);
    await ThemeModeController.instance.setMode(mode);
  }

  Future<void> _save() async {
    if (_selectedInterests.isEmpty) return;

    final interests = _selectedInterests.toList();
    final matchedSubjects = InterestMatcher.subjectsForSelections(interests);

    final updated = UserProfile(
      name: _nameController.text.trim(),
      interests: interests,
      matchedSubjects: matchedSubjects,
    );

    await _storage.save(updated);
    HapticFeedback.lightImpact(); // Cleaner tactical snap for premium apps
    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final canSave = _selectedInterests.isNotEmpty && _nameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: palette.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'SETTINGS',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            fontSize: 11,
            color: palette.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          // Premium editorial pattern: Save button is elegantly integrated into the header bar
          TextButton(
            onPressed: canSave ? _save : null,
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: canSave ? palette.textPrimary : palette.textTertiary.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- NAME SECTION ---
                    Text(
                      "NAME",
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.textTertiary, letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(fontSize: 18, color: palette.textPrimary, letterSpacing: -0.2),
                      onChanged: (_) => setState(() {}), // Keeps save state validation real-time
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: UnderlineInputBorder(borderSide: BorderSide(color: palette.border)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: palette.border)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: palette.textPrimary)),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // --- APPEARANCE SECTION ---
                    Text(
                      'APPEARANCE',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.textTertiary, letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 16),
                    Row( // Row layout offers cleaner visual rhythm than Wrap for 3 standard options
                      children: [
                        Expanded(
                          child: _ThemeChoice(
                            label: 'System',
                            selected: _themeMode == ThemeMode.system,
                            onTap: () => _setThemeMode(ThemeMode.system),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ThemeChoice(
                            label: 'Light',
                            selected: _themeMode == ThemeMode.light,
                            onTap: () => _setThemeMode(ThemeMode.light),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ThemeChoice(
                            label: 'Dark',
                            selected: _themeMode == ThemeMode.dark,
                            onTap: () => _setThemeMode(ThemeMode.dark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // --- INTERESTS SECTION TITLE ---
                    Text(
                      "INTERESTS",
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.textTertiary, letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // --- INTERESTS PICKER SCROLL ZONE ---
            SliverFillRemaining(
              hasScrollBody: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                      stops: const [0.0, 0.04, 0.92, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: InterestPicker(
                      selectedLabels: _selectedInterests,
                      onToggle: _toggleInterest,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Refined Premium Segment Chips ──────────────────────────────────────────

class _ThemeChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return PressButton( // Integrated PressButton wrapper for fluid tactile response on change
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.textPrimary : Colors.transparent, // Solid minimalism change
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? palette.textPrimary : palette.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? palette.background : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
