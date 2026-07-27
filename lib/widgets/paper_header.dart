import 'package:flutter/material.dart';
import '../models/paper.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import 'citation_badge.dart';
import 'context_window.dart';
import 'math_text.dart';
import 'reveal.dart';

/// The header block shown above a paper's abstract: eyebrow line, offline
/// badge, title, the Context Window box, authors, journal, citation badge,
/// and the divider separating this section from the abstract.
///
/// Extracted from PaperScreen's _buildContent to keep that file focused on
/// screen-level layout/state rather than the visual details of any one
/// section.
class PaperHeader extends StatelessWidget {
  final bool hasError;
  final String errorTitle;
  final UserProfile? profile;
  final bool isOffline;
  final Paper? paper;

  const PaperHeader({
    super.key,
    required this.hasError,
    required this.errorTitle,
    required this.profile,
    required this.isOffline,
    required this.paper,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final paper = this.paper;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Eyebrow ──────────────────────────────────────────────────────
        Reveal(
          child: Text(
            hasError
                ? 'NOTICE'
                : (profile != null && profile!.name.isNotEmpty
                    ? "FOR ${profile!.name.toUpperCase()}"
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
        if (!hasError && isOffline) ...[
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
            delay: const Duration(milliseconds: 60),
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
            delay: const Duration(milliseconds: 80),
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
            delay: const Duration(milliseconds: 120),
            child: CitationBadge(paper.citationCount!),
          ),
        ],

        // ── Context Window ───────────────────────────────────────────────
        // Closed by default; the reader taps to expand and only then do we
        // fetch/generate the plain-language summary + key terms.
        if (!hasError && paper != null && paper.url.isNotEmpty) ...[
          const SizedBox(height: 16),
          Reveal(
            delay: const Duration(milliseconds: 140),
            child: ContextWindow(
              paperId: paper.url,
              title: paper.title,
              abstract: paper.abstract,
              field: profile?.interests.isNotEmpty == true
                  ? profile!.interests.first
                  : null,
            ),
          ),
        ],

        // ── Divider ───────────────────────────────────────────────────────
        Reveal(
          delay: const Duration(milliseconds: 160),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(
              height: 1,
              thickness: 1,
              color: palette.border,
            ),
          ),
        ),
      ],
    );
  }
}
