import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/three_d/mesh.dart';
import '../../../core/three_d/obj_format.dart';

const flashlightModelAsset = 'assets/models/flashlight.obj';

final flashlightModelProvider = FutureProvider<Mesh>((ref) async {
  final source = await rootBundle.loadString(flashlightModelAsset);
  return compute(parseObj, source);
});
