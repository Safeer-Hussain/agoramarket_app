import 'package:latlong2/latlong.dart';

import '../../domain/entities/spatial_cluster.dart';
import '../../domain/entities/tech_corridor.dart';
import '../../domain/entities/video_pitch.dart';

class GeospatialClusterer {
  static const double clusterThresholdZoom = 13.5;
  static const Distance _distance = Distance();

  /// Clusters pitches according to the current map zoom level.
  /// When zoom >= clusterThresholdZoom, pitches are rendered individually (1 per cluster).
  /// When zoom < clusterThresholdZoom, pitches inside corridors or within proximity are grouped into clusters.
  static List<SpatialCluster> clusterPitches({
    required List<VideoPitch> pitches,
    required double zoom,
    List<TechCorridor> corridors = TechCorridor.corridors,
    TechCorridor? selectedCorridor,
  }) {
    if (pitches.isEmpty) return const [];

    List<VideoPitch> candidatePitches = pitches;
    if (selectedCorridor != null) {
      candidatePitches = pitches
          .where(
            (p) => selectedCorridor.contains(LatLng(p.latitude, p.longitude)),
          )
          .toList();
    }

    if (zoom >= clusterThresholdZoom) {
      return candidatePitches.map((pitch) {
        final loc = LatLng(pitch.latitude, pitch.longitude);
        TechCorridor? matchedCorridor;
        for (final c in corridors) {
          if (c.contains(loc)) {
            matchedCorridor = c;
            break;
          }
        }
        return SpatialCluster(
          center: loc,
          pitches: [pitch],
          corridor: matchedCorridor,
        );
      }).toList();
    }

    final List<SpatialCluster> result = [];
    final Set<String> assignedPitchIds = {};

    for (final corridor in corridors) {
      final corridorPitches = <VideoPitch>[];
      for (final pitch in candidatePitches) {
        if (!assignedPitchIds.contains(pitch.id)) {
          if (corridor.contains(LatLng(pitch.latitude, pitch.longitude))) {
            corridorPitches.add(pitch);
            assignedPitchIds.add(pitch.id);
          }
        }
      }

      if (corridorPitches.isNotEmpty) {
        double sumLat = 0.0;
        double sumLng = 0.0;
        for (final p in corridorPitches) {
          sumLat += p.latitude;
          sumLng += p.longitude;
        }
        final centroid = LatLng(
          sumLat / corridorPitches.length,
          sumLng / corridorPitches.length,
        );

        result.add(
          SpatialCluster(
            center: corridorPitches.length == 1
                ? LatLng(
                    corridorPitches.first.latitude,
                    corridorPitches.first.longitude,
                  )
                : centroid,
            pitches: corridorPitches,
            corridor: corridor,
          ),
        );
      }
    }

    final unassigned = candidatePitches
        .where((p) => !assignedPitchIds.contains(p.id))
        .toList();
    final double proximityMeters = zoom < 11.0 ? 3500.0 : 2000.0;

    final List<List<VideoPitch>> proximityGroups = [];
    for (final pitch in unassigned) {
      final pitchLoc = LatLng(pitch.latitude, pitch.longitude);
      bool added = false;
      for (final group in proximityGroups) {
        final groupLoc = LatLng(group.first.latitude, group.first.longitude);
        if (_distance.as(LengthUnit.Meter, pitchLoc, groupLoc) <=
            proximityMeters) {
          group.add(pitch);
          added = true;
          break;
        }
      }
      if (!added) {
        proximityGroups.add([pitch]);
      }
    }

    for (final group in proximityGroups) {
      if (group.length == 1) {
        result.add(
          SpatialCluster(
            center: LatLng(group.first.latitude, group.first.longitude),
            pitches: group,
            corridor: null,
          ),
        );
      } else {
        double sLat = 0.0;
        double sLng = 0.0;
        for (final p in group) {
          sLat += p.latitude;
          sLng += p.longitude;
        }
        result.add(
          SpatialCluster(
            center: LatLng(sLat / group.length, sLng / group.length),
            pitches: group,
            corridor: null,
          ),
        );
      }
    }

    return result;
  }
}
