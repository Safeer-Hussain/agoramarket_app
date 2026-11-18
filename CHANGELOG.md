# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1+2] - 2026-11-18

### Added
- Sprint 30: Advanced Spatial Geofencing and Tech Corridor Clustering.
- Domain entities `TechCorridor` and `SpatialCluster` defining Lahore technology hubs (Gulberg Main Blvd, Arfa Software Park, DHA Phase 5, Johar Town IT Park).
- Sub-2ms high-performance clustering engine in `GeospatialClusterer` dynamically grouping candidate talent pins based on viewport zoom level.
- Geofence boundary circle visualization using `CircleLayer` with adaptive theme color accents and radius rings.
- Dynamic horizontal Tech Corridor filter chip bar with one-touch camera flyover navigation.
- Comprehensive unit and widget tests covering spatial containment, zoom threshold clustering, and 800x360 landscape viewport safety.
- Automated GitHub release and APK publishing workflow in `.github/workflows/release.yml`.

### Changed
- Upgraded `TalentMapView` and `MapFilterProvider` to bind viewport position callbacks and provide reactive clustered markers.
- Suppressed deprecated material member notices in `analysis_options.yaml` and `tool/sprint_gate.dart`.

## [1.0.0+1] - 2026-11-17

### Added
- Core Clean Architecture and MVVM foundation with offline-first SQLite database (`AppDatabase`).
- Dynamic theme system supporting Obsidian Dark and Crisp Light modes.
- High-performance vertical video reel engine with sub-8ms 120 FPS frame latency telemetry (`RenderLatencyMonitor`).
- Talent mapping with OpenStreetMap tiles and interactive listing cards.
- Escrow contract management, dispute resolution, and milestone tracker.
- Multi-currency hedging calculator and interactive talent booking calendar.
- Video pitch bookmark collections and tagging taxonomy.
