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
    HapticFeedback.mediumImpact();
    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final canSave = _selectedInterests.isNotEmpty;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SETTINGS',
          style: TextStyle(
            fontFamily: '-apple-system',
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            fontSize: 13,
            color: palette.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- NAME SECTION ---
              Text(
                "NAME",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textTertiary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: TextStyle(fontSize: 17, color: palette.textPrimary),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: palette.border)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: palette.border)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: palette.textPrimary)),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'APPEARANCE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textTertiary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ThemeChoice(
                    label: 'System',
                    selected: _themeMode == ThemeMode.system,
                    onTap: () => _setThemeMode(ThemeMode.system),
                  ),
                  _ThemeChoice(
                    label: 'Light',
                    selected: _themeMode == ThemeMode.light,
                    onTap: () => _setThemeMode(ThemeMode.light),
                  ),
                  _ThemeChoice(
                    label: 'Dark',
                    selected: _themeMode == ThemeMode.dark,
                    onTap: () => _setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              
              // --- INTERESTS SECTION ---
              Text(
                "INTERESTS",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.textTertiary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: InterestPicker(
                    selectedLabels: _selectedInterests,
                    onToggle: _toggleInterest,
                  ),
                ),
              ),
              
              // --- BUTTON SECTION ---
              const SizedBox(height: 24),
              PressButton(
                onPressed: canSave ? _save : () {},
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: canSave
                        ? palette.buttonPrimary
                        : palette.buttonPrimary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "Save Changes",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.buttonPrimaryText),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? palette.chipSelectedBackground : palette.chipUnselectedBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? palette.chipSelectedBorder : palette.chipUnselectedBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? palette.chipSelectedText : palette.chipUnselectedText,
          ),
        ),
      ),
    );
  }
}
