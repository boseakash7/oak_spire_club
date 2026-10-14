import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/utils/thousands_number_input_formatter.dart';
import '../../../core/widgets/app_date_picker.dart';
import '../../../core/widgets/collection_form_field.dart';
import '../../../core/widgets/common_primary_button.dart';
import '../../../core/widgets/show_app_dialog.dart';
import '../../../data/models/collection_item_model.dart';

/// Saves the fields that changed; a null one is left as it is. Throws
/// [ApiException] when the server says no, and the sheet stays open.
typedef BottleEditSave =
    Future<void> Function({double? pricePaid, DateTime? purchasedOn});

final DateFormat _dateFormat = DateFormat('MMM d, y');

/// Edit one bottle of a kind: its price paid and purchase date. Pops true
/// once saved.
Future<bool?> showBottleEditSheet(
  BuildContext context, {
  required OwnedBottle bottle,
  required int number,
  required BottleEditSave onSave,
}) {
  return showAppAnimatedBottomSheet<bool>(
    context: context,
    builder: (ctx) =>
        _BottleEditSheet(bottle: bottle, number: number, onSave: onSave),
  );
}

class _BottleEditSheet extends StatefulWidget {
  const _BottleEditSheet({
    required this.bottle,
    required this.number,
    required this.onSave,
  });

  final OwnedBottle bottle;
  final int number;
  final BottleEditSave onSave;

  @override
  State<_BottleEditSheet> createState() => _BottleEditSheetState();
}

class _BottleEditSheetState extends State<_BottleEditSheet> {
  late final String _initialPrice = widget.bottle.pricePaid == null
      ? ''
      : PriceFormatter.format(
          widget.bottle.pricePaid!.round().toString(),
          withSymbol: false,
        );
  late final _price = TextEditingController(text: _initialPrice);
  late final _date = TextEditingController(
    text: _purchasedOn == null ? '' : _dateFormat.format(_purchasedOn!),
  );
  late DateTime? _purchasedOn = widget.bottle.purchasedOn;
  String? _priceError;
  bool _saving = false;

  @override
  void dispose() {
    _price.dispose();
    _date.dispose();
    super.dispose();
  }

  double? get _typedPrice =>
      double.tryParse(PriceFormatter.normalizeForApi(_price.text) ?? '');

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showAppDatePicker(
      context,
      initialDate: _purchasedOn ?? today,
      firstDate: DateTime(1950),
      lastDate: today,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _purchasedOn = DateUtils.dateOnly(picked);
      _date.text = _dateFormat.format(_purchasedOn!);
    });
  }

  Future<void> _save() async {
    final price = _typedPrice;
    if (price == null) {
      setState(() => _priceError = 'Enter what you paid');
      return;
    }

    // Only what changed goes up, so an untouched price keeps its cents.
    final priceChanged = _price.text != _initialPrice;
    final dateChanged =
        _purchasedOn != null && _purchasedOn != widget.bottle.purchasedOn;
    if (!priceChanged && !dateChanged) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(
        pricePaid: priceChanged ? price : null,
        purchasedOn: dateChanged ? _purchasedOn : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _saving = false);
      await AppSnackbar.error(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.bodyS().copyWith(color: AppColors.textWolf);

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
                'Edit bottle ${widget.number}',
                style: AppTextStyles.titleS().copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Changes this bottle only, not the others of its kind.',
                style: muted,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Price paid', style: muted),
              const SizedBox(height: 6),
              CollectionFormField(
                controller: _price,
                hint: 'What you paid for this bottle',
                prefixText: r'$ ',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [ThousandsNumberInputFormatter()],
                errorText: _priceError,
                onChanged: (_) {
                  if (_priceError != null) setState(() => _priceError = null);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Purchase date', style: muted),
              const SizedBox(height: 6),
              CollectionFormField(
                controller: _date,
                hint: 'When you bought it',
                readOnly: true,
                onTap: _pickDate,
                suffixIcon: const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CommonPrimaryButton(
                label: 'Save changes',
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
