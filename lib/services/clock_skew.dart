import 'dart:io';
import 'package:http/http.dart' as http;

/// Thrown when a network request fails at the TLS layer in a way that's
/// consistent with the device's system clock being wrong (rather than a
/// genuine connectivity problem). Callers should catch this separately
/// from generic network Exceptions so the user gets an actionable message
/// instead of a raw "handshake failed" error.
class ClockSkewException implements Exception {
  final String message;
  const ClockSkewException([
    this.message =
        'Your device date & time appear to be set incorrectly, which is blocking secure connections.',
  ]);

  @override
  String toString() => message;
}

class ClockSkewDetector {
  /// Compares device time against a remote Date header to check for gross
  /// clock skew (the kind that breaks TLS certificate validity checks —
  /// a few minutes off never does, so we only flag large drift).
  ///
  /// Deliberately probes over plain HTTP, not HTTPS. An HTTPS probe goes
  /// through the same certificate date validation that's potentially
  /// broken, so if the clock actually is the cause, an HTTPS check would
  /// just fail identically and prove nothing. Plain HTTP has no cert to
  /// validate, so it succeeds regardless of clock state and gives us a
  /// server-supplied time to compare against.
  static Future<bool> isClockLikelySkewed() async {
    try {
      final response = await http
          .head(Uri.parse('http://www.google.com'))
          .timeout(const Duration(seconds: 5));

      final serverDateHeader = response.headers['date'];
      if (serverDateHeader == null) return false;

      final serverTime = HttpDate.parse(serverDateHeader);
      final deviceTime = DateTime.now().toUtc();
      final drift = deviceTime.difference(serverTime).abs();

      // Generous threshold — this only needs to catch skew large enough
      // to break TLS cert validity windows, not measure precise drift.
      return drift > const Duration(hours: 24);
    } catch (_) {
      // Couldn't reach anything at all, even over plain HTTP — that's a
      // genuine connectivity problem, not something we can pin on the
      // clock, so don't misattribute it.
      return false;
    }
  }
}
