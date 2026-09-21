import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'mesh.dart';
import 'vec3.dart';

typedef VertexShader = Color Function(
  Vec3 model,
  Vec3 view,
  Vec3 normal,
  int material,
);

class Renderer3D {
  Renderer3D({
    required this.origin,
    required this.focal,
    this.distance = 6,
    this.nearPlane = 0.5,
    double yaw = 0,
    double pitch = 0,
    this.pivot = Vec3.zero,
    this.offset = Vec3.zero,
  }) : _cy = math.cos(yaw),
       _sy = math.sin(yaw),
       _cp = math.cos(pitch),
       _sp = math.sin(pitch);

  final Offset origin;

  final double focal;
  final double distance;

  final double nearPlane;

  final Vec3 pivot;

  final Vec3 offset;

  final double _cy, _sy, _cp, _sp;

  Vec3 get cameraPosition => Vec3(0, 0, distance);

  Vec3 rotate(Vec3 v) {
    final x1 = v.x * _cy + v.z * _sy;
    final z1 = -v.x * _sy + v.z * _cy;
    final y2 = v.y * _cp - z1 * _sp;
    final z2 = v.y * _sp + z1 * _cp;
    return Vec3(x1, y2, z2);
  }

  Vec3 toView(Vec3 model) => rotate(model - pivot) + offset;

  Offset project(Vec3 view) {
    final s = focal / (distance - view.z);
    return Offset(origin.dx + view.x * s, origin.dy - view.y * s);
  }

  double scaleAt(double viewZ) => focal / (distance - viewZ);

  void drawMesh(
    Canvas canvas,
    Mesh mesh, {
    required VertexShader shader,
    bool cull = true,
    bool Function(double depth)? include,
    BlendMode blendMode = BlendMode.srcOver,
  }) {
    final count = mesh.triangleCount;
    final view = Float32List(count * 9);
    final depths = <(double, int)>[];

    for (var t = 0; t < count; t++) {
      final a = toView(mesh.position(t, 0));
      final b = toView(mesh.position(t, 1));
      final c = toView(mesh.position(t, 2));
      final near = distance - nearPlane;
      if (a.z > near || b.z > near || c.z > near) continue;
      final centroid = (a + b + c) * (1 / 3);
      if (cull) {
        final faceNormal = (b - a).cross(c - a);
        if (faceNormal.dot(cameraPosition - centroid) <= 0) continue;
      }
      if (include != null && !include(centroid.z)) continue;
      final i = t * 9;
      view
        ..[i] = a.x
        ..[i + 1] = a.y
        ..[i + 2] = a.z
        ..[i + 3] = b.x
        ..[i + 4] = b.y
        ..[i + 5] = b.z
        ..[i + 6] = c.x
        ..[i + 7] = c.y
        ..[i + 8] = c.z;
      depths.add((centroid.z, t));
    }
    if (depths.isEmpty) return;

    depths.sort((a, b) => a.$1.compareTo(b.$1));

    final positions = Float32List(depths.length * 6);
    final colors = Int32List(depths.length * 3);
    var k = 0;
    for (final (_, t) in depths) {
      for (var corner = 0; corner < 3; corner++) {
        final i = t * 9 + corner * 3;
        final v = Vec3(view[i], view[i + 1], view[i + 2]);
        final screen = project(v);
        positions[k * 2] = screen.dx;
        positions[k * 2 + 1] = screen.dy;
        colors[k] = shader(
          mesh.position(t, corner),
          v,
          rotate(mesh.normal(t, corner)).normalized(),
          mesh.materials[t],
        ).toARGB32();
        k++;
      }
    }

    canvas.drawVertices(
      Vertices.raw(VertexMode.triangles, positions, colors: colors),
      BlendMode.dst,
      Paint()..blendMode = blendMode,
    );
  }
}
