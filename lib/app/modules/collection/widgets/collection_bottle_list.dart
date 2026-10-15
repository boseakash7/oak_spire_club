import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/animated_fill_bar.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../data/models/collection_item_model.dart';
import 'hold_to_toggle_button.dart';

final DateFormat _addedFormat = DateFormat('MMM d, y');

/// The slider's range for an opened bottle. A fill of 1 would read as a
/// fraction (100%), so the floor is 2; 100 is only for a sealed bottle.
const int _kMinOpenedFill = 2;
const int _kMaxOpenedFill = 99;

/// Every bottle of one kind, grouped by the day it was bought (the day it was
/// added when no purchase date is set), each with its price paid and fill. A
/// row opens to change that bottle: a slider once it is opened, a two-second
/// hold to open it or seal it again, Edit for its price and purchase date, and
/// Remove.
class CollectionBottleList extends StatefulWidget {
  const CollectionBottleList({
    super.key,
    required this.bottles,
    required this.onFillChanged,
    required this.onFillCommitted,
    required this.onToggle,
    this.onEdit,
    this.onRemove,
    this.busy = false,
  });

  final List<OwnedBottle> bottles;

  /// While the slider moves: update what's on screen.
  final void Function(OwnedBottle bottle, int fill) onFillChanged;

  /// When the slider is let go or a quick pick is tapped: save it.
  final void Function(OwnedBottle bottle, int fill) onFillCommitted;

  /// A finished hold: open ([opening] true) or seal the bottle.
  final Future<void> Function(OwnedBottle bottle, {required bool opening})
  onToggle;

  /// Edit: open the sheet for [bottle], shown as bottle [number].
  final void Function(OwnedBottle bottle, int number)? onEdit;

  /// Remove: confirm and remove [bottle], shown as bottle [number].
  final void Function(OwnedBottle bottle, int number)? onRemove;

  final bool busy;

  @override
  State<CollectionBottleList> createState() => _CollectionBottleListState();
}

class _CollectionBottleListState extends State<CollectionBottleList> {
  String? _expandedId;

  static int _byAdded(OwnedBottle a, OwnedBottle b) {
    final byTime = (a.createdAt ?? 0).compareTo(b.createdAt ?? 0);
    if (byTime != 0) return byTime;
    return (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final bottles = widget.bottles;
    if (bottles.isEmpty) return const SizedBox.shrink();

    // Numbered oldest first so a bottle keeps its number when more are added.
    final ordered = [...bottles]..sort(_byAdded);
    final number = {
      for (var i = 0; i < ordered.length; i++) ordered[i].id: i + 1,
    };

    final groups = <DateTime?, List<OwnedBottle>>{};
    for (final b in ordered) {
      groups.putIfAbsent(b.purchasedOn, () => []).add(b);
    }
    // Newest group first; bottles with no date last.
    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return b.compareTo(a);
      });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('YOUR BOTTLES · ${bottles.length}', style: _label),
          for (final key in keys) ...[
            _GroupHeader(at: key, count: groups[key]!.length),
            for (final b in groups[key]!)
              _BottleRow(
                key: ValueKey(b.id),
                bottle: b,
                number: number[b.id]!,
                expanded: _expandedId == b.id,
                busy: widget.busy,
                onTap: () => setState(
                  () => _expandedId = _expandedId == b.id ? null : b.id,
                ),
                onFillChanged: (fill) => widget.onFillChanged(b, fill),
                onFillCommitted: (fill) => widget.onFillCommitted(b, fill),
                onToggle: (opening) => widget.onToggle(b, opening: opening),
                onEdit: widget.onEdit == null
                    ? null
                    : () => widget.onEdit!(b, number[b.id]!),
                onRemove: widget.onRemove == null
                    ? null
                    : () => widget.onRemove!(b, number[b.id]!),
              ),
          ],
        ],
      ),
    );
  }
}

final TextStyle _label = AppTextStyles.bodyS().copyWith(
  fontSize: 10.5,
  letterSpacing: 1,
  fontWeight: FontWeight.w600,
  color: AppColors.textWolf,
);

String _money(double v) => PriceFormatter.format(v.toStringAsFixed(2));

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.at, required this.count});

  final DateTime? at;
  final int count;

  @override
  Widget build(BuildContext context) {
    final text = at == null ? 'Date unknown' : _addedFormat.format(at!);

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyS().copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textCream,
              ),
            ),
          ),
          Text(
            count == 1 ? '1 bottle' : '$count bottles',
            style: AppTextStyles.bodyS().copyWith(
              fontSize: 11.5,
              color: AppColors.textWolf,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottleRow extends StatefulWidget {
  const _BottleRow({
    super.key,
    required this.bottle,
    required this.number,
    required this.expanded,
    required this.busy,
    required this.onTap,
    required this.onFillChanged,
    required this.onFillCommitted,
    required this.onToggle,
    this.onEdit,
    this.onRemove,
  });

  final OwnedBottle bottle;
  final int number;
  final bool expanded;
  final bool busy;
  final VoidCallback onTap;
  final ValueChanged<int> onFillChanged;
  final ValueChanged<int> onFillCommitted;
  final Future<void> Function(bool opening) onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  State<_BottleRow> createState() => _BottleRowState();
}

class _BottleRowState extends State<_BottleRow> {
  /// 0..1 progress of the hold, to shake the row.
  final ValueNotifier<double> _hold = ValueNotifier(0);
  bool _flash = false;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Future<void> _toggled(bool opening) async {
    await widget.onToggle(opening);
    if (!mounted) return;
    _hold.value = 0;
    if (AppMotion.reduced(context)) return;
    setState(() => _flash = true);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (mounted) setState(() => _flash = false);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bottle;
    final opened = b.isOpened;
    final reduced = AppMotion.reduced(context);

    return ValueListenableBuilder<double>(
      valueListenable: _hold,
      builder: (context, p, child) {
        // The hold's shake, growing with it in step with the phone's rumble.
        final dx = reduced ? 0.0 : HoldToToggleButton.shakeOffset(p);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: AnimatedContainer(
        duration: _flash
            ? Duration.zero
            : AppMotion.of(context, AppMotion.slow),
        decoration: BoxDecoration(
          color: _flash
              ? AppColors.goldRich.withValues(alpha: 0.22)
              : Colors.transparent,
          border: const Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPressable(
              onTap: widget.onTap,
              haptic: PressHaptic.selection,
              scale: 0.99,
              semanticLabel: 'Bottle ${widget.number}',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.fillBarTrack,
                      ),
                      child: Text(
                        '${widget.number}',
                        style: AppTextStyles.bodyS().copyWith(
                          fontSize: 11,
                          color: AppColors.textCream,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 66,
                      child: Text(
                        b.pricePaid == null ? '—' : _money(b.pricePaid!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyL().copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textCream,
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedFillBar(value: b.fill / 100, height: 5),
                    ),
                    const SizedBox(width: 10),
                    _StateTag(opened: opened),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${b.fill}%',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodyL().copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textCream,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: widget.expanded ? 0.5 : 0,
                      duration: AppMotion.of(context, AppMotion.fast),
                      curve: AppMotion.standard,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: AppMotion.of(context, AppMotion.fast),
              curve: AppMotion.standard,
              alignment: Alignment.topCenter,
              child: widget.expanded
                  ? Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _EditStrip(
                            bottle: b,
                            busy: widget.busy,
                            onEdit: widget.onEdit,
                            onRemove: widget.onRemove,
                          ),
                          const SizedBox(height: 10),
                          opened
                              ? _OpenedPanel(
                                  bottle: b,
                                  busy: widget.busy,
                                  onChanged: widget.onFillChanged,
                                  onCommitted: widget.onFillCommitted,
                                  onProgress: (v) => _hold.value = v,
                                  onSeal: () => _toggled(false),
                                )
                              : _SealedPanel(
                                  busy: widget.busy,
                                  onProgress: (v) => _hold.value = v,
                                  onOpen: () => _toggled(true),
                                ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateTag extends StatelessWidget {
  const _StateTag({required this.opened});

  final bool opened;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.chip),
        color: opened
            ? AppColors.fillBarTrack
            : AppColors.trendPositive.withValues(alpha: 0.2),
      ),
      child: Text(
        opened ? 'Opened' : 'Sealed',
        style: AppTextStyles.bodyS().copyWith(
          fontSize: 10.5,
          color: opened ? AppColors.textMuted : AppColors.trendPositive,
        ),
      ),
    );
  }
}

/// When the bottle was bought (the row above already shows what was paid),
/// with Edit for its price and date, and Remove.
class _EditStrip extends StatelessWidget {
  const _EditStrip({
    required this.bottle,
    required this.busy,
    required this.onEdit,
    required this.onRemove,
  });

  final OwnedBottle bottle;
  final bool busy;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final on = bottle.purchasedOn;

    return Row(
      children: [
        Expanded(
          child: Text(
            on == null
                ? 'Purchase date not set'
                : 'Bought ${_addedFormat.format(on)}',
            style: AppTextStyles.bodyS().copyWith(
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
        if (onEdit != null)
          _StripChip(
            icon: Icons.edit_rounded,
            label: 'Edit',
            semanticLabel: 'Edit price and purchase date',
            color: AppColors.goldBright,
            border: AppColors.tagGoldBorder,
            onTap: busy ? null : onEdit,
          ),
        if (onRemove != null) ...[
          const SizedBox(width: 6),
          _StripChip(
            icon: Icons.delete_outline_rounded,
            label: 'Remove',
            semanticLabel: 'Remove this bottle',
            color: AppColors.errorLight,
            border: AppColors.destructiveDeep,
            onTap: busy ? null : onRemove,
          ),
        ],
      ],
    );
  }
}

/// A small outlined action on the strip.
class _StripChip extends StatelessWidget {
  const _StripChip({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.color,
    required this.border,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final Color color;
  final Color border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.selection,
      scale: 0.94,
      semanticLabel: semanticLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceChip,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodyS().copyWith(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SealedPanel extends StatelessWidget {
  const _SealedPanel({
    required this.busy,
    required this.onProgress,
    required this.onOpen,
  });

  final bool busy;
  final ValueChanged<double> onProgress;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sealed. Open it to set how much is left.',
          style: AppTextStyles.bodyS().copyWith(
            fontSize: 11.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        HoldToToggleButton(
          key: const ValueKey('open'),
          opening: true,
          enabled: !busy,
          onProgress: onProgress,
          onComplete: onOpen,
        ),
      ],
    );
  }
}

class _OpenedPanel extends StatelessWidget {
  const _OpenedPanel({
    required this.bottle,
    required this.busy,
    required this.onChanged,
    required this.onCommitted,
    required this.onProgress,
    required this.onSeal,
  });

  final OwnedBottle bottle;
  final bool busy;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onCommitted;
  final ValueChanged<double> onProgress;
  final VoidCallback onSeal;

  @override
  Widget build(BuildContext context) {
    final value = bottle.fill
        .clamp(_kMinOpenedFill, _kMaxOpenedFill)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: AppColors.goldRich,
            inactiveTrackColor: AppColors.fillBarTrack,
            thumbColor: AppColors.fillSliderThumb,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 9,
              elevation: 0,
              pressedElevation: 0,
            ),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: value,
            min: _kMinOpenedFill.toDouble(),
            max: _kMaxOpenedFill.toDouble(),
            divisions: _kMaxOpenedFill - _kMinOpenedFill,
            onChanged: busy ? null : (v) => onChanged(v.round()),
            onChangeEnd: busy ? null : (v) => onCommitted(v.round()),
          ),
        ),
        Row(
          children: [
            _QuickPick(label: 'Half', onTap: busy ? null : () => _pick(50)),
            const SizedBox(width: 8),
            _QuickPick(
              label: 'Last pour',
              onTap: busy ? null : () => _pick(10),
            ),
          ],
        ),
        const SizedBox(height: 10),
        HoldToToggleButton(
          key: const ValueKey('seal'),
          opening: false,
          enabled: !busy,
          onProgress: onProgress,
          onComplete: onSeal,
        ),
        const SizedBox(height: 6),
        Text(
          'Sealing puts it back to 100%.',
          style: AppTextStyles.bodyS().copyWith(
            fontSize: 11,
            color: AppColors.textWolf,
          ),
        ),
      ],
    );
  }

  void _pick(int fill) {
    onChanged(fill);
    onCommitted(fill);
  }
}

class _QuickPick extends StatelessWidget {
  const _QuickPick({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.selection,
      scale: 0.94,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyS().copyWith(
            fontSize: 12,
            color: AppColors.textCream,
          ),
        ),
      ),
    );
  }
}
