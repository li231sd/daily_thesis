import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Displays an adaptive banner ad, collapsing to zero height until the ad
/// has actually loaded so there's no empty gap or layout jump.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && AdService.instance.isSupportedPlatform) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width) ??
        AdSize.banner;

    final ad = AdService.instance.createBannerAd(
      size: size,
      onLoaded: () {
        if (mounted) setState(() => _isLoaded = true);
      },
    );
    _bannerAd = ad;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!AdService.instance.isSupportedPlatform || ad == null || !_isLoaded) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
