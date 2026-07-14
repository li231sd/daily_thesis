import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralizes Firebase Analytics calls so screens don't need to know
/// about analytics plumbing directly. Mirrors the AdService pattern.
///
/// Retention, region, and session-length data all come for free from
/// Firebase once `logAppOpen`/screen views are wired in — no extra work
/// needed on our end for those, they show up in the Firebase console
/// under Engagement > Retention / Demographics.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;

  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      debugPrint('Analytics init failed: $e');
    }
  }

  /// Call once per cold start, right after initialize().
  void logAppOpen() {
    _analytics?.logAppOpen();
  }

  /// Call from each screen's initState (paper, history, settings, etc).
  void logScreenView(String screenName) {
    _analytics?.logScreenView(screenName: screenName);
  }

  /// Call when a user selects/updates subject interests in onboarding
  /// or settings. Useful for seeing which subjects are popular.
  void logInterestsSelected(List<String> matchedSubjects) {
    _analytics?.logEvent(
      name: 'interests_selected',
      parameters: {
        'subjects': matchedSubjects.join(','),
        'count': matchedSubjects.length,
      },
    );
  }

  /// Call from FeedbackStorage whenever a paper is liked/disliked/skipped.
  void logPaperFeedback({required String action, required String subject}) {
    _analytics?.logEvent(
      name: 'paper_feedback',
      parameters: {'action': action, 'subject': subject},
    );
  }

  /// Call whenever a paper is served from the offline prefetch buffer,
  /// so you can see how often the buffer is actually being used.
  void logOfflinePaperServed(String subject) {
    _analytics?.logEvent(
      name: 'offline_paper_served',
      parameters: {'subject': subject},
    );
  }

  /// Call from AdService when an ad is shown/clicked, once ads are
  /// re-enabled, to correlate ad activity with retention.
  void logAdEvent(String eventName) {
    _analytics?.logEvent(name: 'ad_$eventName');
  }
}
