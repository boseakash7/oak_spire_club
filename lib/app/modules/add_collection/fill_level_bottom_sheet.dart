import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// Leading width for [ph:wine] icon; gap matches Figma before the track.
const double _kWineIconSize = 28;
const double _kWineToTrackGap = 19;

/// Same vertical extent for header + slider rows so padding reads evenly.
const double _kSheetRowExtent = 48;

/// Figma [Bourbon — Add to collection](https://www.figma.com/design/172L0vTcVUDV6S4TnX16jo/Bourbon--Copy-?node-id=108-357): fill-level sheet (108:392+).
Future<void> showFillLevelBottomSheet(
  BuildContext context, {
  required TextEditingController fillController,
}) {
  final initial =
      (int.tryParse(fillController.text.trim()) ?? 100).clamp(1, 100);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    isScrollControlled: true,
    showDragHandle: false,
    builder: (ctx) {
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
      return _FillLevelBottomSheetBody(
        initialPercent: initial,
        bottomInset: bottomInset,
        onPercentChanged: (p) => fillController.text = p.toString(),
      );
    },
  );
}

class _FillLevelBottomSheetBody extends StatefulWidget {
  const _FillLevelBottomSheetBody({
    required this.initialPercent,
    required this.bottomInset,
    required this.onPercentChanged,
  });

  final int initialPercent;
  final double bottomInset;
  final ValueChanged<int> onPercentChanged;

  @override
  State<_FillLevelBottomSheetBody> createState() =>
      _FillLevelBottomSheetBodyState();
}

class _FillLevelBottomSheetBodyState extends State<_FillLevelBottomSheetBody> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialPercent.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final pct = _value.round().clamp(1, 100);
    final titleStyle = GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: AppColors.white,
    );
    final chipStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: AppColors.white,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.cardSurfaceGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(23, 20, 23, 20 + widget.bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _kSheetRowExtent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Fill Level', style: titleStyle),
                  const Spacer(),
                  Container(
                    width: 62,
                    height: 29,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text('$pct%', style: chipStyle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: _kWineIconSize,
                  height: _kSheetRowExtent,
                  child: Center(
                    child: SvgPicture.asset(
                      AppAssets.phWine,
                      width: _kWineIconSize,
                      height: _kWineIconSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: _kWineToTrackGap),
                Expanded(
                  child: SizedBox(
                    height: _kSheetRowExtent,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 12,
                          activeTrackColor: AppColors.goldRich,
                          inactiveTrackColor: AppColors.fillBarTrack,
                          thumbColor: AppColors.fillSliderThumb,
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                            elevation: 0,
                            pressedElevation: 0,
                          ),
                          trackShape: const RoundedRectSliderTrackShape(),
                          padding: EdgeInsets.zero,
                        ),
                        child: Slider(
                          padding: EdgeInsets.zero,
                          value: _value.clamp(1, 100),
                          min: 1,
                          max: 100,
                          divisions: 99,
                          onChanged: (v) {
                            setState(() => _value = v);
                            widget.onPercentChanged(v.round().clamp(1, 100));
                          },
                        ),
                      ),
                    ),
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
