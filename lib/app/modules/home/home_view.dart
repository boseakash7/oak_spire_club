import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/animations/state_switcher.dart';
import 'home_controller.dart';
import 'home_filled_view.dart';
import 'home_loading_view.dart';
import 'widgets/home_empty_view.dart';

enum _HomeState { loading, filled, empty }

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.isLoading.value
          ? _HomeState.loading
          : controller.hasCollection.value
          ? _HomeState.filled
          : _HomeState.empty;

      return AppStateSwitcher(
        stateKey: state,
        child: switch (state) {
          _HomeState.loading => const HomeLoadingView(),
          _HomeState.filled => const HomeFilledView(),
          _HomeState.empty => HomeEmptyView(controller: controller),
        },
      );
    });
  }
}
