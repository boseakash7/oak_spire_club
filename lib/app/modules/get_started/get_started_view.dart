import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/analytics/app_analytics_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../routes/app_routes.dart';

class GetStartedView extends StatelessWidget {
  const GetStartedView({super.key});

  static const double _horizontalPadding = 20;
  static const double _logoSize = 114;
  static const double _topOffset = 28;
  static const double _buttonRadius = 12;

  // Design-matched onboarding palette.
  static const Color _goldAccent = Color(0xFFC59358);
  static const Color _goldLight = Color(0xFFD4A76A);
  static const Color _goldDark = Color(0xFF9B6D3B);
  static const Color _creamTitle = Color(0xFFE8E2D6);
  static const Color _creamBody = Color(0xFFD8D2C6);
  static const Color _featureDescription = Color(0xFFC8C2B6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.onboardingBackground, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.black.withValues(alpha: 0.52),
                  Colors.black.withValues(alpha: 0.78),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: _topOffset),
                      child: Column(
                        children: [
                          Image.asset(
                            AppAssets.appIc,
                            width: _logoSize,
                            height: _logoSize,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          _welcomeHeader(),
                          const SizedBox(height: 8),
                          _featuresRow(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ctaText(),
                  const SizedBox(height: 26),
                  _bottomButtons(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeHeader() {
    final welcomeStyle = GoogleFonts.roboto(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 3.2,
      color: _goldAccent,
    );
    final clubStyle = GoogleFonts.roboto(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 8,
      color: _goldAccent,
    );
    final taglineStyle = GoogleFonts.roboto(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.6,
      height: 1.35,
      color: _goldAccent,
    );
    final titleStyle = GoogleFonts.playfairDisplay(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      height: 1.05,
      letterSpacing: 0.8,
      color: _creamTitle,
    );

    return Column(
      children: [
        Text('WELCOME TO', style: welcomeStyle),
        const SizedBox(height: 4),
        Text('OAK SPIRE', style: titleStyle, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        _ClubTitle(style: clubStyle),
        const SizedBox(height: 10),
        Column(
          children: [
            Text(
              'A COMMUNITY FOR TRUE',
              style: taglineStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'WHISKEY COLLECTORS',
              style: taglineStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _featuresRow() {
    const features = <_OnboardingFeature>[
      _OnboardingFeature(
        icon: AppAssets.onboardingBell,
        title: 'INSTANT\nALERTS',
        description: 'Be first to know about rare releases.',
      ),
      _OnboardingFeature(
        icon: AppAssets.onboardingStat,
        title: 'MARKET\nINSIGHTS',
        description: 'Real-time pricing and market trends.',
      ),
      _OnboardingFeature(
        icon: AppAssets.onboardingBottle,
        title: 'COLLECTION\nMANAGEMENT',
        description: 'Track, organize and value your collection.',
      ),
      _OnboardingFeature(
        icon: AppAssets.onboardingGroup,
        title: 'EXCLUSIVE\nCOMMUNITY',
        description: 'Connect with fellow whiskey enthusiasts.',
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: _goldAccent.withValues(alpha: 0.28),
              ),
            Expanded(child: _FeatureColumn(feature: features[i])),
          ],
        ],
      ),
    );
  }

  Widget _ctaText() {
    return Text(
      'Join an exclusive members-only community and elevate your whiskey journey.',
      textAlign: TextAlign.center,
      style: GoogleFonts.roboto(
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: _creamBody,
      ),
    );
  }

  Widget _bottomButtons(BuildContext context) {
    return Column(
      children: [
        _GoldPillButton(
          label: 'Sign Up',
          filled: true,
          onPressed: () {
            if (Get.isRegistered<AppAnalyticsController>()) {
              unawaited(
                AppAnalyticsController.to.logTap('get_started_sign_up'),
              );
            }
            Get.toNamed(AppRoutes.signUp);
          },
        ),
        const SizedBox(height: 16),
        _GoldPillButton(
          label: 'Log In',
          filled: false,
          borderColor: AppColors.border,
          textColor: AppColors.textCream,
          onPressed: () {
            if (Get.isRegistered<AppAnalyticsController>()) {
              unawaited(
                AppAnalyticsController.to.logTap('get_started_log_in'),
              );
            }
            Get.toNamed(AppRoutes.signIn);
          },
        ),
      ],
    );
  }
}

class _ClubTitle extends StatelessWidget {
  const _ClubTitle({required this.style});

  final TextStyle style;

  static const double _sideGap = 10;

  @override
  Widget build(BuildContext context) {
    final clubWidth = _measureTextWidth('CLUB', style);
    final sideLineWidth = clubWidth * 0.9;
    final bottomLineWidth = clubWidth * 0.55;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _TaperedGoldLine(
              width: sideLineWidth,
              style: _TaperedLineStyle.sideLeft,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _sideGap),
              child: Text('CLUB', style: style),
            ),
            _TaperedGoldLine(
              width: sideLineWidth,
              style: _TaperedLineStyle.sideRight,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _TaperedGoldLine(
          width: bottomLineWidth,
          style: _TaperedLineStyle.center,
          maxThickness: 1.6,
        ),
      ],
    );
  }

  double _measureTextWidth(String text, TextStyle textStyle) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}

enum _TaperedLineStyle { sideLeft, sideRight, center }

class _TaperedGoldLine extends StatelessWidget {
  const _TaperedGoldLine({
    required this.width,
    required this.style,
    this.maxThickness = 2.2,
  });

  final double width;
  final _TaperedLineStyle style;
  final double maxThickness;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, maxThickness + 1),
      painter: _TaperedGoldLinePainter(
        style: style,
        maxThickness: maxThickness,
      ),
    );
  }
}

class _TaperedGoldLinePainter extends CustomPainter {
  const _TaperedGoldLinePainter({
    required this.style,
    required this.maxThickness,
  });

  final _TaperedLineStyle style;
  final double maxThickness;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final centerY = size.height / 2;
    final w = size.width;
    final h = maxThickness;

    switch (style) {
      case _TaperedLineStyle.sideLeft:
        path
          ..moveTo(0, centerY)
          ..lineTo(w * 0.88, centerY - h / 2)
          ..lineTo(w, centerY)
          ..lineTo(w * 0.88, centerY + h / 2)
          ..close();
      case _TaperedLineStyle.sideRight:
        path
          ..moveTo(w, centerY)
          ..lineTo(w * 0.12, centerY - h / 2)
          ..lineTo(0, centerY)
          ..lineTo(w * 0.12, centerY + h / 2)
          ..close();
      case _TaperedLineStyle.center:
        path
          ..moveTo(0, centerY)
          ..lineTo(w * 0.5, centerY - h / 2)
          ..lineTo(w, centerY)
          ..lineTo(w * 0.5, centerY + h / 2)
          ..close();
    }

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF9B6D3B),
          Color(0xFFD4A76A),
          Color(0xFFC59358),
          Color(0xFFD4A76A),
          Color(0xFF9B6D3B),
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TaperedGoldLinePainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.maxThickness != maxThickness;
  }
}

class _OnboardingFeature {
  const _OnboardingFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final String icon;
  final String title;
  final String description;
}

class _FeatureColumn extends StatelessWidget {
  const _FeatureColumn({required this.feature});

  final _OnboardingFeature feature;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.roboto(
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.15,
      color: GetStartedView._goldAccent,
    );
    final descriptionStyle = GoogleFonts.roboto(
      fontSize: 9,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: GetStartedView._featureDescription,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Image.asset(
            feature.icon,
            width: 56,
            height: 56,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            feature.title,
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            feature.description,
            style: descriptionStyle,
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

class _GoldPillButton extends StatefulWidget {
  const _GoldPillButton({
    required this.label,
    required this.filled,
    required this.onPressed,
    this.borderColor,
    this.textColor,
  });

  final String label;
  final bool filled;
  final VoidCallback onPressed;
  final Color? borderColor;
  final Color? textColor;

  @override
  State<_GoldPillButton> createState() => _GoldPillButtonState();
}

class _GoldPillButtonState extends State<_GoldPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.filled ? AppColors.goldGradient : null,
            color: widget.filled ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(GetStartedView._buttonRadius),
            border: widget.filled
                ? null
                : Border.all(
                    color: widget.borderColor ?? GetStartedView._goldAccent,
                    width: 1.1,
                  ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(GetStartedView._buttonRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(GetStartedView._buttonRadius),
              onTap: widget.onPressed,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              child: Center(
                child: Text(
                  widget.label,
                  style: AppTextStyles.button20Bold().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.filled
                        ? const Color(0xFF1A1208)
                        : (widget.textColor ?? GetStartedView._goldAccent),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
