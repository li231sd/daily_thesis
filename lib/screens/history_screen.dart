import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/paper_history_storage.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = PaperHistoryStorage();
  late Future<List<PaperHistoryEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _storage.load();
  }

  Future<void> _refresh() async {
    setState(() {
      _entriesFuture = _storage.load();
    });
  }

  Future<void> _openPaper(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        title: Text(
          'HISTORY',
          style: TextStyle(
            fontFamily: '-apple-system',
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            fontSize: 13,
            color: palette.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.refresh_rounded, size: 20, color: palette.textPrimary), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<PaperHistoryEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No history yet. Papers you open will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: palette.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: entries.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final paper = entry.paper;

              return Material(
                color: palette.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                shadowColor: palette.shadow,
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: paper.url.isEmpty ? null : () => _openPaper(paper.url),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paper.title,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: palette.textPrimary,
                          ),
                        ),
                        if (paper.authors.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            paper.authors,
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Recommended ${entry.viewedAt.toLocal().toString().split(' ').first}',
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
