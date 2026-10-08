import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/animations/app_overlay_entrance.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_pressable.dart';
import '../collection_controller.dart';

/// Sort button (opens an anchored menu) and, when the list was opened from a
/// quick-stat tile, that tile's filter as a pill that clears it.
class CollectionFilterRow extends StatefulWidget {
  const CollectionFilterRow({super.key, required this.controller});

  final CollectionController controller;

  @override
  State<CollectionFilterRow> createState() => _CollectionFilterRowState();
}

class _CollectionFilterRowState extends State<CollectionFilterRow>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  late final AnimationController _menuController;
  late final CurvedAnimation _menuCurve;
  OverlayEntry? _entry;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: AppMotion.dropdown,
      reverseDuration: AppMotion.fast,
    );
    _menuCurve = CurvedAnimation(
      parent: _menuController,
      curve: AppMotion.dropdownEnter,
      reverseCurve: AppMotion.dropdownExit,
    );
    _menuController.addStatusListener(_onMenuAnimationStatus);
    _menuCurve.addListener(_rebuildOverlay);
  }

  @override
  void dispose() {
    _menuCurve.removeListener(_rebuildOverlay);
    _menuController.removeStatusListener(_onMenuAnimationStatus);
    _removeOverlay();
    _menuCurve.dispose();
    _menuController.dispose();
    super.dispose();
  }

  void _rebuildOverlay() => _entry?.markNeedsBuild();

  void _onMenuAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _menuOpen) {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
    if (mounted) {
      if (_menuOpen) setState(() => _menuOpen = false);
    } else {
      _menuOpen = false;
    }
  }

  void _closeMenu({bool animated = true}) {
    if (!_menuOpen) return;

    if (animated) {
      _menuController.reverse();
    } else {
      _menuController.value = 0;
      _removeOverlay();
    }
  }

  void _openMenu() {
    if (_menuOpen) return;

    _menuOpen = true;
    setState(() {});

    _entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: appOverlayScrim(
                animation: _menuCurve,
                onDismiss: _closeMenu,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: const Offset(41, 0),
              child: RepaintBoundary(
                child: appOverlayDropdownEntrance(
                  animation: _menuCurve,
                  scaleAlignment: Alignment.topLeft,
                  child: _SortMenu(
                    controller: widget.controller,
                    onClose: _closeMenu,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_entry!);
    _menuController.forward(from: 0);
  }

  void _toggle() {
    if (_menuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          CompositedTransformTarget(
            link: _link,
            child: InkResponse(
              onTap: _toggle,
              radius: 24,
              child: Obx(
                () => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedRotation(
                      turns: _menuOpen ? 0.5 : 0,
                      duration: AppMotion.of(context, AppMotion.medium),
                      curve: AppMotion.emphasizedDecelerate,
                      child: SvgPicture.asset(
                        AppAssets.collectionFilterIcon,
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          _menuOpen
                              ? AppColors.goldBright
                              : AppColors.textMuted,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: AnimatedScale(
                        scale: widget.controller.hasActiveSort ? 1 : 0,
                        duration: AppMotion.of(context, AppMotion.fast),
                        curve: AppMotion.emphasized,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.badgeAlert,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 9, height: 9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              final filter = widget.controller.filter.value;
              return Align(
                alignment: Alignment.centerLeft,
                child: AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: filter == CollectionFilter.all
                      ? const SizedBox.shrink()
                      : _ActiveFilterPill(
                          key: ValueKey(filter),
                          label: filter.label,
                          onClear: widget.controller.clearFilter,
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// The quick-stat filter the list was opened with; tapping it shows every
/// bottle again.
class _ActiveFilterPill extends StatelessWidget {
  const _ActiveFilterPill({
    super.key,
    required this.label,
    required this.onClear,
  });

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onClear,
      haptic: PressHaptic.selection,
      semanticLabel: 'Clear filter $label',
      child: Container(
        height: 28,
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(42),
          gradient: AppColors.goldGradient,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              style: AppTextStyles.uiChip().copyWith(color: AppColors.black),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.close_rounded, size: 16, color: AppColors.black),
          ],
        ),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.controller, required this.onClose});

  final CollectionController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 156,
        height: 182,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          color: AppColors.menuSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowBlack32,
              blurRadius: 4.8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(7, 12, 6, 10),
        child: Obx(() {
          final showSelected = controller.hasActiveSort;
          return Column(
            children: [
              _SortMenuRow(
                label: 'Name',
                selected:
                    showSelected &&
                    controller.sort.value == CollectionSort.name,
                ascending: controller.sortAscending.value,
                onTap: () {
                  controller.toggleSort(CollectionSort.name);
                  onClose();
                },
              ),
              const SizedBox(height: 5),
              _SortMenuRow(
                label: 'Price',
                selected:
                    showSelected &&
                    controller.sort.value == CollectionSort.price,
                ascending: controller.sortAscending.value,
                onTap: () {
                  controller.toggleSort(CollectionSort.price);
                  onClose();
                },
              ),
              const SizedBox(height: 5),
              _SortMenuRow(
                label: 'Gain',
                selected:
                    showSelected &&
                    controller.sort.value == CollectionSort.gain,
                ascending: controller.sortAscending.value,
                onTap: () {
                  controller.toggleSort(CollectionSort.gain);
                  onClose();
                },
              ),
              const SizedBox(height: 5),
              _SortMenuRow(
                label: 'Fill Rate',
                selected:
                    showSelected &&
                    controller.sort.value == CollectionSort.fillRate,
                ascending: controller.sortAscending.value,
                onTap: () {
                  controller.toggleSort(CollectionSort.fillRate);
                  onClose();
                },
              ),
              _SortMenuRow(
                label: 'Added Time',
                selected:
                    showSelected &&
                    controller.sort.value == CollectionSort.addedTime,
                ascending: controller.sortAscending.value,
                onTap: () {
                  controller.toggleSort(CollectionSort.addedTime);
                  onClose();
                },
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SortMenuRow extends StatelessWidget {
  const _SortMenuRow({
    required this.label,
    required this.selected,
    required this.ascending,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool ascending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.menuRowSelected : Colors.transparent;
    final upColor = selected && ascending
        ? AppColors.white
        : AppColors.sortChevronInactive;
    final downColor = selected && !ascending
        ? AppColors.white
        : AppColors.sortChevronInactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 29,
        width: 143,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.uiCardTitle().copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AppAssets.sortChevronUp,
                  width: 6,
                  height: 7,
                  colorFilter: ColorFilter.mode(upColor, BlendMode.srcIn),
                ),
                const SizedBox(height: 2),
                Transform.rotate(
                  angle: 3.1415926535,
                  child: SvgPicture.asset(
                    AppAssets.sortChevronDown,
                    width: 6,
                    height: 7,
                    colorFilter: ColorFilter.mode(downColor, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
