import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/constants/app_assets.dart';
import '../../core/network/app_cache_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/collection_form_field.dart';
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
      appBar: AppScreenAppBar(
        title: Text(
          'Add to collection',
          style: AppTextStyles.body16().copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          return Padding(
            padding: const EdgeInsets.fromLTRB(23, 12, 23, 16),
            child: ListView(
              children: [
                _ImagePreview(
                  previewImageUrl: controller.previewImageUrl.value,
                  localImageFile: controller.customImageFile.value,
                  showChangeImage: controller.isCustomBottle,
                  onChangeImage: controller.pickCustomImage,
                ),
                const SizedBox(height: 18),
                _Field(
                  controller: controller.bottleNameCtrl,
                  hint: 'Bottle name',
                  errorText: controller.bottleNameError.value,
                  onChanged: controller.clearBottleNameError,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Field(
                        controller: controller.qtyCtrl,
                        hint: 'Quantity',
                        keyboardType: TextInputType.number,
                        errorText: controller.qtyError.value,
                        onChanged: controller.clearQtyError,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Field(
                        controller: controller.priceCtrl,
                        hint: 'Price',
                        prefix: r'$ ',
                        keyboardType: TextInputType.number,
                        errorText: controller.priceError.value,
                        onChanged: controller.clearPriceError,
                        inputFormatters: [ThousandsNumberInputFormatter()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DateField(
                        controller: controller.dateAcquiredCtrl,
                        errorText: controller.dateAcquiredError.value,
                        onTap: () => controller.pickDate(Get.context!),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Field(
                        controller: controller.fillCtrl,
                        hint: 'Fill %',
                        readOnly: true,
                        errorText: controller.fillError.value,
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          await showFillLevelBottomSheet(
                            context,
                            fillController: controller.fillCtrl,
                          );
                          controller.clearFillError(controller.fillCtrl.text);
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
  const _ImagePreview({
    required this.previewImageUrl,
    required this.localImageFile,
    required this.showChangeImage,
    required this.onChangeImage,
  });

  final String previewImageUrl;
  final File? localImageFile;
  final bool showChangeImage;
  final VoidCallback onChangeImage;

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

    Widget imageChild;
    if (localImageFile != null) {
      imageChild = Image.file(
        localImageFile!,
        width: 195,
        height: 195,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (previewImageUrl.isEmpty) {
      imageChild = placeholder;
    } else {
      imageChild = CachedNetworkImage(
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
      );
    }

    return Container(
      height: 235,
      decoration: BoxDecoration(
        color: const Color(0xFF10090B),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF414141)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: imageChild),
          if (showChangeImage)
            Positioned(
              right: 27,
              bottom: 20,
              child: _ChangeImageButton(onTap: onChangeImage),
            ),
        ],
      ),
    );
  }
}

/// Figma node 150:284 — pill button on image preview for custom bottles.
class _ChangeImageButton extends StatelessWidget {
  const _ChangeImageButton({required this.onTap});

  final VoidCallback onTap;

  static const Color _gradientTop = Color(0xFF271C16);
  static const Color _gradientBottom = Color(0xFF201512);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(38),
        child: Ink(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(38),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_gradientTop, _gradientBottom],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 17,
                color: AppColors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'Change Image',
                style: AppTextStyles.body16().copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.white,
                  height: 1.0,
                ),
              ),
            ],
          ),
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
    this.errorText,
    this.onChanged,
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
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CollectionFormField(
      controller: controller,
      hint: hint,
      prefixText: prefix,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      inputFormatters: inputFormatters,
      errorText: errorText,
      onChanged: onChanged,
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.onTap,
    this.errorText,
  });

  final TextEditingController controller;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _Field(
      controller: controller,
      hint: 'Date Acquired',
      readOnly: true,
      onTap: onTap,
      errorText: errorText,
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

