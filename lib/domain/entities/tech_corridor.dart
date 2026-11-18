import 'package:latlong2/latlong.dart';

class TechCorridor {
  final String id;
  final String name;
  final LatLng center;
  final double radiusMeters;
  final String tagline;

  const TechCorridor({
    required this.id,
    required this.name,
    required this.center,
    required this.radiusMeters,
    required this.tagline,
  });

  bool contains(LatLng point) {
    const distance = Distance();
    final distInMeters = distance.as(LengthUnit.Meter, center, point);
    return distInMeters <= radiusMeters;
  }

  static const List<TechCorridor> corridors = [
    TechCorridor(
      id: 'corridor_gulberg',
      name: 'Gulberg Main Blvd Tech Hub',
      center: LatLng(31.5204, 74.3587),
      radiusMeters: 1800.0,
      tagline: 'Mobile Architecture & 120FPS Flutter Hub',
    ),
    TechCorridor(
      id: 'corridor_arfa',
      name: 'Arfa Software Technology Park',
      center: LatLng(31.4764, 74.3435),
      radiusMeters: 1200.0,
      tagline: 'Enterprise Cloud & Distributed Systems Corridor',
    ),
    TechCorridor(
      id: 'corridor_dha',
      name: 'DHA Phase 5 Innovation Center',
      center: LatLng(31.4697, 74.4084),
      radiusMeters: 1500.0,
      tagline: 'Fintech UX & Design Systems Zone',
    ),
    TechCorridor(
      id: 'corridor_itpark',
      name: 'Lahore IT Park (Johar Town)',
      center: LatLng(31.4697, 74.2728),
      radiusMeters: 1600.0,
      tagline: 'High-Concurrency DevOps & Infrastructure Corridor',
    ),
  ];
}
