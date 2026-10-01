import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/animations/app_dialog_transitions.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_fill_bar.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/bottle_image.dart';
import '../../../data/models/collection_item_display.dart';
import '../../../data/models/collection_item_model.dart';
import '../../../routes/app_routes.dart';
import '../collection_controller.dart';
import 'collection_bottle_card.dart';

const Color _kBackdrop = Color.fromRGBO(49, 49, 49, 0.67);

/// Opens the quick view for [item], flying it out of the card at
/// [cardContext], and reloads the collection if the quantity changed.
Future<void> showCollectionQuickView(
  BuildContext cardContext, {
  required CollectionItemModel item,
  required CollectionController controller,
}) async {
  final box = cardContext.findRenderObject() as RenderBox?;
  final sourceRect = box == null || !box.hasSize
      ? null
      : (box.localToGlobal(Offset.zero) & box.size);

  final changed = await showGeneralDialog<bool>(
    context: cardContext,
    barrierDismissible: false,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: AppMotion.dialog,
    transitionBuilder: appDialogScaleFadeTransition,
    pageBuilder: (context, animation, secondaryAnimation) =>
        _QuickView(item: item, controller: controller, sourceRect: sourceRect),
  );

  if (changed == true) await controller.forceReload();
}

/// A larger card with quantity controls (+, − / delete) and a link to the
/// bottle's detail screen.
class _QuickView extends StatefulWidget {
  const _QuickView({
    required this.item,
    required this.controller,
    this.sourceRect,
  });

  final CollectionItemModel item;
  final CollectionController controller;
  final Rect? sourceRect;

  @override
  State<_QuickView> createState() => _QuickViewState();
}

class _QuickViewState extends State<_QuickView> {
  static const double _cardWidth = 196;
  static const double _cardHeight = 226;

  int _qty = 1;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    final parsed = int.tryParse(widget.item.quantity ?? '');
    _qty = (parsed == null || parsed <= 0) ? 1 : parsed;
  }

  void _close() => Navigator.of(context).pop(_changed);

  Future<void> _inc() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final next = _qty + 1;
      await widget.controller.increaseBottleQuantity(
        widget.item,
        next,
        reloadList: false,
      );
      if (mounted) {
        setState(() {
          _qty = next;
          _changed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decOrRemove() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final next = _qty - 1;
      await widget.controller.decreaseBottleQuantity(
        widget.item,
        next,
        reloadList: false,
      );
      if (!mounted) return;
      _changed = true;
      if (next <= 0) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _qty = next);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDetail() async {
    final hadChanges = _changed;
    final bottleId = widget.controller.resolveBottleId(widget.item);
    Navigator.of(context).pop(false);
    await Get.toNamed(
      AppRoutes.benchmarkDetail,
      arguments: widget.item.benchmarkDetailArguments(bottleId),
    );
    if (hadChanges) await widget.controller.forceReload();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: const ColoredBox(color: _kBackdrop),
              ),
            ),
          ),
          Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 36),
            child: _FlyFromSource(
              sourceRect: widget.sourceRect,
              cardWidth: _cardWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: _cardWidth,
                    height: _cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        kCollectionCardRadius,
                      ),
                      gradient: AppColors.cardSurfaceGradient,
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: AppShadows.goldGlow,
                    ),
                    padding: const EdgeInsets.fromLTRB(15, 16, 15, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox.square(
                              dimension: kCollectionBottleImage,
                              child: BottleImage(
                                urls: item.resolvedImageCandidates,
                                cacheWidthPx:
                                    (kCollectionBottleImage *
                                            MediaQuery.devicePixelRatioOf(
                                              context,
                                            ))
                                        .round(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        CollectionCardDetails(item: item),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: AppMotion.of(context, AppMotion.fast),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween(
                                          begin: const Offset(0, 0.4),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                child: Text(
                                  '${item.priceLabel} ($_qty)',
                                  key: ValueKey(_qty),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyL().copyWith(
                                    fontSize: 12,
                                    color: AppColors.textCream,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 63,
                              child: AnimatedFillBar(
                                value: item.fillRatio,
                                height: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: _cardWidth,
                    child: Row(
                      children: [
                        _ActionButton(
                          index: 0,
                          icon: Icons.add_rounded,
                          label: 'Add one',
                          onTap: _busy ? null : _inc,
                        ),
                        const SizedBox(width: 10),
                        _ActionButton(
                          index: 1,
                          icon: _qty <= 1
                              ? Icons.delete_outline_rounded
                              : Icons.remove_rounded,
                          label: _qty <= 1 ? 'Remove' : 'Remove one',
                          onTap: _busy ? null : _decOrRemove,
                        ),
                        const Spacer(),
                        if (_busy)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        _ActionButton(
                          index: 2,
                          icon: Icons.visibility_rounded,
                          label: 'View details',
                          onTap: _busy ? null : _openDetail,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scales and translates [child] from the tapped card to the screen centre.
/// A popup route cannot take part in a Hero flight, so the card itself
/// provides the sense of the bottle lifting out of the grid.
class _FlyFromSource extends StatelessWidget {
  const _FlyFromSource({
    required this.sourceRect,
    required this.cardWidth,
    required this.child,
  });

  final Rect? sourceRect;
  final double cardWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, const Duration(milliseconds: 360)),
      curve: AppMotion.emphasizedDecelerate,
      builder: (context, t, child) {
        final source = sourceRect;
        final screen = MediaQuery.sizeOf(context);
        final target = Offset(screen.width / 2, screen.height / 2 - 8);
        final from = source?.center ?? target;
        final fromScale = source == null
            ? 0.92
            : (source.width / cardWidth).clamp(0.65, 1.0);
        return Transform.translate(
          offset: (from - target) * (1 - t),
          child: Transform.scale(
            scale: lerpDouble(fromScale, 1.0, t)!,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.index,
    required this.icon,
    required this.label,
    this.onTap,
  });

  static const double _size = 40;

  final int index;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Pop in one after another once the card has landed.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(
        context,
        AppMotion.medium + AppMotion.staggerStep * (index + 2),
      ),
      curve: const Interval(0.35, 1, curve: Curves.easeOutBack),
      builder: (context, t, child) =>
          Transform.scale(scale: t.clamp(0.0, 1.2), child: child),
      child: AppPressable(
        onTap: onTap,
        haptic: PressHaptic.tap,
        scale: 0.9,
        semanticLabel: label,
        child: AnimatedOpacity(
          opacity: onTap == null ? 0.5 : 1,
          duration: AppMotion.of(context, AppMotion.fast),
          child: Container(
            width: _size,
            height: _size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
              boxShadow: [BoxShadow(color: AppColors.goldGlow, blurRadius: 10)],
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.fast),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                icon,
                key: ValueKey(icon),
                color: AppColors.black,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
