import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../animations/app_motion.dart';
import '../constants/app_assets.dart';
import '../constants/app_hero_tags.dart';
import '../network/app_cache_manager.dart';
import '../theme/app_colors.dart';

/// Bottle art, the same way everywhere: warm glow behind, the placeholder
/// bottle until the image arrives, a soft fade-in, and a Hero so the bottle
/// flies between a list row and the screen it opens.
///
/// Give [urls] when the API's image field has several plausible locations
/// (collection items); each is tried in turn until one loads.
class BottleImage extends StatelessWidget {
  const BottleImage({
    super.key,
    this.url,
    this.urls,
    this.bottleId,
    this.fit = BoxFit.contain,
    this.glow = true,
    this.cacheWidthPx,
    this.padding = EdgeInsets.zero,
  });

  final String? url;
  final List<String>? urls;

  /// Enables the Hero; rows without a stable id skip it (see [AppHeroTags]).
  final String? bottleId;

  final BoxFit fit;
  final bool glow;
  final int? cacheWidthPx;
  final EdgeInsetsGeometry padding;

  List<String> get _candidates {
    final list = urls ?? [?url];
    return list.where((u) => u.trim().isNotEmpty).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _candidates;
    final placeholder = Image.asset(
      AppAssets.collectionBottlePlaceholder,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );

    final art = Stack(
      fit: StackFit.expand,
      children: [
        if (glow)
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.bottleRadialGlow),
          ),
        Padding(
          padding: padding,
          child: candidates.isEmpty
              ? placeholder
              : _FallbackNetworkImage(
                  urls: candidates,
                  fit: fit,
                  placeholder: placeholder,
                  cacheWidthPx: cacheWidthPx,
                ),
        ),
      ],
    );

    final tag = AppHeroTags.bottleImage(bottleId);
    if (tag == null) return art;

    return Hero(
      tag: tag,
      // Fly the art that is already decoded: the row's on the way in, the
      // row's again on the way back. The detail asks for a bigger image (a
      // different cache entry), so flying it would flash the placeholder
      // until it decodes.
      flightShuttleBuilder: (context, animation, direction, from, to) =>
          direction == HeroFlightDirection.push ? from.widget : to.widget,
      child: art,
    );
  }
}

/// Tries each URL in turn. An image already in memory shows at once (so a
/// new copy of the same art, like a Hero's, never flashes the placeholder);
/// one still loading fades in over the placeholder.
class _FallbackNetworkImage extends StatefulWidget {
  const _FallbackNetworkImage({
    required this.urls,
    required this.fit,
    required this.placeholder,
    this.cacheWidthPx,
  });

  final List<String> urls;
  final BoxFit fit;
  final Widget placeholder;
  final int? cacheWidthPx;

  @override
  State<_FallbackNetworkImage> createState() => _FallbackNetworkImageState();
}

class _FallbackNetworkImageState extends State<_FallbackNetworkImage> {
  int _index = 0;
  bool _advanceScheduled = false;

  @override
  void didUpdateWidget(_FallbackNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.urls, widget.urls)) _index = 0;
  }

  // Runs from inside the error builder, so the state change waits for the
  // next frame.
  void _advance() {
    if (_advanceScheduled || _index >= widget.urls.length - 1) return;
    _advanceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _index += 1;
        _advanceScheduled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.urls[_index];
    final fade = AppMotion.of(context, AppMotion.fast);
    final cacheWidth = widget.cacheWidthPx;

    // CachedNetworkImage (OctoImage) skips the placeholder and the fade
    // when the image resolves synchronously from the memory cache.
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: AppCacheManager.images,
      memCacheWidth: cacheWidth != null && cacheWidth > 0 ? cacheWidth : null,
      fit: widget.fit,
      filterQuality: FilterQuality.medium,
      placeholder: (context, _) => widget.placeholder,
      placeholderFadeInDuration: Duration.zero,
      fadeInDuration: fade,
      fadeInCurve: AppMotion.enter,
      fadeOutDuration: fade,
      errorWidget: (context, error, stackTrace) {
        if (kDebugMode) debugPrint('[BottleImage] failed: $url ($error)');
        _advance();
        return widget.placeholder;
      },
    );
  }
}
