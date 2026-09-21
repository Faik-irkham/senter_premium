import 'dart:math' as math;
import 'dart:typed_data';

import 'mesh.dart';
import 'vec3.dart';

class ProfilePoint {
  const ProfilePoint(this.x, this.r, this.material);

  final double x;
  final double r;
  final String material;
}

class MeshBuilder {
  final _positions = <double>[];
  final _normals = <double>[];
  final _materials = <int>[];
  final _materialNames = <String>[];

  int _materialIndex(String name) {
    final index = _materialNames.indexOf(name);
    if (index >= 0) return index;
    _materialNames.add(name);
    return _materialNames.length - 1;
  }

  void addTriangle(
    Vec3 a,
    Vec3 b,
    Vec3 c,
    Vec3 na,
    Vec3 nb,
    Vec3 nc,
    String material,
  ) {
    final faceNormal = (b - a).cross(c - a);
    if (faceNormal.length < 1e-9) return;
    if (faceNormal.dot(na + nb + nc) < 0) {
      (b, c) = (c, b);
      (nb, nc) = (nc, nb);
    }
    for (final p in [a, b, c]) {
      _positions.addAll([p.x, p.y, p.z]);
    }
    for (final n in [na, nb, nc]) {
      _normals.addAll([n.x, n.y, n.z]);
    }
    _materials.add(_materialIndex(material));
  }

  void lathe(List<ProfilePoint> profile, {int segments = 48}) {
    for (var i = 0; i < profile.length - 1; i++) {
      final p0 = profile[i];
      final p1 = profile[i + 1];
      final dx = p1.x - p0.x;
      final dr = p1.r - p0.r;
      final len = math.sqrt(dx * dx + dr * dr);
      if (len == 0) continue;
      final nx = -dr / len;
      final nr = dx / len;

      for (var j = 0; j < segments; j++) {
        final a0 = 2 * math.pi * j / segments;
        final a1 = 2 * math.pi * (j + 1) / segments;
        Vec3 ring(double x, double r, double a) =>
            Vec3(x, r * math.cos(a), r * math.sin(a));
        Vec3 normal(double a) => Vec3(nx, nr * math.cos(a), nr * math.sin(a));

        final v00 = ring(p0.x, p0.r, a0);
        final v10 = ring(p1.x, p1.r, a0);
        final v11 = ring(p1.x, p1.r, a1);
        final v01 = ring(p0.x, p0.r, a1);
        final n0 = normal(a0);
        final n1 = normal(a1);
        addTriangle(v00, v10, v11, n0, n0, n1, p0.material);
        addTriangle(v00, v11, v01, n0, n1, n1, p0.material);
      }
    }
  }

  void box(Vec3 min, Vec3 max, String material) {
    Vec3 corner(int i) => Vec3(
      i & 1 == 0 ? min.x : max.x,
      i & 2 == 0 ? min.y : max.y,
      i & 4 == 0 ? min.z : max.z,
    );
    const faces = [
      (Vec3(-1, 0, 0), [0, 2, 6, 4]),
      (Vec3(1, 0, 0), [1, 5, 7, 3]),
      (Vec3(0, -1, 0), [0, 4, 5, 1]),
      (Vec3(0, 1, 0), [2, 3, 7, 6]),
      (Vec3(0, 0, -1), [0, 1, 3, 2]),
      (Vec3(0, 0, 1), [4, 6, 7, 5]),
    ];
    for (final (n, q) in faces) {
      final [a, b, c, d] = [for (final i in q) corner(i)];
      addTriangle(a, b, c, n, n, n, material);
      addTriangle(a, c, d, n, n, n, material);
    }
  }

  Mesh build() => Mesh(
    positions: Float32List.fromList(_positions),
    normals: Float32List.fromList(_normals),
    materials: Uint16List.fromList(_materials),
    materialNames: List.unmodifiable(_materialNames),
  );
}
