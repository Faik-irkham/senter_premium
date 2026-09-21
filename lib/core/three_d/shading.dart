import 'dart:math' as math;
import 'dart:ui';

import 'vec3.dart';

class SurfaceMaterial {
  const SurfaceMaterial({
    required this.color,
    this.specular = 0.3,
    this.shininess = 24,
    this.metallic = false,
  });

  final Color color;

  final double specular;
  final double shininess;

  final bool metallic;
}

class StudioLighting {
  const StudioLighting({
    this.key = const Vec3(-0.45, 0.75, 0.55),
    this.fill = const Vec3(0.8, -0.2, 0.45),
    this.ambient = 0.16,
    this.keyStrength = 0.9,
    this.fillStrength = 0.25,
    this.rimStrength = 0.45,
    this.rimColor = const Color(0xFFFFFFFF),
  });

  final Vec3 key;
  final Vec3 fill;
  final double ambient;
  final double keyStrength;
  final double fillStrength;
  final double rimStrength;
  final Color rimColor;

  Color shade(SurfaceMaterial material, Vec3 view, Vec3 normal, Vec3 camera) {
    final toCamera = (camera - view).normalized();
    final keyDir = key.normalized();
    final fillDir = fill.normalized();

    final diffuse =
        ambient +
        keyStrength * math.max(0, normal.dot(keyDir)) +
        fillStrength * math.max(0, normal.dot(fillDir));

    final half = (keyDir + toCamera).normalized();
    final spec =
        material.specular *
        math.pow(math.max(0, normal.dot(half)), material.shininess);

    final rim =
        rimStrength * math.pow(1 - math.max(0, normal.dot(toCamera)), 3);

    final base = material.color;
    final specColor = material.metallic ? base : const Color(0xFFFFFFFF);

    double channel(double b, double s, double r) =>
        (b * diffuse + s * spec + r * rim).clamp(0.0, 1.0);

    return Color.from(
      alpha: 1,
      red: channel(base.r, specColor.r, rimColor.r),
      green: channel(base.g, specColor.g, rimColor.g),
      blue: channel(base.b, specColor.b, rimColor.b),
    );
  }
}
