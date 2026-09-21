import 'dart:typed_data';

import 'mesh.dart';
import 'vec3.dart';

Mesh parseObj(String source) {
  final positions = <Vec3>[];
  final normals = <Vec3>[];
  final outPositions = <double>[];
  final outNormals = <double>[];
  final outMaterials = <int>[];
  final materialNames = <String>['default'];
  var currentMaterial = 0;

  int resolve(String token, int count) {
    final i = int.parse(token);
    return i < 0 ? count + i : i - 1;
  }

  for (final rawLine in source.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split(RegExp(r'\s+'));
    switch (parts.first) {
      case 'v':
        positions.add(
          Vec3(
            double.parse(parts[1]),
            double.parse(parts[2]),
            double.parse(parts[3]),
          ),
        );
      case 'vn':
        normals.add(
          Vec3(
            double.parse(parts[1]),
            double.parse(parts[2]),
            double.parse(parts[3]),
          ),
        );
      case 'usemtl':
        final name = parts.length > 1 ? parts[1] : 'default';
        var index = materialNames.indexOf(name);
        if (index < 0) {
          materialNames.add(name);
          index = materialNames.length - 1;
        }
        currentMaterial = index;
      case 'f':
        final corners = <(Vec3, Vec3?)>[];
        for (final token in parts.skip(1)) {
          final refs = token.split('/');
          final p = positions[resolve(refs[0], positions.length)];
          final n = refs.length > 2 && refs[2].isNotEmpty
              ? normals[resolve(refs[2], normals.length)]
              : null;
          corners.add((p, n));
        }
        for (var i = 1; i < corners.length - 1; i++) {
          final tri = [corners[0], corners[i], corners[i + 1]];
          final flat = (tri[1].$1 - tri[0].$1)
              .cross(tri[2].$1 - tri[0].$1)
              .normalized();
          for (final (p, n) in tri) {
            final normal = n ?? flat;
            outPositions.addAll([p.x, p.y, p.z]);
            outNormals.addAll([normal.x, normal.y, normal.z]);
          }
          outMaterials.add(currentMaterial);
        }
    }
  }

  return Mesh(
    positions: Float32List.fromList(outPositions),
    normals: Float32List.fromList(outNormals),
    materials: Uint16List.fromList(outMaterials),
    materialNames: List.unmodifiable(materialNames),
  );
}

String writeObj(Mesh mesh, {String? header}) {
  final out = StringBuffer();
  if (header != null) {
    for (final line in header.split('\n')) {
      out.writeln('# $line');
    }
  }

  final vIndex = <String, int>{};
  final nIndex = <String, int>{};
  final vLines = StringBuffer();
  final nLines = StringBuffer();
  final faceLines = StringBuffer();
  String key(Vec3 v) =>
      '${v.x.toStringAsFixed(4)} ${v.y.toStringAsFixed(4)} '
      '${v.z.toStringAsFixed(4)}';

  int indexOf(Map<String, int> map, StringBuffer lines, String prefix, Vec3 v) {
    final k = key(v);
    return map.putIfAbsent(k, () {
      lines.writeln('$prefix $k');
      return map.length + 1;
    });
  }

  int? lastMaterial;
  for (var t = 0; t < mesh.triangleCount; t++) {
    final material = mesh.materials[t];
    if (material != lastMaterial) {
      faceLines.writeln('usemtl ${mesh.materialNames[material]}');
      lastMaterial = material;
    }
    final refs = [
      for (var c = 0; c < 3; c++)
        '${indexOf(vIndex, vLines, 'v', mesh.position(t, c))}'
            '//${indexOf(nIndex, nLines, 'vn', mesh.normal(t, c))}',
    ];
    faceLines.writeln('f ${refs.join(' ')}');
  }

  out
    ..write(vLines)
    ..write(nLines)
    ..write(faceLines);
  return out.toString();
}
