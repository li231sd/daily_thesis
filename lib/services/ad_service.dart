// import 'dart:io' show Platform;

// import 'package:flutter/foundation.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// // import 'package:google_mobile_ads/google_mobile_ads.dart';

// /// Centralizes AdMob setup, ad unit ID lookup, and interstitial frequency
// /// capping so screens don't need to know about ad plumbing directly.
// class AdService {
//   AdService._();

//   static final AdService instance = AdService._();

//   static const int _fetchesBetweenInterstitials = 3;

//   InterstitialAd? _interstitialAd;
//   bool _isLoadingInterstitial = false;
//   int _fetchCountSinceLastInterstitial = 0;

//   // TEMPORARY: flip to true to re-enable ads. While this is false, every
//   // ad code path (banner, interstitial, initialization) no-ops, since they
//   // all already gate on isSupportedPlatform below.
//   static const bool _adsEnabledForNow = false; // TODO: If needed

//   /// Ads only run on Android/iOS, and only while [_adsEnabledForNow] is true.
//   bool get isSupportedPlatform =>
//       _adsEnabledForNow && !kIsWeb && (Platform.isAndroid || Platform.isIOS);

//   String get bannerAdUnitId =>
//       dotenv.env['PaperScreen_Banner'] ?? _testBannerId;

//   String get _interstitialAdUnitId =>
//       dotenv.env['PaperScreen_Interstitial'] ?? _testInterstitialId;

//   // Google's official test ad unit IDs. Safe fallbacks if .env is missing
//   // a value, so a bad config never accidentally serves real ad requests.
//   static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
//   static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

//   Future<void> initialize() async {
//     if (!isSupportedPlatform) return;
//     await MobileAds.instance.initialize();
//     _loadInterstitial();
//   }

//   BannerAd createBannerAd({required AdSize size, required VoidCallback onLoaded}) {
//     return BannerAd(
//       adUnitId: bannerAdUnitId,
//       size: size,
//       request: const AdRequest(),
//       listener: BannerAdListener(
//         onAdLoaded: (_) => onLoaded(),
//         onAdFailedToLoad: (ad, error) {
//           debugPrint('Banner ad failed to load: $error');
//           ad.dispose();
//         },
//       ),
//     )..load();
//   }

//   void _loadInterstitial() {
//     if (!isSupportedPlatform || _isLoadingInterstitial || _interstitialAd != null) {
//       return;
//     }
//     _isLoadingInterstitial = true;
//     InterstitialAd.load(
//       adUnitId: _interstitialAdUnitId,
//       request: const AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (ad) {
//           _interstitialAd = ad;
//           _isLoadingInterstitial = false;
//         },
//         onAdFailedToLoad: (error) {
//           debugPrint('Interstitial ad failed to load: $error');
//           _isLoadingInterstitial = false;
//         },
//       ),
//     );
//   }

//   /// Call this each time the "daily paper" is fetched. Shows an interstitial
//   /// every [_fetchesBetweenInterstitials] fetches instead of every single
//   /// one, to avoid hurting retention with too-frequent full-screen ads.
//   void maybeShowInterstitial() {
//     if (!isSupportedPlatform) return;

//     _fetchCountSinceLastInterstitial++;
//     if (_fetchCountSinceLastInterstitial < _fetchesBetweenInterstitials) return;

//     final ad = _interstitialAd;
//     if (ad == null) {
//       // Wasn't ready in time; keep waiting for the next opportunity rather
//       // than blocking the user.
//       _loadInterstitial();
//       return;
//     }

//     _fetchCountSinceLastInterstitial = 0;
//     ad.fullScreenContentCallback = FullScreenContentCallback(
//       onAdDismissedFullScreenContent: (ad) {
//         ad.dispose();
//         _interstitialAd = null;
//         _loadInterstitial();
//       },
//       onAdFailedToShowFullScreenContent: (ad, error) {
//         debugPrint('Interstitial ad failed to show: $error');
//         ad.dispose();
//         _interstitialAd = null;
//         _loadInterstitial();
//       },
//     );
//     ad.show();
//   }
// }


import 'package:flutter/foundation.dart';

/// Centralizes AdMob setup, ad unit ID lookup, and interstitial frequency
/// capping so screens don't need to know about ad plumbing directly.
///
/// TEMPORARILY STUBBED: google_mobile_ads is removed from pubspec.yaml
/// because its native init (WorkManager/Room) was crashing the app on
/// launch. All methods are no-ops until the package is re-added and the
/// crash is resolved. See git history for the original implementation.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  /// Ads are fully disabled while google_mobile_ads is removed.
  bool get isSupportedPlatform => false;

  Future<void> initialize() async {
    // No-op: google_mobile_ads is not currently a dependency.
  }

  /// Returns null while ads are disabled. Callers must handle null.
  Object? createBannerAd({
    required double width,
    required double height,
    required VoidCallback onLoaded,
  }) {
    return null;
  }

  void maybeShowInterstitial() {
    // No-op: google_mobile_ads is not currently a dependency.
  }
}
