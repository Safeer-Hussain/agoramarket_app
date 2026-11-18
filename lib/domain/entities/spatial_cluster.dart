import 'package:latlong2/latlong.dart';

import 'tech_corridor.dart';
import 'video_pitch.dart';

class SpatialCluster {
  final LatLng center;
  final List<VideoPitch> pitches;
  final TechCorridor? corridor;

  const SpatialCluster({
    required this.center,
    required this.pitches,
    this.corridor,
  });

  int get count => pitches.length;
  bool get isCluster => count > 1;
  VideoPitch get primaryPitch => pitches.first;
}
