import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../constants/app_assets.dart';

/// Toast-style messages with app icon (custom overlay — native toast APIs cannot show an asset icon).
class AppSnackbar {
  AppSnackbar._();

  static const Color _bg = Color(0xE8171210);
  static const Color _textError = Color(0xFFF1E8BE);
  static const Color _textSuccess = Color(0xFFC8E6C9);
  static const Color _textInfo = Color(0xFFE6E6E6);

  static OverlayEntry? _entry;
  static Timer? _hideTimer;

  /// Validation / API failure (default).
  static Future<void> error(String message) => _show(message, _textError);

  /// Optional success line after mutations.
  static Future<void> success(String message) => _show(message, _textSuccess);

  /// Neutral API / info copy.
  static Future<void> info(String message) => _show(message, _textInfo);

  static void _dismissOverlayToast() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _entry?.remove();
    _entry = null;
  }

  static Future<void> _show(String message, Color textColor) async {
    final text = message.trim();
    if (text.isEmpty) return;

    await Fluttertoast.cancel();
    _dismissOverlayToast();

    final overlay = Get.key.currentState?.overlay;
    if (overlay == null || !overlay.mounted) {
      await Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        fontSize: 13,
        backgroundColor: _bg,
        textColor: textColor,
      );
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        // Sit above home-indicator safe area, and above the keyboard when open.
        final bottomGap = 50.0 + mq.padding.bottom + mq.viewInsets.bottom;
        return Positioned(
          left: 24,
          right: 24,
          bottom: bottomGap,
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _AppToastChip(message: text, textColor: textColor),
            ),
          ),
        );
      },
    );

    _entry = entry;
    overlay.insert(entry);

    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (identical(_entry, entry)) {
        entry.remove();
        _entry = null;
        _hideTimer = null;
      }
    });
  }
}

class _AppToastChip extends StatelessWidget {
  const _AppToastChip({required this.message, required this.textColor});

  final String message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width - 72;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW > 0 ? maxW : 280),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppSnackbar._bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  AppAssets.appIc,
                  width: 22,
                  height: 22,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.image_not_supported_outlined,
                    size: 22,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
