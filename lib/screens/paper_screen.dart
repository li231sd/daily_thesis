import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/paper.dart';
import '../models/user_profile.dart';
import '../services/paper_history_storage.dart';
import '../services/paper_service.dart';
import '../services/profile_storage.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/reveal.dart';
import '../widgets/press_button.dart';
import '../widgets/citation_badge.dart';
import '../widgets/arxiv_disclaimer.dart';
import '../widgets/math_text.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class PaperScreen extends StatefulWidget {
  const PaperScreen({super.key});

  @override
  State<PaperScreen> createState() => _PaperScreenState();
}

class _PaperScreenState extends State<PaperScreen> with TickerProviderStateMixin {
  final _service = PaperService();
  final _profileStorage = ProfileStorage();
  final _historyStorage = PaperHistoryStorage();

  UserProfile? _profile;
  List<String>? selectedSubjects;
  Paper? _paper;
  bool isLoading = true;
  bool hasError = false;
  String errorTitle = '';
  String errorMessage = '';
  bool _contentVisible = false;

  late AnimationController _refreshCtrl;

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadProfileAndFetch();
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndFetch() async {
    final profile = await _profileStorage.load();
    setState(() {
      _profile = profile;
      selectedSubjects = profile?.matchedSubjects;
    });
    fetchDailyPaper();
  }

  Future<void> fetchDailyPaper() async {
    setState(() {
      isLoading = true;
      hasError = false;
      _contentVisible = false;
    });
    _refreshCtrl.repeat();

    try {
      final paper = await _service.fetchDailyPaper(matchedSubjects: selectedSubjects);
      await _historyStorage.saveDailyRecommendation(paper);
      setState(() {
        _paper = paper;
        isLoading = false;
      });
      _revealContent();
    } on Exception catch (e) {
      _setErrorState('Connection Error', e.toString());
    } finally {
      _refreshCtrl.stop();
      _refreshCtrl.animateTo(1.0, curve: Curves.easeOut);
    }
  }

  void _setErrorState(String title, String message) {
    setState(() {
      errorTitle = title;
      errorMessage = message;
      isLoading = false;
      hasError = true;
    });
    _revealContent();
  }

  void _revealContent() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _contentVisible = true);
    });
  }

  Future<void> _openPaperLink() async {
    final url = _paper?.url;
    if (url != null && url.isNotEmpty) {
      HapticFeedback.lightImpact();
      final uri = Uri.parse(url);
      final launchUri = uri.hasScheme ? uri : Uri.parse('https://$url');

      if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the publication link')),
        );
      }
    }
  }

  Future<void> _openSettings() async {
    if (_profile == null) return;
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          profile: _profile!,
          onSaved: _loadProfileAndFetch,
        ),
      ),
    );
  }

  Future<void> _openHistory() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  Future<void> _openActionsMenu() async {
    HapticFeedback.lightImpact();
    final palette = AppPalette.of(context);

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MenuAction(
                    icon: Icons.refresh_rounded,
                    label: 'Reload',
                    onTap: () => Navigator.of(context).pop('reload'),
                  ),
                  const SizedBox(height: 8),
                  _MenuAction(
                    icon: Icons.history_rounded,
                    label: 'History',
                    onTap: () => Navigator.of(context).pop('history'),
                  ),
                  const SizedBox(height: 8),
                  _MenuAction(
                    icon: Icons.tune_rounded,
                    label: 'Settings',
                    onTap: () => Navigator.of(context).pop('settings'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'reload':
        if (!isLoading) fetchDailyPaper();
        break;
      case 'history':
        await _openHistory();
        break;
      case 'settings':
        await _openSettings();
        break;
    }
  }

  Future<void> _copyCitation() async {
    final paper = _paper;
    if (paper == null || hasError) return;

    await Clipboard.setData(ClipboardData(text: paper.citation()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Citation copied to clipboard')),
    );
  }

  Future<void> _sharePaper() async {
    final paper = _paper;
    if (paper == null || hasError) return;

    final shareText = [
      paper.title,
      if (paper.authors.isNotEmpty) paper.authors,
      if (paper.journal.isNotEmpty)
        paper.publishYear != null ? '${paper.journal}, ${paper.publishYear}' : paper.journal,
      paper.url,
    ].where((line) => line.isNotEmpty).join('\n');

    final size = MediaQuery.sizeOf(context);
    final origin = Rect.fromLTWH(0, 0, size.width, size.height);

    await Share.share(
      shareText,
      subject: paper.title,
      sharePositionOrigin: origin,
    );
  }

  Future<void> _discussWithChatGPT() async {
    final paper = _paper;
    if (paper == null || hasError) return;
    HapticFeedback.lightImpact();

    // Keep the abstract short enough that the resulting URL stays well
    // under common browser/webview length limits (~2000 chars).
    const maxAbstractChars = 1200;
    var abstract = paper.abstract;
    if (abstract.length > maxAbstractChars) {
      abstract = '${abstract.substring(0, maxAbstractChars)}...';
    }

    final promptBuffer = StringBuffer()
      ..writeln('Can you explain this paper in plain language and walk me through its key contributions?')
      ..writeln()
      ..writeln('Title: ${paper.title}');
    if (paper.authors.isNotEmpty) {
      promptBuffer.writeln('Authors: ${paper.authors}');
    }
    promptBuffer
      ..writeln('Abstract: $abstract')
      ..write('Link: ${paper.url}');

    // chatgpt.com supports a `q` query param that pre-fills the message
    // box. It does NOT reliably auto-send (OpenAI added anti-abuse
    // protections around that after it was used for prompt-injection
    // link attacks), so this opens ChatGPT with the prompt ready to
    // review and send, not already sent.
    final uri = Uri.https('chatgpt.com', '/', {'q': promptBuffer.toString()});

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open ChatGPT')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: palette.textPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        title: Text(
          'DAILY THESIS',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            fontSize: 11,
            color: palette.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.menu_rounded, size: 24, color: palette.textPrimary), onPressed: _openActionsMenu),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620),
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('shimmer'),
                      width: double.infinity,
                      height: 500,
                      child: ShimmerLoader(),
                    )
                  : _contentVisible
                      ? _buildContent()
                      : const SizedBox(key: ValueKey('blank'), height: 500),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final paper = _paper;
    final palette = AppPalette.of(context);

    return Column(
      key: const ValueKey('content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Eyebrow ──────────────────────────────────────────────────────
        Reveal(
          child: Text(
            hasError
                ? 'NOTICE'
                : (_profile != null && _profile!.name.isNotEmpty
                    ? "FOR ${_profile!.name.toUpperCase()}"
                    : "TODAY'S INSIGHT"),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: hasError ? palette.danger : palette.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Title (LaTeX-aware, no WebView) ───────────────────────────────
        Reveal(
          delay: const Duration(milliseconds: 60),
          child: MathText(
            hasError ? errorTitle : (paper?.title ?? ''),
            style: TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: palette.textPrimary,
            ),
          ),
        ),

        // ── Authors ───────────────────────────────────────────────────────
        if (!hasError && paper != null && paper.authors.isNotEmpty) ...[
          const SizedBox(height: 20),
          Reveal(
            delay: const Duration(milliseconds: 120),
            child: Text(
              paper.authors,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],

        // ── Journal ───────────────────────────────────────────────────────
        if (!hasError && paper != null && paper.journal.isNotEmpty) ...[
          const SizedBox(height: 12),
          Reveal(
            delay: const Duration(milliseconds: 180),
            child: Text(
              paper.publishYear != null
                  ? '${paper.journal}, ${paper.publishYear}'
                  : paper.journal,
              style: TextStyle(fontSize: 13, color: palette.textTertiary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        // ── Citations ─────────────────────────────────────────────────────
        if (!hasError && paper != null && paper.citationCount != null) ...[
          const SizedBox(height: 8),
          Reveal(
            delay: const Duration(milliseconds: 180),
            child: CitationBadge(paper.citationCount!),
          ),
        ],

        // ── Divider ───────────────────────────────────────────────────────
        Reveal(
          delay: const Duration(milliseconds: 240),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28.0),
            child: Divider(
              height: 1,
              thickness: 0.75,
              color: palette.borderSoft,
            ),
          ),
        ),

        // ── Abstract (LaTeX-aware, no WebView) ─────────────────────────────
        Reveal(
          delay: const Duration(milliseconds: 300),
          child: MathText(
            hasError ? errorMessage : (paper?.abstract ?? ''),
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              height: 1.65,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        // ── arXiv disclaimer ─────────────────────────────────────────────
        if (!hasError && paper != null && paper.isArxiv) ...[
          const SizedBox(height: 24),
          Reveal(
            delay: const Duration(milliseconds: 330),
            child: const ArxivDisclaimer(),
          ),
        ],

        const SizedBox(height: 48),

        // ── CTA Button ────────────────────────────────────────────────────
        if (!hasError && paper != null && paper.url.isNotEmpty)
          Reveal(
            delay: const Duration(milliseconds: 360),
            child: PressButton(
              onPressed: _openPaperLink,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: palette.buttonPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Read Full Publication',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.buttonPrimaryText,
                        letterSpacing: 0.3,
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

        // ── Error retry ───────────────────────────────────────────────────
        if (hasError)
          Reveal(
            delay: const Duration(milliseconds: 200),
            child: PressButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                fetchDailyPaper();
              },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: palette.textPrimary, width: 1.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (!hasError && paper != null) ...[
          const SizedBox(height: 24),
          Reveal(
            delay: const Duration(milliseconds: 330),
            child: Row(
              children: [
                Expanded(
                  child: PressButton(
                    onPressed: _copyCitation,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: palette.buttonSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.buttonSecondaryBorder),
                      ),
                      child: Center(
                        child: Text(
                          'Cite',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: palette.buttonSecondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PressButton(
                    onPressed: _sharePaper,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: palette.buttonSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.buttonSecondaryBorder),
                      ),
                      child: Center(
                        child: Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: palette.buttonSecondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Reveal(
            delay: const Duration(milliseconds: 360),
            child: PressButton(
              onPressed: _discussWithChatGPT,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.buttonSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.buttonSecondaryBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 16, color: palette.buttonSecondaryText),
                    const SizedBox(width: 8),
                    Text(
                      'Discuss with ChatGPT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.buttonSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 40),
      ],
    );
  }
}

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.buttonSecondary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: palette.buttonSecondaryText),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: palette.buttonSecondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
