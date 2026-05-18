import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/network/app_cache_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/widgets/common_primary_button.dart';
import '../../data/models/category_bottle_model.dart';
import 'add_collection_controller.dart';
import 'fill_level_bottom_sheet.dart';

class AddCollectionView extends GetView<AddCollectionController> {
  const AddCollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDeep,
        elevation: 0,
        title: Text(
          'Add to collection',
          style: AppTextStyles.body16().copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          return Padding(
            padding: const EdgeInsets.fromLTRB(23, 12, 23, 16),
            child: ListView(
              children: [
                _ImagePreview(
                  previewImageUrl: controller.previewImageUrl.value,
                ),
                const SizedBox(height: 18),
                _Field(
                  controller: controller.bottleNameCtrl,
                  hint: 'Bottle name',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: controller.qtyCtrl,
                        hint: 'Quantity',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Field(
                        controller: controller.priceCtrl,
                        hint: 'Price',
                        prefix: r'$ ',
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsNumberInputFormatter()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        controller: controller.dateAcquiredCtrl,
                        onTap: () => controller.pickDate(Get.context!),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Field(
                        controller: controller.fillCtrl,
                        hint: 'Fill %',
                        readOnly: true,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          showFillLevelBottomSheet(
                            context,
                            fillController: controller.fillCtrl,
                          );
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          FillPercentInputFormatter(),
                        ],
                        prefixIcon: const Icon(
                          Icons.percent,
                          size: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Field(
                  controller: controller.notesCtrl,
                  hint: 'Notes / Tasting notes',
                  minLines: 3,
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                CommonPrimaryButton(
                  label: '+ Add to collection',
                  isLoading: controller.isSubmitting.value,
                  onPressed: controller.submit,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.previewImageUrl});
  final String previewImageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 195,
      height: 195,
      alignment: Alignment.center,
      child: Image.asset(
        AppAssets.collectionBottlePlaceholder,
        width: 195,
        height: 195,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
    return Container(
      height: 235,
      decoration: BoxDecoration(
        color: const Color(0xFF10090B),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF414141)),
      ),
      child: Center(
        child: previewImageUrl.isEmpty
            ? placeholder
            : CachedNetworkImage(
                imageUrl:
                    CategoryBottleModel(
                      id: '',
                      bottleName: '',
                      image: previewImageUrl,
                    ).resolvedImageUrl ??
                    previewImageUrl,
                cacheManager: AppCacheManager.images,
                width: 195,
                height: 195,
                fit: BoxFit.contain,
                placeholder: (context, _) => placeholder,
                errorWidget: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.prefix,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final String? prefix;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: AppTextStyles.body16().copyWith(fontSize: 14),
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        prefixIcon: prefixIcon,
        prefixText: prefix,
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: AppTextStyles.body16().copyWith(
          fontSize: 16,
          color: AppColors.white,
        ),
        filled: true,
        fillColor: const Color(0xFF10090B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF414141)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF414141)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF585858)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.controller, required this.onTap});

  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Field(
      controller: controller,
      hint: 'Date Acquired',
      readOnly: true,
      onTap: onTap,
      suffixIcon: const Icon(
        Icons.calendar_today,
        size: 18,
        color: AppColors.white,
      ),
    );
  }
}

class ThousandsNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = PriceFormatter.normalizeForApi(newValue.text);
    if (normalized == null) {
      return const TextEditingValue(text: '');
    }
    final formatted = PriceFormatter.format(normalized, withSymbol: false);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class FillPercentInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final parsed = int.tryParse(text);
    if (parsed == null) return oldValue;
    if (parsed < 1 || parsed > 100) return oldValue;
    return newValue;
  }
}

