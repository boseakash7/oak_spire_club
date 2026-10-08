import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/utils/thousands_number_input_formatter.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/collection_form_field.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../core/widgets/show_app_dialog.dart';
import '../wishlist_controller.dart';

/// Add a bottle to the wishlist, or edit its target and note. [average] and
/// [low] are the bottle's market average and recent low, for the quick
/// target chips.
Future<void> showWishlistSheet(
  BuildContext context, {
  required String bottleId,
  required String name,
  double? average,
  double? low,
}) {
  return showAppAnimatedBottomSheet<void>(
    context: context,
    builder: (ctx) => _WishlistSheet(
      bottleId: bottleId,
      name: name,
      average: average,
      low: low,
    ),
  );
}

class _WishlistSheet extends StatefulWidget {
  const _WishlistSheet({
    required this.bottleId,
    required this.name,
    this.average,
    this.low,
  });

  final String bottleId;
  final String name;
  final double? average;
  final double? low;

  @override
  State<_WishlistSheet> createState() => _WishlistSheetState();
}

class _WishlistSheetState extends State<_WishlistSheet> {
  final _wishlist = WishlistController.to;
  late final _existing = _wishlist.itemFor(widget.bottleId);
  late final _target = TextEditingController(
    text: _existing?.targetPrice == null ? '' : _whole(_existing!.targetPrice!),
  );
  late final _note = TextEditingController(text: _existing?.note ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _target.dispose();
    _note.dispose();
    super.dispose();
  }

  static String _whole(double v) => v.round().toString();
  static String _money(double v) => PriceFormatter.format(_whole(v));

  double? get _typedTarget {
    final v = double.tryParse(
      PriceFormatter.normalizeForApi(_target.text) ?? '',
    );
    return v != null && v > 0 ? v : null;
  }

  void _pick(double v) {
    final text = ThousandsNumberInputFormatter()
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: _whole(v)),
        )
        .text;
    _target.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final note = _note.text.trim();
    final saved = await _wishlist.save(
      bottleId: widget.bottleId,
      targetPrice: _typedTarget,
      note: note.isEmpty ? null : note,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved != null) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    setState(() => _saving = true);
    final removed = await _wishlist.remove(widget.bottleId);
    if (!mounted) return;
    setState(() => _saving = false);
    if (removed) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final existing = _existing;
    final average = widget.average;
    final muted = AppTextStyles.bodyS().copyWith(color: AppColors.textWolf);

    final String intro;
    if (existing != null) {
      final from = existing.addedPrice, change = existing.changeSinceAdded;
      intro = from == null
          ? 'On your wishlist.'
          : 'Added at ${_money(from)}'
                '${average == null ? '' : ' · now ${_money(average)}'}'
                '${change == null ? '' : ' (${PriceFormatter.percentLabel(change)})'}';
    } else {
      intro = average == null
          ? 'No market price yet. We\'ll track it once it has one.'
          : 'We\'ll track its price from today: ${_money(average)}.';
    }

    final chips = <(String, double)>[
      if (widget.low != null && widget.low! > 0)
        ('Market low ${_money(widget.low!)}', widget.low!),
      if (average != null) ('−10%', average * 0.9),
      if (average != null) ('−20%', average * 0.8),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.cardSurfaceGradient,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.lg,
          AppSpacing.gutter,
          AppSpacing.md +
              MediaQuery.paddingOf(context).bottom +
              MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'Add to your wishlist' : 'Your wishlist',
                style: AppTextStyles.titleS().copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyM().copyWith(
                  color: AppColors.textCream,
                ),
              ),
              const SizedBox(height: 4),
              Text(intro, style: muted),
              const SizedBox(height: AppSpacing.md),
              Text('Target price (optional)', style: muted),
              const SizedBox(height: 6),
              CollectionFormField(
                controller: _target,
                hint: 'The price you would pay',
                prefixText: r'$ ',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [ThousandsNumberInputFormatter()],
                onChanged: (_) => setState(() {}),
              ),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (label, value) in chips)
                      _QuickChip(label: label, onTap: () => _pick(value)),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text('Note (optional)', style: muted),
              const SizedBox(height: 6),
              CollectionFormField(
                controller: _note,
                hint: 'Store pick is fine, for a birthday',
                textInputAction: TextInputAction.done,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),
              CommonPrimaryButton(
                label: existing == null ? 'Add to wishlist' : 'Save changes',
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
              if (existing != null) ...[
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: _saving ? null : _remove,
                  child: Text(
                    'Remove from wishlist',
                    style: AppTextStyles.bodyM().copyWith(
                      color: AppColors.marketTrendDown,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: PressHaptic.selection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceChip,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: AppColors.tagGoldBorder),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyS().copyWith(color: AppColors.goldBright),
        ),
      ),
    );
  }
}
