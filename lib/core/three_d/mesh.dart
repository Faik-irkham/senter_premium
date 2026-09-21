import 'dart:typed_data';

import 'vec3.dart';

class Mesh {
  Mesh({
    required this.positions,
    required this.normals,
    required this.materials,
    required this.materialNames,
  }) : assert(positions.length == materials.length * 9),
       assert(normals.length == materials.length * 9);

  final Float32List positions;
  final Float32List normals;
  final Uint16List materials;
  final List<String> materialNames;

  int get triangleCount => materials.length;

  Vec3 position(int triangle, int corner) {
    final i = triangle * 9 + corner * 3;
    return Vec3(positions[i], positions[i + 1], positions[i + 2]);
  }

  Vec3 normal(int triangle, int corner) {
    final i = triangle * 9 + corner * 3;
    return Vec3(normals[i], normals[i + 1], normals[i + 2]);
  }
}
