import 'package:flutter/material.dart';

import '../animations/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// The bottle search box (market, taste): a gold glow while focused, a
/// clear button that pops in once there is text, and an optional thin
/// progress line while results load.
///
/// The screen's controller owns [controller], so it can clear or prefill the
/// query (e.g. an empty state's "Clear search") and the field follows.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search bottles',
    this.busy = false,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  /// Shows a thin gold progress line under the field.
  final bool busy;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;
    final duration = AppMotion.of(context, AppMotion.fast);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: duration,
          curve: AppMotion.standard,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: focused ? AppColors.gold2 : AppColors.border,
              width: focused ? 1.2 : 1,
            ),
            boxShadow: focused
                ? const [BoxShadow(color: AppColors.goldGlow, blurRadius: 16)]
                : const [],
          ),
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.sm),
              AnimatedSwitcher(
                duration: duration,
                child: Icon(
                  Icons.search_rounded,
                  key: ValueKey(focused),
                  size: 20,
                  color: focused ? AppColors.gold2 : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  onChanged: widget.onChanged,
                  onTapOutside: (_) => _focus.unfocus(),
                  textInputAction: TextInputAction.search,
                  style: AppTextStyles.bodyL().copyWith(color: AppColors.white),
                  cursorColor: AppColors.gold2,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: AppTextStyles.bodyL().copyWith(
                      color: AppColors.textMuted,
                    ),
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              AnimatedScale(
                scale: hasText ? 1 : 0,
                duration: duration,
                curve: hasText ? AppMotion.emphasized : AppMotion.exit,
                child: IconButton(
                  tooltip: 'Clear search',
                  onPressed: hasText ? _clear : null,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 2,
          child: AnimatedOpacity(
            opacity: widget.busy ? 1 : 0,
            duration: duration,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppRadii.md),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
