import 'package:flutter/material.dart';

import '../../../../core/animation/flicker.dart';
import '../../../../core/theme/app_theme.dart';

class AmbientGlow extends StatefulWidget {
  const AmbientGlow({super.key, required this.isOn, required this.child});

  final bool isOn;
  final Widget child;

  @override
  State<AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<AmbientGlow>
    with TickerProviderStateMixin {
  late final _flicker = AnimationController(
    vsync: this,
    duration: bulbFlickerDuration,
  );
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  @override
  void didUpdateWidget(covariant AmbientGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOn == oldWidget.isOn) return;
    if (widget.isOn) {
      if (_reduceMotion) {
        _flicker.value = 1;
        return;
      }
      _flicker.forward(from: 0).whenComplete(() {
        if (mounted && widget.isOn) _breath.repeat(reverse: true);
      });
    } else {
      _breath.stop();
      _flicker.reverse();
    }
  }

  @override
  void dispose() {
    _flicker.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flicker, _breath]),
      child: widget.child,
      builder: (context, child) {
        final intensity =
            bulbFlicker.transform(_flicker.value) *
            (0.85 + 0.15 * _breath.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.9 + 0.5 * intensity,
              colors: [
                Color.lerp(
                  AppColors.surface,
                  AppColors.gold.withValues(alpha: 0.45),
                  intensity,
                )!,
                AppColors.background,
              ],
            ),
          ),
          child: child,
        );
      },
    );
  }
}
