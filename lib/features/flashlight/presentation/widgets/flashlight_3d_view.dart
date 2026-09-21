import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animation/flicker.dart';
import '../../application/flashlight_model_provider.dart';
import 'flashlight_scene_painter.dart';

class Flashlight3DView extends ConsumerStatefulWidget {
  const Flashlight3DView({
    super.key,
    required this.isOn,
    this.onTap,
    this.height = 300,
  });

  final bool isOn;
  final VoidCallback? onTap;
  final double height;

  @override
  ConsumerState<Flashlight3DView> createState() => _Flashlight3DViewState();
}

class _Flashlight3DViewState extends ConsumerState<Flashlight3DView>
    with TickerProviderStateMixin {
  static const _defaultYaw = -0.55;
  static const _defaultPitch = 0.32;

  late final _power = AnimationController(
    vsync: this,
    duration: bulbFlickerDuration,
    value: widget.isOn ? 1 : 0,
  );
  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  bool _turningOn = true;
  double _yaw = _defaultYaw;
  double _pitch = _defaultPitch;

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  double get _powerValue =>
      _turningOn ? bulbFlicker.transform(_power.value) : _power.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Flashlight3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOn == oldWidget.isOn) return;
    _turningOn = widget.isOn;
    if (_reduceMotion) {
      _power.value = widget.isOn ? 1 : 0;
    } else if (widget.isOn) {
      _power.forward(from: 0);
    } else {
      _power.animateTo(0, duration: const Duration(milliseconds: 180));
    }
  }

  @override
  void dispose() {
    _power.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(flashlightModelProvider);
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: model.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Icon(Icons.flashlight_on)),
        data: (mesh) => Semantics(
          button: true,
          label: widget.isOn ? 'Matikan senter' : 'Nyalakan senter',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onPanUpdate: (details) => setState(() {
              _yaw += details.delta.dx * 0.01;
              _pitch = (_pitch + details.delta.dy * 0.01).clamp(-1.2, 1.2);
            }),
            child: AnimatedBuilder(
              animation: Listenable.merge([_power, _idle]),
              builder: (context, _) {
                final phase = _idle.value * 2 * math.pi;
                return CustomPaint(
                  size: Size.infinite,
                  painter: FlashlightScenePainter(
                    mesh: mesh,
                    power: _powerValue,
                    yaw: _yaw + math.sin(phase) * 0.08,
                    pitch: _pitch + math.sin(phase * 2) * 0.03,
                    hover: math.sin(phase * 2) * 0.05,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
