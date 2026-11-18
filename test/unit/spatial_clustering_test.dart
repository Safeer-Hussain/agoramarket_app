import 'package:agora_market_app/core/utils/geospatial_clusterer.dart';
import 'package:agora_market_app/domain/entities/tech_corridor.dart';
import 'package:agora_market_app/domain/entities/video_pitch.dart';
import 'package:agora_market_app/presentation/map/map_filter_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../mocks/mock_repositories.dart';

void main() {
  group('TechCorridor Entity Unit Tests', () {
    test('contains accurately detects points inside radius', () {
      final gulberg = TechCorridor.corridors.firstWhere(
        (c) => c.id == 'corridor_gulberg',
      );

      // Point right at Gulberg center
      expect(gulberg.contains(const LatLng(31.5204, 74.3587)), isTrue);

      // Point ~200 meters away
      expect(gulberg.contains(const LatLng(31.5220, 74.3590)), isTrue);

      // Point in Johar Town (far away)
      expect(gulberg.contains(const LatLng(31.4697, 74.2728)), isFalse);
    });

    test('All predefined tech corridors have valid centers and radii', () {
      expect(TechCorridor.corridors.length, 4);
      for (final corridor in TechCorridor.corridors) {
        expect(corridor.id.isNotEmpty, isTrue);
        expect(corridor.name.isNotEmpty, isTrue);
        expect(corridor.radiusMeters, greaterThan(500.0));
        expect(corridor.tagline.isNotEmpty, isTrue);
      }
    });
  });

  group('GeospatialClusterer Algorithm Tests', () {
    const p1 = VideoPitch(
      id: 'p1',
      title: 'Gulberg Pitch 1',
      creatorName: 'Talent A',
      creatorAvatar: 'assets/images/avatar_safeer.png',
      role: 'Flutter Lead',
      hourlyRate: 90.0,
      currency: 'USD',
      locationName: 'Gulberg III',
      latitude: 31.5204,
      longitude: 74.3587,
      category: 'Freelancer',
      videoAsset: 'assets/images/thumb_mobile_arch.png',
      thumbnailAsset: 'assets/images/thumb_mobile_arch.png',
      likesCount: 10,
      bookmarksCount: 5,
      isLiked: false,
      isBookmarked: false,
      pitchScript: 'Pitch 1 script',
      skills: ['Flutter'],
      createdAt: '2026-11-01',
    );

    const p2 = VideoPitch(
      id: 'p2',
      title: 'Gulberg Pitch 2',
      creatorName: 'Talent B',
      creatorAvatar: 'assets/images/avatar_bilal.png',
      role: 'Dart Architect',
      hourlyRate: 110.0,
      currency: 'USD',
      locationName: 'Gulberg II',
      latitude: 31.5220,
      longitude: 74.3590,
      category: 'Freelancer',
      videoAsset: 'assets/images/thumb_mobile_arch.png',
      thumbnailAsset: 'assets/images/thumb_mobile_arch.png',
      likesCount: 15,
      bookmarksCount: 8,
      isLiked: false,
      isBookmarked: false,
      pitchScript: 'Pitch 2 script',
      skills: ['Dart'],
      createdAt: '2026-11-01',
    );

    const p3 = VideoPitch(
      id: 'p3',
      title: 'DHA Pitch',
      creatorName: 'Talent C',
      creatorAvatar: 'assets/images/avatar_ayesha.png',
      role: 'UX Designer',
      hourlyRate: 80.0,
      currency: 'USD',
      locationName: 'DHA Phase 5',
      latitude: 31.4697,
      longitude: 74.4084,
      category: 'Freelancer',
      videoAsset: 'assets/images/thumb_ui_ux.png',
      thumbnailAsset: 'assets/images/thumb_ui_ux.png',
      likesCount: 20,
      bookmarksCount: 12,
      isLiked: false,
      isBookmarked: false,
      pitchScript: 'Pitch 3 script',
      skills: ['Figma'],
      createdAt: '2026-11-01',
    );

    test('Clusters multiple pitches within same corridor at zoom < 13.5', () {
      final clusters = GeospatialClusterer.clusterPitches(
        pitches: [p1, p2, p3],
        zoom: 12.0,
      );

      // Should have 2 clusters: Gulberg (with 2 pitches) and DHA (with 1 pitch)
      expect(clusters.length, 2);

      final gulbergCluster = clusters.firstWhere(
        (c) => c.corridor?.id == 'corridor_gulberg',
      );
      expect(gulbergCluster.count, 2);
      expect(gulbergCluster.isCluster, isTrue);
      expect(
        gulbergCluster.pitches.map((p) => p.id),
        containsAll(['p1', 'p2']),
      );

      final dhaCluster = clusters.firstWhere(
        (c) => c.corridor?.id == 'corridor_dha',
      );
      expect(dhaCluster.count, 1);
      expect(dhaCluster.isCluster, isFalse);
    });

    test('Separates all pitches into individual points at zoom >= 13.5', () {
      final clusters = GeospatialClusterer.clusterPitches(
        pitches: [p1, p2, p3],
        zoom: 14.0,
      );

      // At zoom 14.0, every pitch is its own cluster
      expect(clusters.length, 3);
      for (final cluster in clusters) {
        expect(cluster.count, 1);
        expect(cluster.isCluster, isFalse);
      }
    });

    test('Filters clusters strictly when selectedCorridor is specified', () {
      final gulberg = TechCorridor.corridors.firstWhere(
        (c) => c.id == 'corridor_gulberg',
      );

      final clusters = GeospatialClusterer.clusterPitches(
        pitches: [p1, p2, p3],
        zoom: 12.0,
        selectedCorridor: gulberg,
      );

      expect(clusters.length, 1);
      expect(clusters.first.corridor?.id, 'corridor_gulberg');
      expect(clusters.first.count, 2);
    });
  });

  group('MapFilterProvider Tech Corridor Integration Tests', () {
    late MockMarketplaceRepository mockRepo;
    late MapFilterProvider provider;

    setUp(() {
      mockRepo = MockMarketplaceRepository();
      provider = MapFilterProvider(repository: mockRepo);
    });

    test('Selecting corridor filters pitches and updates clusters', () async {
      await provider.loadMapData();
      expect(provider.filteredPitches.length, 3);

      final gulberg = TechCorridor.corridors.firstWhere(
        (c) => c.id == 'corridor_gulberg',
      );
      provider.selectCorridor(gulberg);

      expect(provider.selectedCorridor, gulberg);
      expect(provider.filteredPitches.length, 1);
      expect(provider.filteredPitches.first.locationName, contains('Gulberg'));

      // Selecting null restores all pitches
      provider.selectCorridor(null);
      expect(provider.selectedCorridor, isNull);
      expect(provider.filteredPitches.length, 3);
    });

    test(
      'Setting map zoom level dynamically updates cluster grouping',
      () async {
        await provider.loadMapData();

        provider.setZoom(12.0);
        expect(provider.currentZoom, 12.0);
        final zoomedOutClusters = provider.clusters;
        expect(zoomedOutClusters.isNotEmpty, isTrue);

        provider.setZoom(15.0);
        expect(provider.currentZoom, 15.0);
        final zoomedInClusters = provider.clusters;
        expect(zoomedInClusters.every((c) => !c.isCluster), isTrue);
      },
    );

    test('Recentering resets selected corridor and route', () async {
      await provider.loadMapData();

      final dha = TechCorridor.corridors.firstWhere(
        (c) => c.id == 'corridor_dha',
      );
      provider.selectCorridor(dha);
      provider.toggleRoute();

      expect(provider.selectedCorridor, isNotNull);
      expect(provider.showRoute, isTrue);

      provider.recenterToTechHub();

      expect(provider.selectedCorridor, isNull);
      expect(provider.showRoute, isFalse);
    });
  });
}
