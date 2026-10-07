import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_image_url.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/app_segmented_range.dart';
import '../../../data/models/bluebook_model.dart';
import '../../../data/models/price_sparkline.dart';
import '../../../routes/app_routes.dart';
import '../../market/benchmark_detail_controller.dart';
import 'dashboard_bottle_row.dart';
import 'dashboard_section_header.dart';

enum _Direction { rising, falling }

/// "Biggest movers": the market bottles that rose (or fell) most over
/// [windowDays], with a rising / falling toggle, one card per bottle. Each
/// row carries its price line over the same window and opens the bottle;
/// [onSeeAll] opens the full lists.
class DashboardMovers extends StatefulWidget {
  const DashboardMovers({
    super.key,
    required this.gainers,
    required this.losers,
    required this.windowDays,
    required this.sparklines,
    required this.heroIds,
    required this.onSeeAll,
    required this.onOpen,
    this.onDirectionChanged,
  });

  final List<BluebookModel> gainers;
  final List<BluebookModel> losers;
  final int windowDays;

  /// Price lines keyed by bottle id; a missing one draws the placeholder.
  final Map<String, PriceSparkline> sparklines;

  /// Bottles whose art may fly into the detail (each id once per page).
  final Set<String> heroIds;
  final VoidCallback? onSeeAll;
  final ValueChanged<String> onOpen;

  /// Called with `true` for rising, `false` for falling.
  final ValueChanged<bool>? onDirectionChanged;

  @override
  State<DashboardMovers> createState() => _DashboardMoversState();
}

class _DashboardMoversState extends State<DashboardMovers> {
  _Direction _direction = _Direction.rising;

  void _select(_Direction value) {
    if (_direction == value) return;
    setState(() => _direction = value);
    widget.onDirectionChanged?.call(value == _Direction.rising);
  }

  @override
  Widget build(BuildContext context) {
    final gainers = widget.gainers;
    final losers = widget.losers;
    if (gainers.isEmpty && losers.isEmpty) return const SizedBox.shrink();

    final rising = _direction == _Direction.rising;
    final rows = rising ? gainers : losers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(
          title: 'Biggest movers',
          subtitle: 'Market prices over the last ${widget.windowDays} days',
          trailing: AppSegmentedRange<_Direction>(
            values: _Direction.values,
            selected: _direction,
            segmentWidth: 64,
            labelOf: (d) => d == _Direction.rising ? 'Rising' : 'Falling',
            onChanged: _select,
          ),
        ),
        AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.stateSwitch),
          child: rows.isEmpty
              ? Padding(
                  key: ValueKey('empty-$_direction'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    rising
                        ? 'No bottle has risen in this window yet.'
                        : 'No bottle has fallen in this window yet.',
                    style: AppTextStyles.bodyM().copyWith(
                      color: AppColors.textWolf,
                    ),
                  ),
                )
              : Column(
                  key: ValueKey('rows-$_direction'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: DashboardBottleRow.spaced([
                    for (final b in rows) _row(b),
                  ]),
                ),
        ),
        if (rows.isNotEmpty && widget.onSeeAll != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: widget.onSeeAll,
              child: Text(
                'See all',
                style: AppTextStyles.bodyS().copyWith(
                  color: AppColors.goldBright,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(BluebookModel b) {
    return DashboardBottleRow(
      name: b.bottleName,
      imageUrls: [?AppImageUrl.resolve(b.image)],
      heroId: widget.heroIds.contains(b.id) ? b.id : null,
      price: (double.tryParse(b.average ?? '') ?? 0) > 0
          ? PriceFormatter.format(b.average)
          : null,
      change: b.market?.changeOver(widget.windowDays),
      caption: null,
      sparkline: widget.sparklines[b.id],
      onTap: () {
        widget.onOpen(b.id);
        Get.toNamed(
          AppRoutes.benchmarkDetail,
          arguments: BenchmarkDetailRouteArgs.mapFromBluebook(b),
        );
      },
    );
  }
}
