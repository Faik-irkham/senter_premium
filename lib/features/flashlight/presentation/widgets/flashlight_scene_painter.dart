import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/three_d/mesh.dart';
import '../../../../core/three_d/mesh_builder.dart';
import '../../../../core/three_d/renderer.dart';
import '../../../../core/three_d/shading.dart';
import '../../../../core/three_d/vec3.dart';

const _lensX = 0.90;
const _lensRadius = 0.365;
const _beamLength = 5.6;

const _pivot = Vec3(-0.12, 0, 0);

const _materials = <String, SurfaceMaterial>{
  'body': SurfaceMaterial(
    color: Color(0xFF2A2A33),
    specular: 0.45,
    shininess: 40,
  ),
  'grip': SurfaceMaterial(
    color: Color(0xFF1C1C22),
    specular: 0.2,
    shininess: 16,
  ),
  'head': SurfaceMaterial(
    color: Color(0xFF30303B),
    specular: 0.6,
    shininess: 50,
  ),
  'gold': SurfaceMaterial(
    color: Color(0xFFD9AE48),
    specular: 0.9,
    shininess: 60,
    metallic: true,
  ),
  'reflector': SurfaceMaterial(
    color: Color(0xFFC8CCD4),
    specular: 0.9,
    shininess: 70,
    metallic: true,
  ),
  'lens': SurfaceMaterial(color: Color(0xFF3A4656), specular: 1, shininess: 90),
  'button': SurfaceMaterial(
    color: Color(0xFF9A2222),
    specular: 0.3,
    shininess: 20,
  ),
};
const _fallbackMaterial = SurfaceMaterial(color: Color(0xFF808080));

final Mesh _beamMesh =
    (MeshBuilder()..lathe([
          for (var i = 0; i <= 8; i++)
            ProfilePoint(
              _lensX + _beamLength * i / 8,
              _lensRadius + 1.9 * i / 8,
              'beam',
            ),
        ], segments: 40))
        .build();

class FlashlightScenePainter extends CustomPainter {
  FlashlightScenePainter({
    required this.mesh,
    required this.power,
    required this.yaw,
    required this.pitch,
    this.hover = 0,
  }) : _surfaces = [
         for (final name in mesh.materialNames)
           _materials[name] ?? _fallbackMaterial,
       ],
       _lensIndex = mesh.materialNames.indexOf('lens'),
       _reflectorIndex = mesh.materialNames.indexOf('reflector');

  final Mesh mesh;

  final double power;
  final double yaw;
  final double pitch;

  final double hover;

  final List<SurfaceMaterial> _surfaces;
  final int _lensIndex;
  final int _reflectorIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const modelLength = 2.15;
    const distance = 6.0;
    final fit = math.min(size.width * 0.6, size.height * 1.1);
    final renderer = Renderer3D(
      origin: Offset(size.width * 0.38, size.height * 0.5),
      focal: fit * distance / modelLength,
      distance: distance,
      yaw: yaw,
      pitch: pitch,
      pivot: _pivot,
      offset: Vec3(0, hover, 0),
    );

    _paintShadow(canvas, renderer);

    final towardCamera = _towardCamera(renderer);
    Color beamShader(Vec3 model, Vec3 view, Vec3 normal, int _) =>
        _beamColor(model, view, normal, towardCamera, renderer);

    if (power > 0.01) {
      renderer.drawMesh(
        canvas,
        _beamMesh,
        shader: beamShader,
        cull: false,
        include: (depth) => depth < 0,
        blendMode: BlendMode.screen,
      );
    }

    final lighting = StudioLighting(
      rimColor: Color.lerp(Colors.white, AppColors.gold, power)!,
    );
    renderer.drawMesh(
      canvas,
      mesh,
      shader: (model, view, normal, material) {
        final shaded = lighting.shade(
          _surfaces[material],
          view,
          normal,
          renderer.cameraPosition,
        );
        if (material == _lensIndex) {
          return Color.lerp(shaded, AppColors.beam, power)!;
        }
        if (material == _reflectorIndex) {
          return Color.lerp(shaded, AppColors.gold, power * 0.8)!;
        }
        return shaded;
      },
    );

    if (power > 0.01) {
      renderer.drawMesh(
        canvas,
        _beamMesh,
        shader: beamShader,
        cull: false,
        include: (depth) => depth >= 0,
        blendMode: BlendMode.screen,
      );
      _paintBloom(canvas, renderer, towardCamera);
    }
  }

  Color _beamColor(
    Vec3 model,
    Vec3 view,
    Vec3 normal,
    double towardCamera,
    Renderer3D renderer,
  ) {
    final t = ((model.x - _lensX) / _beamLength).clamp(0.0, 1.0);
    final falloff = math.pow(1 - t, 2.4);
    final toCamera = (renderer.cameraPosition - view).normalized();
    final facing = math.pow(normal.dot(toCamera).abs(), 2);
    final damping = 1 - 0.85 * towardCamera;
    final alpha = (power * 0.45 * falloff * facing * damping).clamp(0.0, 1.0);
    return AppColors.beam.withValues(alpha: alpha.toDouble());
  }

  double _towardCamera(Renderer3D renderer) {
    final lens = renderer.toView(const Vec3(_lensX, 0, 0));
    final axis = renderer.rotate(const Vec3(1, 0, 0));
    return math.max(
      0.0,
      axis.dot((renderer.cameraPosition - lens).normalized()),
    );
  }

  void _paintShadow(Canvas canvas, Renderer3D renderer) {
    final ground = renderer.project(const Vec3(0, -0.75, 0));
    final width = renderer.scaleAt(0) * 2.3;
    final lift = hover.clamp(-0.1, 0.1);
    canvas.drawOval(
      Rect.fromCenter(
        center: ground,
        width: width * (1 - lift),
        height: width * 0.1,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55 - lift * 2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  void _paintBloom(Canvas canvas, Renderer3D renderer, double facing) {
    final lens = renderer.toView(const Vec3(_lensX + 0.01, 0, 0));
    final center = renderer.project(lens);
    final radius =
        _lensRadius * renderer.scaleAt(lens.z) * (2.2 + 3.5 * facing);
    final strength = power * (0.35 + 0.65 * facing);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            AppColors.beam.withValues(alpha: strength),
            AppColors.gold.withValues(alpha: strength * 0.35),
            AppColors.gold.withValues(alpha: 0),
          ],
          stops: const [0, 0.35, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(FlashlightScenePainter old) =>
      old.mesh != mesh ||
      old.power != power ||
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.hover != hover;
}
