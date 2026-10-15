import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/analytics/app_analytics_controller.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/limit_exceeded_exception.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/utils/proof_formatter.dart';
import '../../../core/utils/rating_formatter.dart';
import '../../../core/widgets/animated_fill_bar.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/bottle_image.dart';
import '../../../core/widgets/price_sparkline.dart';
import '../../../core/widgets/pricing_badge.dart';
import '../../../data/models/bottle_pricing.dart';
import '../../../data/models/collection_item_display.dart';
import '../../../data/models/collection_item_model.dart';
import '../../../data/models/price_sparkline.dart';
import '../../../routes/app_routes.dart';
import '../collection_controller.dart';
import 'collection_bottle_edit_sheet.dart';
import 'collection_bottle_list.dart';

const Color _kBackdrop = Color.fromRGBO(20, 14, 12, 0.72);

const double kCollectionCardRadius = 22;

/// Widest the card grows (a tablet).
const double _kMaxCardWidth = 400;
const double _kArtSize = 44;

/// Opens the quick view for [item] and reloads the collection if the quantity
/// changed.
///
/// It is a transparent [PageRoute], not a dialog, because only page routes
/// take part in a Hero flight: pass the row's [heroBottleId] and its bottle
/// art flies into the card, and back to the row on close.
Future<void> showCollectionQuickView(
  BuildContext cardContext, {
  required CollectionItemModel item,
  required CollectionController controller,
  String? heroBottleId,
}) async {
  final changed = await Navigator.of(cardContext).push<bool>(
    PageRouteBuilder<bool>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: AppMotion.page,
      reverseTransitionDuration: AppMotion.medium,
      pageBuilder: (context, animation, secondaryAnimation) => _QuickView(
        item: item,
        controller: controller,
        heroBottleId: heroBottleId,
      ),
      // Fade only: the Hero measures where its art lands, so the card must
      // not move while it flies.
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: AppMotion.enter,
              reverseCurve: AppMotion.exit,
            ),
            child: child,
          ),
    ),
  );

  if (changed == true) await controller.forceReload();
}

/// A compact card for one bottle: title row, today's value and gain, a strip
/// of figures, the average fill and the 90-day price line, a quantity stepper
/// with a link to the bottle's detail screen, and under them every bottle of
/// it, grouped by when it was added, each with its own fill. The card scrolls
/// as one column.
class _QuickView extends StatefulWidget {
  const _QuickView({
    required this.item,
    required this.controller,
    this.heroBottleId,
  });

  final CollectionItemModel item;
  final CollectionController controller;
  final String? heroBottleId;

  @override
  State<_QuickView> createState() => _QuickViewState();
}

class _QuickViewState extends State<_QuickView> {
  int _qty = 1;
  bool _busy = false;
  bool _changed = false;

  late CollectionItemModel _item = widget.item;

  /// This card's own copy of the bottles, so a fill moves on screen the
  /// moment it is changed and the average follows.
  late List<OwnedBottle> _bottles = List.of(widget.item.bottles ?? const []);

  @override
  void initState() {
    super.initState();
    final parsed = int.tryParse(widget.item.quantity ?? '');
    _qty = (parsed == null || parsed <= 0) ? 1 : parsed;
  }

  /// Average fill of every bottle, or the item's own when it has none listed.
  double get _avgFill => _bottles.isEmpty
      ? _item.fillRatio
      : _bottles.fold<int>(0, (sum, b) => sum + b.fill) / _bottles.length / 100;

  /// Takes in the item as the collection now has it (after an add or remove),
  /// or closes when it is gone.
  void _refresh() {
    final fresh = widget.controller.itemFor(
      widget.controller.resolveBottleId(_item),
    );
    if (fresh == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _item = fresh;
      _bottles = List.of(fresh.bottles ?? const []);
      _qty = fresh.displayQuantity;
    });
  }

  void _setLocalFill(OwnedBottle bottle, int fill) {
    setState(() {
      _bottles = [
        for (final b in _bottles)
          if (b.id == bottle.id) b.copyWith(fill: fill) else b,
      ];
    });
  }

  /// Runs a save, and on a failure says so and takes the real data back.
  Future<void> _save(Future<void> Function() action) async {
    _changed = true;
    try {
      await action();
    } on LimitExceededException {
      // The subscription screen has already opened with the message.
    } on ApiException catch (e) {
      await AppSnackbar.error(e.message);
      await widget.controller.forceReload();
      if (mounted) _refresh();
    }
  }

  Future<void> _commitFill(OwnedBottle bottle, int fill) =>
      _save(() => widget.controller.setBottleFill(bottle, fill));

  Future<void> _toggle(OwnedBottle bottle, {required bool opening}) {
    _setLocalFill(bottle, opening ? CollectionController.openedFill : 100);
    return _save(
      () => opening
          ? widget.controller.openBottle(bottle)
          : widget.controller.sealBottle(bottle),
    );
  }

  /// Edit one bottle's price and date. The save reloads the collection,
  /// so the card's paid, gain and value follow the new price.
  Future<void> _edit(OwnedBottle bottle, int number) async {
    if (_busy) return;
    final saved = await showBottleEditSheet(
      context,
      bottle: bottle,
      number: number,
      onSave: ({pricePaid, purchasedOn}) => widget.controller.editBottle(
        bottle,
        pricePaid: pricePaid,
        purchasedOn: purchasedOn,
      ),
    );
    if (saved != true || !mounted) return;
    _changed = true;
    _refresh();
  }

  /// Removes one bottle after a confirm that names it by date, price and
  /// fill. The last one takes the whole bottle out of the collection and
  /// closes the card.
  Future<void> _remove(OwnedBottle bottle, int number) async {
    if (_busy) return;
    final last = _bottles.length <= 1;
    final on = bottle.purchasedOn;
    final facts = [
      if (on != null) 'Bought ${_kRemoveDate.format(on)}',
      if (bottle.pricePaid != null) _money(bottle.pricePaid!),
      bottle.isOpened ? '${bottle.fill}% full' : 'Sealed',
    ].join(' · ');

    final confirmed = await showAppConfirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      title: last ? 'Remove ${_item.lineTitle}?' : 'Remove bottle $number?',
      message: last
          ? "$facts\nIt's your last one, so it leaves your collection. "
                "This can't be undone."
          : "$facts\nThis can't be undone.",
      confirmLabel: 'Remove',
      confirmIsDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    if (Get.isRegistered<AppAnalyticsController>()) {
      unawaited(
        AppAnalyticsController.to.logTap('collection_bottle_remove', {
          'last': last ? 1 : 0,
        }),
      );
    }

    setState(() => _busy = true);
    try {
      await widget.controller.removeBottle(_item, bottle);
      _changed = true;
      unawaited(
        AppSnackbar.success(
          last ? 'Removed from your collection' : 'Bottle $number removed',
        ),
      );
      if (mounted) _refresh();
    } on ApiException catch (e) {
      await AppSnackbar.error(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _close() => Navigator.of(context).pop(_changed);

  Future<void> _inc() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.controller.increaseBottleQuantity(_item, _qty + 1);
      _changed = true;
      if (mounted) _refresh();
    } on LimitExceededException {
      // The subscription screen has already opened with the message.
    } on ApiException catch (e) {
      await AppSnackbar.error(e.message);
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
        _item,
        next,
        reloadList: next > 0,
      );
      if (!mounted) return;
      _changed = true;
      if (next <= 0) {
        Navigator.of(context).pop(true);
      } else {
        _refresh();
      }
    } on ApiException catch (e) {
      await AppSnackbar.error(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Pushed from here, so the art flies from the card's title row; coming
  /// back returns to the card.
  Future<void> _openDetail() async {
    final bottleId = widget.controller.resolveBottleId(_item);
    await Get.toNamed(
      AppRoutes.benchmarkDetail,
      arguments: _item.benchmarkDetailArguments(bottleId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final cardWidth = math.min(size.width - AppSpacing.md * 2, _kMaxCardWidth);
    final maxHeight = size.height - padding.vertical - AppSpacing.md * 2;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: const ColoredBox(color: _kBackdrop),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: cardWidth,
                    maxHeight: maxHeight,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        kCollectionCardRadius,
                      ),
                      gradient: AppColors.cardSurfaceGradient,
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: AppShadows.goldGlow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        kCollectionCardRadius,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _QuickViewBody(
                                    item: _item,
                                    quantity: _qty,
                                    fill: _avgFill,
                                    sealedCount: _bottles.isEmpty
                                        ? null
                                        : _bottles
                                              .where((b) => !b.isOpened)
                                              .length,
                                    openedCount: _bottles.isEmpty
                                        ? null
                                        : _bottles
                                              .where((b) => b.isOpened)
                                              .length,
                                    heroBottleId: widget.heroBottleId,
                                    sparklines: widget.controller.sparklines,
                                    onClose: _close,
                                  ),
                                  _ActionBar(
                                    quantity: _qty,
                                    busy: _busy,
                                    onAdd: _inc,
                                    onRemove: _decOrRemove,
                                    onDetails: _openDetail,
                                  ),
                                  CollectionBottleList(
                                    bottles: _bottles,
                                    busy: _busy,
                                    onFillChanged: _setLocalFill,
                                    onFillCommitted: _commitFill,
                                    onToggle: _toggle,
                                    onEdit: _edit,
                                    onRemove: _remove,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(double v) => PriceFormatter.format(v.toStringAsFixed(2));

final DateFormat _kRemoveDate = DateFormat('MMM d, y');

final TextStyle _kStrongValue = AppTextStyles.bodyL().copyWith(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: AppColors.textCream,
);

Color _trendColor(double? v) => v == null || v == 0
    ? AppColors.textWolf
    : v > 0
    ? AppColors.trendPositive
    : AppColors.marketTrendDown;

/// Everything above the action bar. [quantity] follows the stepper, so
/// value, gain and paid track the live count.
class _QuickViewBody extends StatelessWidget {
  const _QuickViewBody({
    required this.item,
    required this.quantity,
    required this.fill,
    required this.sealedCount,
    required this.openedCount,
    required this.heroBottleId,
    required this.sparklines,
    required this.onClose,
  });

  final CollectionItemModel item;
  final int quantity;

  /// Average fill of every bottle, 0..1.
  final double fill;
  final int? sealedCount;
  final int? openedCount;
  final String? heroBottleId;

  /// The controller's observable map, read inside an [Obx] so the price line
  /// fills in when it arrives.
  final RxMap<String, PriceSparkline> sparklines;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final unitPaid = double.tryParse(item.pricePaid ?? '') ?? 0;
    final unitMarket = item.marketAverageValue;
    final hasMarket = unitMarket != null && unitMarket > 0;
    final paid = unitPaid * quantity;
    // Worth in proportion to what is left: quantity × average fill is the sum
    // of every bottle's fill.
    final market = hasMarket ? unitMarket * quantity * fill : null;
    final gain = market == null || paid <= 0 ? null : market - paid;
    final pct = gain == null ? null : gain / paid * 100;
    final movement = item.priceMovementRaw;
    final movementLabel = PriceFormatter.formatPriceMovementLabel(movement);
    final sparkKey = item.bluebookBottleId ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _TitleRow(item: item, heroBottleId: heroBottleId, onClose: onClose),
          const SizedBox(height: 12),
          _ValueLine(
            value: _money(market ?? paid * fill),
            atCost: market == null,
            quantity: quantity,
            gain: gain,
            pct: pct,
            pricing: market == null ? null : item.pricing,
          ),
          const SizedBox(height: 12),
          _StatStrip(
            cells: [
              _StatCell(label: 'QTY', value: '×$quantity'),
              if (paid > 0) _StatCell(label: 'PAID', value: _money(paid)),
              if (hasMarket)
                _StatCell(label: 'MARKET', value: _money(unitMarket)),
              if (movementLabel != '—')
                _StatCell(
                  label: 'LAST',
                  value: movementLabel,
                  color: PriceFormatter.priceMovementColor(movement),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _FillRow(fill: fill, sealed: sealedCount, opened: openedCount),
          const SizedBox(height: 12),
          // Always reads the map: an Obx that reads nothing throws.
          Obx(() => _PriceLine(spark: sparklines[sparkKey])),
        ],
      ),
    );
  }
}

/// Art, name and one line of facts, with the close button.
class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.item,
    required this.heroBottleId,
    required this.onClose,
  });

  final CollectionItemModel item;
  final String? heroBottleId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final details = item.details;
    final facts = [
      details.distillery ?? details.brand,
      details.spiritType,
      details.ageLabel,
      details.abvLabel ?? ProofFormatter.formatLabel(item.proof),
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    final hasRating = RatingFormatter.outOfTen(item.ratingRaw) != null;
    final meta = AppTextStyles.bodyS().copyWith(
      fontSize: 11.5,
      height: 1.3,
      color: AppColors.textMuted,
    );
    const sep = TextSpan(text: ' · ');

    final spans = <InlineSpan>[
      if (facts.isNotEmpty) TextSpan(text: facts.join(' · ')),
      if (item.isRareFind) ...[
        if (facts.isNotEmpty) sep,
        const TextSpan(
          text: 'Rare',
          style: TextStyle(
            color: AppColors.goldBright,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      if (hasRating) ...[
        if (facts.isNotEmpty || item.isRareFind) sep,
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 3),
            child: SvgPicture.asset(
              AppAssets.star,
              width: 10,
              height: 10,
              colorFilter: const ColorFilter.mode(
                AppColors.goldRich,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        TextSpan(text: RatingFormatter.label(item.ratingRaw)),
      ],
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox.square(
            dimension: _kArtSize,
            child: BottleImage(
              urls: item.resolvedImageCandidates,
              bottleId: heroBottleId,
              // Same as the collection row, so the Hero lands on art that is
              // already decoded.
              cacheWidthPx: BottleImage.rowCacheWidthPx,
              padding: const EdgeInsets.all(2),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.lineTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyL().copyWith(
                  fontSize: 15,
                  height: 1.2,
                  color: AppColors.white,
                ),
              ),
              if (item.lineSubtitle.isNotEmpty)
                Text(
                  item.lineSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: meta.copyWith(color: AppColors.textCream),
                ),
              if (spans.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(children: spans),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: meta,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 6),
        AppPressable(
          onTap: onClose,
          haptic: PressHaptic.selection,
          scale: 0.9,
          semanticLabel: 'Close',
          child: const SizedBox.square(
            dimension: 32,
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Today's value large, the gain beside it, and the price basis dot.
class _ValueLine extends StatelessWidget {
  const _ValueLine({
    required this.value,
    required this.atCost,
    required this.quantity,
    required this.gain,
    required this.pct,
    required this.pricing,
  });

  final String value;
  final bool atCost;
  final int quantity;
  final double? gain;
  final double? pct;
  final BottlePricing? pricing;

  @override
  Widget build(BuildContext context) {
    final g = gain;
    final p = pct;
    final color = _trendColor(g);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.fast),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            value,
            key: ValueKey(quantity),
            style: AppTextStyles.bodyL().copyWith(
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: AppColors.textCream,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: g != null && p != null
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${p >= 0 ? '+' : '-'}${p.abs().toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '  ${g >= 0 ? '+' : '-'}${_money(g.abs())}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    style: AppTextStyles.bodyS().copyWith(color: color),
                  ),
                )
              : Text(
                  atCost ? 'Valued at cost' : '',
                  style: AppTextStyles.bodyS().copyWith(
                    fontSize: 12,
                    color: AppColors.textWolf,
                  ),
                ),
        ),
        if (pricing != null) PricingBadge(pricing: pricing, compact: true),
      ],
    );
  }
}

/// One figure in the strip.
class _StatCell {
  const _StatCell({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;
}

/// Up to four figures in one panel, separated by hairlines.
class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.cells});

  final List<_StatCell> cells;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0)
              const SizedBox(
                height: 28,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.cardBorder,
                ),
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PanelLabel(cells[i].label),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      cells[i].value,
                      style: _kStrongValue.copyWith(
                        color: cells[i].color ?? AppColors.textCream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A thin fill bar with its percentage.
class _FillRow extends StatelessWidget {
  const _FillRow({required this.fill, this.sealed, this.opened});

  /// Average fill of every bottle, 0..1.
  final double fill;
  final int? sealed;
  final int? opened;

  @override
  Widget build(BuildContext context) {
    final counts = sealed == null || opened == null
        ? null
        : '$sealed sealed · $opened opened';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const _PanelLabel('FILL'),
            const SizedBox(width: 10),
            Expanded(child: AnimatedFillBar(value: fill, height: 5)),
            const SizedBox(width: 10),
            Text(
              '${(fill * 100).round()}%',
              style: _kStrongValue.copyWith(fontSize: 13),
            ),
            const SizedBox(width: 4),
            Text(
              'avg',
              style: AppTextStyles.bodyS().copyWith(
                fontSize: 11,
                color: AppColors.textWolf,
              ),
            ),
          ],
        ),
        if (counts != null) ...[
          const SizedBox(height: 4),
          Text(
            counts,
            style: AppTextStyles.bodyS().copyWith(
              fontSize: 11,
              color: AppColors.textWolf,
            ),
          ),
        ],
      ],
    );
  }
}

/// The 90-day line, full width, with the change beside its label.
class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.spark});

  final PriceSparkline? spark;

  @override
  Widget build(BuildContext context) {
    final change = spark?.changePct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: _PanelLabel('90 DAYS')),
            if (change != null)
              Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                style: _kStrongValue.copyWith(
                  fontSize: 13,
                  color: _trendColor(change),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, box) =>
              PriceSparklineView(data: spark, width: box.maxWidth, height: 40),
        ),
      ],
    );
  }
}

/// A soft inset surface on the card.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodyS().copyWith(
        fontSize: 10.5,
        letterSpacing: 1,
        fontWeight: FontWeight.w600,
        color: AppColors.textWolf,
      ),
    );
  }
}

/// Quantity stepper on the left, "View details" on the right.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.quantity,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
    required this.onDetails,
  });

  final int quantity;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final last = quantity <= 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.28),
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadii.chip),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepButton(
                  icon: last
                      ? Icons.delete_outline_rounded
                      : Icons.remove_rounded,
                  label: last ? 'Remove' : 'Remove one',
                  color: last ? AppColors.marketTrendDown : AppColors.textCream,
                  onTap: busy ? null : onRemove,
                ),
                SizedBox(
                  width: 32,
                  child: Center(
                    child: busy
                        ? const SizedBox.square(
                            dimension: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('$quantity', style: _kStrongValue),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  label: 'Add one',
                  color: AppColors.goldBright,
                  onTap: busy ? null : onAdd,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppPressable(
              onTap: onDetails,
              haptic: PressHaptic.tap,
              semanticLabel: 'View details',
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                  boxShadow: const [
                    BoxShadow(color: AppColors.goldGlow, blurRadius: 12),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View details',
                      style: AppTextStyles.bodyL().copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.tap,
      scale: 0.88,
      semanticLabel: label,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1,
        duration: AppMotion.of(context, AppMotion.fast),
        child: SizedBox.square(
          dimension: 40,
          child: AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.fast),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween(begin: 0.75, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(icon, key: ValueKey(icon), color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
