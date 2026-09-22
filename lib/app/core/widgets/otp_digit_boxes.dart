import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animations/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Animated 4-digit OTP boxes used across auth flows.
class OtpDigitBoxes extends StatelessWidget {
  const OtpDigitBoxes({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onBackspace,
    this.length = 4,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final void Function(int index) onBackspace;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
        (i) => Padding(
          padding: EdgeInsets.only(right: i < length - 1 ? 16 : 0),
          child: _OtpBox(
            controller: controllers[i],
            focusNode: focusNodes[i],
            onChanged: (v) => onChanged(i, v),
            onBackspace: () => onBackspace(i),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatefulWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final FocusNode _keyboardFocusNode;
  bool _focused = false;
  bool _detached = false;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    _anim = AnimationController(vsync: this, duration: AppMotion.medium);
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _anim, curve: AppMotion.standard),
    );
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  void _onTextChange() {
    if (_detached || !mounted) return;
    setState(() {});
  }

  void _onFocusChange() {
    if (_detached || !mounted) return;
    final focused = widget.focusNode.hasFocus;
    if (focused == _focused) return;
    _focused = focused;
    if (focused) {
      _anim.forward();
    } else {
      _anim.reverse();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _detached = true;
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _anim.stop();
    _anim.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.isNotEmpty;
    final borderColor = _focused ? const Color(0xFFCCA230) : AppColors.border;
    final fillColor = _focused ? const Color(0x1ACCA230) : AppColors.panel;

    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: _focused ? 1.8 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: const Color(0xFFCCA230).withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: KeyboardListener(
          focusNode: _keyboardFocusNode,
          onKeyEvent: (event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace &&
                widget.controller.text.isEmpty) {
              widget.onBackspace();
            }
          },
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            textAlign: TextAlign.center,
            maxLength: 1,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.heading32Bold().copyWith(
              fontSize: 24,
              color: hasValue ? AppColors.white : AppColors.border,
            ),
            cursorColor: const Color(0xFFCCA230),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}
