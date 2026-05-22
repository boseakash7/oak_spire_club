import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/animated_list_entrance.dart';
import '../widgets/settings_scaffold.dart';
import '../widgets/settings_toggle_row.dart';
import 'notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Notifications',
      child: Obx(() {
        final p = controller.prefs.value;
        final masterOn = p.pushEnabled;
        final togglesEnabled = !controller.isSaving.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose which alerts you receive. Toggles subscribe to push topics on this device.',
              style: AppTextStyles.body16().copyWith(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            const SettingsSectionLabel('General'),
            SettingsToggleCard(
              rows: [
                SettingsToggleRow(
                  title: 'Push notifications',
                  subtitle: 'Master switch for app alerts on this device',
                  value: p.pushEnabled,
                  enabled: togglesEnabled,
                  onChanged: controller.setPushEnabled,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsSectionLabel('Collection & market'),
            SettingsToggleCard(
              rows: [
                SettingsToggleRow(
                  title: 'Collection value',
                  subtitle: 'Updates when your collection total changes',
                  value: p.collectionAlerts,
                  enabled: masterOn && togglesEnabled,
                  onChanged: controller.setCollectionAlerts,
                ),
                SettingsToggleRow(
                  title: 'Market & benchmarks',
                  subtitle: 'Benchmark moves and market list changes',
                  value: p.marketBenchmarkAlerts,
                  enabled: masterOn && togglesEnabled,
                  onChanged: controller.setMarketBenchmarkAlerts,
                ),
                SettingsToggleRow(
                  title: 'Price movement',
                  subtitle: 'Top movers and significant bottle price shifts',
                  value: p.priceMovementAlerts,
                  enabled: masterOn && togglesEnabled,
                  onChanged: controller.setPriceMovementAlerts,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SettingsSectionLabel('Product'),
            SettingsToggleCard(
              rows: [
                SettingsToggleRow(
                  title: 'Tips & updates',
                  subtitle: 'New features, tasting content, and club news',
                  value: p.productUpdates,
                  enabled: masterOn && togglesEnabled,
                  onChanged: controller.setProductUpdates,
                ),
              ],
            ),
            if (!masterOn) ...[
              const SizedBox(height: 16),
              Text(
                'Turn on push notifications to configure individual alert types.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body16().copyWith(
                  fontSize: 12,
                  color: AppColors.textWolf,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
