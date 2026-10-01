import 'package:flutter/widgets.dart';

/// A full-screen photo background (auth, splash, get-started, subscription).
///
/// Uses high-quality filtering so the dark, blurred art doesn't stair-step
/// when scaled to the screen. Ship 2x variants of these assets under
/// `assets/images/2.0x/` so phones downscale rather than upscale.
class AppBackdropImage extends StatelessWidget {
  const AppBackdropImage(this.asset, {super.key, this.fallbackAsset});

  final String asset;

  /// Shown if [asset] fails to load.
  final String? fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final fallback = fallbackAsset;
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: fallback == null
          ? null
          : (context, error, stackTrace) => AppBackdropImage(fallback),
    );
  }
}
