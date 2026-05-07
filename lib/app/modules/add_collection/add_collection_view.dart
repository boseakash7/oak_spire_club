import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/bluebook_model.dart';
import 'add_collection_controller.dart';

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
          'Add to Collection',
          style: AppTextStyles.body16().copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          final selected = controller.selected.value;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _SearchField(
                  controller: controller.searchCtrl,
                  onClear: () => controller.searchCtrl.clear(),
                ),
                const SizedBox(height: 12),
                if (selected == null) ...[
                  Expanded(child: _ResultsList(onPick: controller.pick)),
                ] else ...[
                  _SelectedHeader(
                    bottle: selected,
                    onChange: controller.clearSelection,
                  ),
                  const SizedBox(height: 14),
                  _FormCard(),
                ],
                const SizedBox(height: 12),
                _BottomActions(
                  hasSelection: selected != null,
                  isSubmitting: controller.isSubmitting.value,
                  onCreate: controller.createCustomBottle,
                  onSubmit: controller.submit,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.body16().copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search bottles or add your own',
        hintStyle: AppTextStyles.body16().copyWith(
          fontSize: 14,
          color: AppColors.textMuted,
        ),
        filled: true,
        fillColor: AppColors.black.withValues(alpha: 0.25),
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        suffixIcon: IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.close, color: AppColors.textMuted),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
      ),
    );
  }
}

class _ResultsList extends GetView<AddCollectionController> {
  const _ResultsList({required this.onPick});

  final ValueChanged<BluebookModel> onPick;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 220) {
          controller.loadMore();
        }
        return false;
      },
      child: Obx(() {
        final list = controller.results;
        if (controller.isSearching.value && list.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold1),
          );
        }
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No bottles found.\nType a name and set price, then tap Create.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body16().copyWith(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: list.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == list.length) {
              return Obx(() {
                if (!controller.isSearching.value) {
                  return const SizedBox(height: 10);
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.gold1),
                  ),
                );
              });
            }
            final b = list[index];
            return _BottleResultTile(bottle: b, onTap: () => onPick(b));
          },
        );
      }),
    );
  }
}

class _BottleResultTile extends StatelessWidget {
  const _BottleResultTile({required this.bottle, required this.onTap});

  final BluebookModel bottle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppColors.cardSurfaceGradient,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  bottle.bottleName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body16().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                bottle.average == null ? '' : '\$${bottle.average}',
                style: AppTextStyles.body16().copyWith(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedHeader extends StatelessWidget {
  const _SelectedHeader({required this.bottle, required this.onChange});

  final BluebookModel bottle;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.cardSurfaceGradient,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              bottle.bottleName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body16().copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onChange,
            child: Text(
              'Change',
              style: AppTextStyles.body16().copyWith(
                fontSize: 13,
                color: AppColors.goldBright,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends GetView<AddCollectionController> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: AppColors.cardSurfaceGradient,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Purchase Price',
                style: AppTextStyles.body16().copyWith(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _Field(
                controller: controller.priceCtrl,
                hint: '0.00',
                prefix: '\$',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              Text(
                'Quantity',
                style: AppTextStyles.body16().copyWith(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _Field(
                controller: controller.qtyCtrl,
                hint: '1',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),
              Text(
                'Fill Level',
                style: AppTextStyles.body16().copyWith(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Obx(() {
                final v = controller.fillPercent.value;
                return SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbColor: AppColors.goldBright,
                    activeTrackColor: AppColors.goldBright,
                    inactiveTrackColor: AppColors.fillBarTrack,
                    trackHeight: 6,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayColor: AppColors.goldBright.withValues(alpha: 0.2),
                    valueIndicatorColor: AppColors.goldRich,
                    valueIndicatorTextStyle:
                        AppTextStyles.body16().copyWith(fontSize: 12),
                  ),
                  child: Slider(
                    value: v.clamp(0, 100),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${v.toStringAsFixed(0)}%',
                    onChanged: (nv) => controller.fillPercent.value = nv,
                  ),
                );
              }),
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
  });

  final TextEditingController controller;
  final String hint;
  final String? prefix;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.body16().copyWith(fontSize: 14),
      decoration: InputDecoration(
        prefixText: prefix,
        hintText: hint,
        hintStyle: AppTextStyles.body16().copyWith(
          fontSize: 14,
          color: AppColors.textMuted,
        ),
        filled: true,
        fillColor: AppColors.black.withValues(alpha: 0.18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.hasSelection,
    required this.isSubmitting,
    required this.onCreate,
    required this.onSubmit,
  });

  final bool hasSelection;
  final bool isSubmitting;
  final VoidCallback onCreate;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSubmitting
            ? null
            : hasSelection
                ? onSubmit
                : onCreate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldRich,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(
                hasSelection ? 'Submit' : 'Create',
                style: AppTextStyles.body16().copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

