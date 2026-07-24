import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/paper.dart';
import '../models/user_profile.dart';
import '../services/dismissed_papers_storage.dart';
import '../services/feedback_storage.dart';
import '../services/interest_matcher.dart';
import '../services/liked_papers_storage.dart';
import '../services/paper_buffer_storage.dart';
import '../services/paper_history_storage.dart';
import '../services/paper_service.dart';
import '../services/profile_storage.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/reveal.dart';
import '../widgets/press_button.dart';
import '../widgets/citation_badge.dart';
import '../widgets/preprint_disclaimer.dart';
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
  final _feedbackStorage = FeedbackStorage();
  final _likedStorage = LikedPapersStorage();
  final _dismissedStorage = DismissedPapersStorage();
  final _bufferStorage = PaperBufferStorage();

  UserProfile? _profile;
  List<String>? selectedSubjects;
  Paper? _paper;
  bool isLoading = true;
  bool hasError = false;
  String errorTitle = '';
  String errorMessage = '';

  // True when the paper currently on screen was served from the offline
  // buffer rather than a live fetch (either because the device had no
  // connection, or because the live fetch failed).
  bool _isOffline = false;

  Map<String, int> _dislikeCounts = {};
  String? _currentSubject;
  int _subjectRotationIndex = 0;
  int _attempt = 0;
  final Set<String> _shownUrlsToday = {};

  Set<String> _likedUrls = {};
  bool get _isCurrentLiked => _paper != null && _likedUrls.contains(_paper!.url);

  late AnimationController _refreshCtrl;

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadProfileAndFetch();
    _loadLikedUrls();
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLikedUrls() async {
    final urls = await _likedStorage.load();
    if (mounted) setState(() => _likedUrls = urls);
  }

  Future<void> _loadProfileAndFetch() async {
    final profile = await _profileStorage.load();
    setState(() {
      _profile = profile;
      selectedSubjects = profile?.matchedSubjects;
    });
    fetchDailyPaper();
  }

  /// True if the device currently has some form of network connection.
  /// This is a quick local check (not a real reachability probe), so it's
  /// used to skip straight to the offline buffer instead of waiting out a
  /// 20-second timeout — the actual fetch call is still the source of
  /// truth if this check is wrong (e.g. captive portal Wi-Fi).
  Future<bool> _hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Builds the set of URLs we should never re-serve: everything already
  /// viewed (history), everything explicitly marked "not for me"
  /// (persisted, so this survives app restarts — not just this session),
  /// plus everything shown earlier this session.
  Future<Set<String>> _excludedUrls() async {
    final history = await _historyStorage.load();
    final dismissed = await _dismissedStorage.load();
    return {
      ..._shownUrlsToday,
      ...dismissed,
      ...history.map((e) => e.paper.url),
    };
  }

  /// Tops up the offline buffer while we have a connection. Fire-and-forget
  /// — never blocks the UI and any failure here is silently ignored, since
  /// the buffer is a nice-to-have, not the primary path.
  Future<void> _refillBuffer() async {
    try {
      if (await _bufferStorage.count() >= PaperBufferStorage.targetSize) return;

      final excludeUrls = await _excludedUrls();
      final subjects = (selectedSubjects == null || selectedSubjects!.isEmpty)
          ? const ['all']
          : selectedSubjects!;

      for (final subject in subjects) {
        if (await _bufferStorage.count() >= PaperBufferStorage.targetSize) break;
        final candidates = await _service.fetchCandidates(
          subject: subject,
          excludeUrls: excludeUrls,
        );
        await _bufferStorage.addIfRoom(candidates, excludeUrls: excludeUrls);
      }
    } catch (_) {
      // Buffer refill is best-effort; a failure here shouldn't surface to
      // the user or interrupt whatever they're doing.
    }
  }

  /// Serves the next queued paper as a fallback when a live fetch isn't
  /// possible. Returns true if a buffered paper was shown.
  Future<bool> _tryServeFromBuffer() async {
    final buffered = await _bufferStorage.popNext();
    if (buffered == null) return false;

    await _historyStorage.saveDailyRecommendation(buffered);
    if (!mounted) return true;
    setState(() {
      _paper = buffered;
      _isOffline = true;
      isLoading = false;
    });
    return true;
  }

  Future<void> fetchDailyPaper() async {
    setState(() {
      isLoading = true;
      hasError = false;
      _isOffline = false;
    });
    _refreshCtrl.repeat();

    _shownUrlsToday.clear();
    _attempt = 0;
    _subjectRotationIndex = 0;

    try {
      _dislikeCounts = await _feedbackStorage.loadDislikeCounts();
      final subjects = selectedSubjects ?? const [];
      _currentSubject = subjects.isEmpty
          ? null
          : InterestMatcher.subjectForToday(subjects, dislikeCounts: _dislikeCounts);

      if (!await _hasConnection()) {
        if (await _tryServeFromBuffer()) return;
        throw Exception(
          "You're offline and don't have any saved papers yet. Connect once to build up a queue.",
        );
      }

      final excludeUrls = await _excludedUrls();
      final paper = await _service.fetchDailyPaper(
        matchedSubjects: selectedSubjects,
        dislikeCounts: _dislikeCounts,
        excludeUrls: excludeUrls,
      );
      await _historyStorage.saveDailyRecommendation(paper);
      setState(() {
        _paper = paper;
        isLoading = false;
      });
      unawaited(_refillBuffer());
    } on Exception catch (e) {
      if (await _tryServeFromBuffer()) return;
      _setErrorState('Connection Error', e.toString());
    } finally {
      _refreshCtrl.stop();
      _refreshCtrl.animateTo(1.0, curve: Curves.easeOut);
    }
  }

  Future<void> _notForMe() async {
    if (_paper == null || hasError || isLoading) return;
    HapticFeedback.lightImpact();

    final dismissedPaper = _paper!;

    if (_currentSubject != null) {
      await _feedbackStorage.recordNotForMe(_currentSubject!);
      _dislikeCounts[_currentSubject!] = (_dislikeCounts[_currentSubject!] ?? 0) + 1;
    }

    // Persist the dismissal so this specific paper is excluded going
    // forward — including after the app is closed and reopened, not just
    // for the rest of this session.
    await _dismissedStorage.add(dismissedPaper.url);
    await _historyStorage.updateStatus(dismissedPaper.url, PaperFeedbackStatus.disliked);

    await _getAnotherPaper();
  }

  Future<void> _getAnotherPaper() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    _refreshCtrl.repeat();

    try {
      if (_paper != null) _shownUrlsToday.add(_paper!.url);

      final subjects = selectedSubjects ?? const [];
      String nextSubject;
      if (subjects.length > 1) {
        _subjectRotationIndex = (_subjectRotationIndex + 1) % subjects.length;
        nextSubject = subjects[_subjectRotationIndex];
      } else {
        nextSubject = _currentSubject ?? 'all';
      }

      if (!await _hasConnection()) {
        if (await _tryServeFromBuffer()) return;
        throw Exception(
          "You're offline and don't have any saved papers yet. Connect once to build up a queue.",
        );
      }

      final excludeUrls = await _excludedUrls();
      final newPaper = await _service.fetchAnotherPaper(
        subject: nextSubject,
        attempt: _attempt++,
        excludeUrls: excludeUrls,
      );

      await _historyStorage.saveDailyRecommendation(newPaper);
      setState(() {
        _paper = newPaper;
        _currentSubject = nextSubject;
        isLoading = false;
        _isOffline = false;
      });
      unawaited(_refillBuffer());
    } on Exception catch (e) {
      if (await _tryServeFromBuffer()) return;
      _setErrorState('Connection Error', e.toString());
    } finally {
      _refreshCtrl.stop();
      _refreshCtrl.animateTo(1.0, curve: Curves.easeOut);
    }
  }

  Future<void> _toggleLike() async {
    final paper = _paper;
    if (paper == null || hasError) return;
    HapticFeedback.mediumImpact();

    final liked = !_likedUrls.contains(paper.url);
    setState(() {
      if (liked) {
        _likedUrls.add(paper.url);
      } else {
        _likedUrls.remove(paper.url);
      }
    });
    await _likedStorage.setLiked(paper.url, liked);
    await _historyStorage.updateStatus(
      paper.url,
      liked ? PaperFeedbackStatus.liked : PaperFeedbackStatus.none,
    );
  }

  void _setErrorState(String title, String message) {
    setState(() {
      errorTitle = title;
      errorMessage = message;
      isLoading = false;
      hasError = true;
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
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MenuAction(
                    icon: Icons.refresh_rounded,
                    label: 'Reload Recommendation',
                    onTap: () => Navigator.of(context).pop('reload'),
                  ),
                  const SizedBox(height: 8),
                  _MenuAction(
                    icon: Icons.history_rounded,
                    label: 'Reading History',
                    onTap: () => Navigator.of(context).pop('history'),
                  ),
                  const SizedBox(height: 8),
                  _MenuAction(
                    icon: Icons.tune_rounded,
                    label: 'Preferences & Feeds',
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
          IconButton(
            icon: Icon(Icons.menu_rounded, size: 24, color: palette.textPrimary),
            onPressed: _openActionsMenu,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('shimmer'),
                      width: double.infinity,
                      height: 500,
                      child: ShimmerLoader(),
                    )
                  : _buildContent(),
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

        // ── Offline badge ───────────────────────────────────────────────
        if (!hasError && _isOffline) ...[
          const SizedBox(height: 8),
          Reveal(
            delay: const Duration(milliseconds: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 13, color: palette.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'OFFLINE · FROM YOUR SAVED QUEUE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // ── Title ────────────────────────────────────────────────────────
        Reveal(
          delay: const Duration(milliseconds: 40),
          child: MathText(
            hasError ? errorTitle : (paper?.title ?? ''),
            style: TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
              fontSize: 26,
              height: 1.25,
              color: palette.textPrimary,
            ),
          ),
        ),

        // ── Authors ───────────────────────────────────────────────────────
        if (!hasError && paper != null && paper.authors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Reveal(
            delay: const Duration(milliseconds: 80),
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
          const SizedBox(height: 8),
          Reveal(
            delay: const Duration(milliseconds: 120),
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
            delay: const Duration(milliseconds: 140),
            child: CitationBadge(paper.citationCount!),
          ),
        ],

        // ── Divider ───────────────────────────────────────────────────────
        Reveal(
          delay: const Duration(milliseconds: 160),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(
              height: 1,
              thickness: 0.75,
              color: palette.borderSoft,
            ),
          ),
        ),

        // ── Abstract ─────────────────────────────────────────────────────
        Reveal(
          delay: const Duration(milliseconds: 200),
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

        // ── Preprint disclaimer ──────────────────────────────────────────
        if (!hasError && paper != null && paper.isPreprint) ...[
          const SizedBox(height: 20),
          Reveal(
            delay: const Duration(milliseconds: 220),
            child: PreprintDisclaimer(sourceName: paper.sourceDisplayName),
          ),
        ],

        const SizedBox(height: 40),

        // ── Primary Action Panel (Ergonomic layout) ────────────────────────
        if (!hasError && paper != null) ...[
          if (paper.url.isNotEmpty)
            Reveal(
              delay: const Duration(milliseconds: 240),
              child: PressButton(
                onPressed: _openPaperLink,
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
          const SizedBox(height: 12),

          // Discovery Feedback Controls (Like / Skip)
          Reveal(
            delay: const Duration(milliseconds: 260),
            child: Row(
              children: [
                Expanded(
                  child: PressButton(
                    onPressed: _toggleLike,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isCurrentLiked ? palette.textPrimary.withValues(alpha: 0.08) : palette.buttonSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isCurrentLiked ? palette.textPrimary : palette.buttonSecondaryBorder,
                          width: _isCurrentLiked ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isCurrentLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                            size: 16,
                            color: _isCurrentLiked ? palette.textPrimary : palette.buttonSecondaryText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Like',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isCurrentLiked ? palette.textPrimary : palette.buttonSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PressButton(
                    onPressed: _notForMe,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: palette.buttonSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.buttonSecondaryBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.thumb_down_outlined, size: 16, color: palette.buttonSecondaryText),
                          const SizedBox(width: 6),
                          Text(
                            'Skip Paper',
                            style: TextStyle(
                              fontSize: 13,
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
            ),
          ),

          // Document Secondary Action Row (Cite, Share, Discuss)
          const SizedBox(height: 12),
          Reveal(
            delay: const Duration(milliseconds: 280),
            child: Row(
              children: [
                _buildUtilityButton(
                  icon: Icons.format_quote_rounded,
                  label: 'Cite',
                  onPressed: _copyCitation,
                  palette: palette,
                ),
                const SizedBox(width: 8),
                _buildUtilityButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  onPressed: _sharePaper,
                  palette: palette,
                ),
                const SizedBox(width: 8),
                _buildUtilityButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Discuss',
                  onPressed: _discussWithChatGPT,
                  palette: palette,
                ),
              ],
            ),
          ),
        ],

        // ── Error retry ───────────────────────────────────────────────────
        if (hasError)
          Reveal(
            delay: const Duration(milliseconds: 100),
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
                  borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildUtilityButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required AppPalette palette,
  }) {
    return Expanded(
      child: PressButton(
        onPressed: onPressed,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: palette.buttonSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.buttonSecondaryBorder.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: palette.buttonSecondaryText),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: palette.buttonSecondaryText),
              const SizedBox(width: 12),
              Text(
                label,
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
    );
  }
}
