import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:senter_premium/core/three_d/mesh_builder.dart';
import 'package:senter_premium/core/three_d/obj_format.dart';
import 'package:senter_premium/core/three_d/vec3.dart';

void main() {
  test('box: 12 segitiga, semua menghadap keluar', () {
    final mesh =
        (MeshBuilder()..box(const Vec3(-1, -1, -1), const Vec3(1, 1, 1), 'm'))
            .build();
    expect(mesh.triangleCount, 12);
    for (var t = 0; t < mesh.triangleCount; t++) {
      final a = mesh.position(t, 0);
      final face = (mesh.position(t, 1) - a).cross(mesh.position(t, 2) - a);
      final center = (a + mesh.position(t, 1) + mesh.position(t, 2)) * (1 / 3);
      expect(face.dot(center), greaterThan(0), reason: 'triangle $t');
    }
  });

  test('tulis lalu baca OBJ menghasilkan mesh yang sama', () {
    final original =
        (MeshBuilder()..lathe(const [
              ProfilePoint(0, 0, 'a'),
              ProfilePoint(0, 1, 'a'),
              ProfilePoint(2, 1, 'b'),
              ProfilePoint(2, 0, 'b'),
            ], segments: 12))
            .build();
    final parsed = parseObj(writeObj(original));

    expect(parsed.triangleCount, original.triangleCount);
    expect(parsed.materialNames, containsAll(['a', 'b']));
    for (var i = 0; i < original.positions.length; i++) {
      expect(parsed.positions[i], closeTo(original.positions[i], 1e-3));
    }
  });

  test('face poligon ditriangulasi dan indeks negatif didukung', () {
    final mesh = parseObj('''
v 0 0 0
v 1 0 0
v 1 1 0
v 0 1 0
usemtl kaca
f -4 -3 -2 -1
''');
    expect(mesh.triangleCount, 2);
    expect(mesh.materialNames[mesh.materials.first], 'kaca');
    expect(mesh.normal(0, 0).z, closeTo(1, 1e-9));
  });

  test('asset senter berisi semua material yang dipakai renderer', () {
    final mesh = parseObj(
      File('assets/models/flashlight.obj').readAsStringSync(),
    );
    expect(mesh.triangleCount, greaterThan(1000));
    expect(
      mesh.materialNames,
      containsAll([
        'body',
        'grip',
        'gold',
        'head',
        'reflector',
        'lens',
        'button',
      ]),
    );
  });
}
