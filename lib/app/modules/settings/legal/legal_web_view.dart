import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/settings_scaffold.dart';

class LegalWebView extends StatefulWidget {
  const LegalWebView({super.key});

  @override
  State<LegalWebView> createState() => _LegalWebViewState();
}

class _LegalWebViewState extends State<LegalWebView> {
  late final WebViewController _controller;
  late final String _pageTitle;
  var _loading = true;
  var _progress = 0.0;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _pageTitle =
        args is Map ? args['title']?.toString() ?? 'Document' : 'Document';
    final url = args is Map ? args['url']?.toString() ?? '' : '';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.surfaceDeep)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (!mounted) return;
            setState(() {
              _progress = p / 100;
              _loading = p < 100;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
        ),
      );

    if (url.isNotEmpty) {
      _controller.loadRequest(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: _pageTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              minHeight: 2,
              backgroundColor: AppColors.surfaceChip,
              color: AppColors.goldBright,
            ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: kSettingsCardBorder),
                  color: AppColors.panel,
                ),
                child: WebViewWidget(controller: _controller),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
