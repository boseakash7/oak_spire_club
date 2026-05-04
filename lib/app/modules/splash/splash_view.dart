import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';

/// Same background art as sign-in; centered brand icon only ([AppAssets.appIc]).
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  static const double _logoSize = 132;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.signInBackground, fit: BoxFit.cover),
          Center(
            child: Image.asset(
              AppAssets.appIc,
              width: _logoSize,
              height: _logoSize,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
