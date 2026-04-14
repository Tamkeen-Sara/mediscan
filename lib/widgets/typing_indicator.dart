import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: AppDimensions.typingDotDuration),
      ),
    );
    _anims = _controllers
        .map((c) => Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.bubblePaddingH,
          vertical: AppDimensions.bubblePaddingV,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusMD),
            topRight: Radius.circular(AppDimensions.radiusMD),
            bottomRight: Radius.circular(AppDimensions.radiusMD),
            bottomLeft: Radius.circular(AppDimensions.radiusXS),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _anims[i],
              builder: (_, __) => Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.typingDotSpacing / 2),
                width: AppDimensions.typingDotSize,
                height: AppDimensions.typingDotSize +
                    _anims[i].value * 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(
                      alpha: 0.5 + 0.5 * _anims[i].value),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
