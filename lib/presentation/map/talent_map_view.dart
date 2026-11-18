import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/tech_corridor.dart';
import '../../domain/entities/video_pitch.dart';
import '../navigation/adaptive_scaffold.dart';
import 'map_filter_provider.dart';
import 'widgets/map_filter_sheet.dart';
import 'widgets/map_listing_card.dart';

class TalentMapView extends StatefulWidget {
  const TalentMapView({super.key});

  @override
  State<TalentMapView> createState() => _TalentMapViewState();
}

class _TalentMapViewState extends State<TalentMapView> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToChat() {
    final scaffold = context.findAncestorStateOfType<AdaptiveScaffoldState>();
    if (scaffold != null) {
      scaffold.setDestination(2); // Switch to Messages tab
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<MapFilterProvider>(
      builder: (context, mapProvider, child) {
        final selected = mapProvider.selectedPitch;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          resizeToAvoidBottomInset: false,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'fab_map_filter',
                tooltip: 'Filter map talent and radius',
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurface,
                onPressed: () => MapFilterSheet.show(context),
                child: const Icon(Icons.tune_rounded, size: 20),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'fab_map_recenter',
                tooltip: 'Recenter map to tech hub',
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                onPressed: () {
                  mapProvider.recenterToTechHub();
                  _mapController.move(mapProvider.userLatLng, 13.0);
                },
                child: const Icon(Icons.my_location_rounded),
              ),
              if (!isLandscape && selected != null) const SizedBox(height: 180),
            ],
          ),
          body: isLandscape
              ? _buildLandscapeLayout(context, mapProvider)
              : _buildPortraitLayout(context, mapProvider),
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    MapFilterProvider mapProvider,
  ) {
    final selected = mapProvider.selectedPitch;

    return Stack(
      children: [
        _buildMapWidget(mapProvider),
        _buildSearchBarOverlay(context, mapProvider, isLandscape: false),
        _buildCorridorChipsOverlay(context, mapProvider, isLandscape: false),
        if (selected != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MapListingCard(
              pitch: selected,
              onMessageDirect: _navigateToChat,
            ),
          ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    MapFilterProvider mapProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = mapProvider.selectedPitch;

    return Row(
      children: [
        // Left Pane: Map Canvas
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              _buildMapWidget(mapProvider),
              _buildSearchBarOverlay(context, mapProvider, isLandscape: true),
              _buildCorridorChipsOverlay(
                context,
                mapProvider,
                isLandscape: true,
              ),
            ],
          ),
        ),

        // Vertical divider
        VerticalDivider(width: 1, color: colorScheme.outlineVariant),

        // Right Pane: Filtered listings master-detail (independent SingleChildScrollView)
        Expanded(
          flex: 4,
          child: Container(
            color: colorScheme.surfaceContainerLowest,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top status bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hub_outlined,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mapProvider.selectedCorridor != null
                                ? '${mapProvider.selectedCorridor!.name} (${mapProvider.filteredPitches.length})'
                                : 'Nearby Listings (${mapProvider.filteredPitches.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Within ${mapProvider.radiusKm.toStringAsFixed(0)}km',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Selected Listing Card
                  if (selected != null)
                    MapListingCard(
                      pitch: selected,
                      onMessageDirect: _navigateToChat,
                      margin: const EdgeInsets.only(bottom: 8),
                    ),

                  // Other nearby listings list
                  Text(
                    'All Corridor Matches',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...mapProvider.filteredPitches.map((item) {
                    final isCurrent = item.id == selected?.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildMiniListingTile(
                        context,
                        item,
                        isCurrent,
                        mapProvider,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapWidget(MapFilterProvider mapProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = mapProvider.selectedPitch;

    final markers = <Marker>[
      // User / Tech Hub Center Pin
      Marker(
        point: mapProvider.userLatLng,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];

    // Clustered or individual markers from GeospatialClusterer
    for (final cluster in mapProvider.clusters) {
      if (cluster.isCluster) {
        // Render clustered badge marker
        markers.add(
          Marker(
            point: cluster.center,
            width: 58,
            height: 58,
            child: Semantics(
              button: true,
              label:
                  '${cluster.count} talent in ${cluster.corridor?.name ?? 'Cluster'}',
              child: GestureDetector(
                onTap: () {
                  mapProvider.selectPitch(cluster.primaryPitch);
                  _mapController.move(cluster.center, 14.5);
                  mapProvider.setZoom(14.5);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.hub_rounded,
                        size: 20,
                        color: colorScheme.onPrimary.withValues(alpha: 0.35),
                      ),
                      Positioned(
                        top: 7,
                        child: Text(
                          '${cluster.count}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        child: Text(
                          'CORRIDOR',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: colorScheme.onPrimary.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        // Render individual talent marker
        final pitch = cluster.primaryPitch;
        final isSel = selected?.id == pitch.id;
        final Color pinColor = pitch.category == 'Freelancer'
            ? colorScheme.secondary
            : (pitch.category == 'Job'
                  ? colorScheme.primary
                  : colorScheme.tertiary);

        markers.add(
          Marker(
            point: LatLng(pitch.latitude, pitch.longitude),
            width: isSel ? 52 : 42,
            height: isSel ? 52 : 42,
            child: Semantics(
              button: true,
              label:
                  '${pitch.creatorName}, ${pitch.role}, \$${pitch.hourlyRate.toStringAsFixed(0)} per hour in ${pitch.locationName}',
              child: GestureDetector(
                onTap: () {
                  mapProvider.selectPitch(pitch);
                  _mapController.move(
                    LatLng(pitch.latitude, pitch.longitude),
                    14.0,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: isSel
                        ? pinColor
                        : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? colorScheme.onPrimary : pinColor,
                      width: isSel ? 2.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.4),
                        blurRadius: isSel ? 12 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: isSel ? 18 : 14,
                      backgroundColor: colorScheme.surfaceContainer,
                      backgroundImage: AssetImage(pitch.creatorAvatar),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    // Polyline route if enabled
    final polylines = <Polyline>[];
    if (mapProvider.showRoute && selected != null) {
      polylines.add(
        Polyline(
          points: [
            mapProvider.userLatLng,
            LatLng(selected.latitude, selected.longitude),
          ],
          strokeWidth: 4.0,
          color: colorScheme.primary,
        ),
      );
    }

    // Geofence circles for tech corridors
    final circles = TechCorridor.corridors.map((corridor) {
      final isSelected = mapProvider.selectedCorridor?.id == corridor.id;
      final hasActiveSelection = mapProvider.selectedCorridor != null;

      if (hasActiveSelection && !isSelected) {
        return CircleMarker(
          point: corridor.center,
          radius: corridor.radiusMeters,
          useRadiusInMeter: true,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
          borderColor: colorScheme.outlineVariant.withValues(alpha: 0.2),
          borderStrokeWidth: 1.0,
        );
      }

      return CircleMarker(
        point: corridor.center,
        radius: corridor.radiusMeters,
        useRadiusInMeter: true,
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.16)
            : colorScheme.secondary.withValues(alpha: 0.08),
        borderColor: isSelected
            ? colorScheme.primary.withValues(alpha: 0.8)
            : colorScheme.secondary.withValues(alpha: 0.4),
        borderStrokeWidth: isSelected ? 2.5 : 1.5,
      );
    }).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: mapProvider.userLatLng,
        initialZoom: mapProvider.currentZoom,
        minZoom: 4.0,
        maxZoom: 18.0,
        onPositionChanged: (pos, hasGesture) {
          mapProvider.setZoom(pos.zoom);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.agoramarket.app',
        ),
        CircleLayer(circles: circles),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildSearchBarOverlay(
    BuildContext context,
    MapFilterProvider mapProvider, {
    required bool isLandscape,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: isLandscape ? 8 : 48,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search roles, skills, or Lahore hub...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (q) => mapProvider.setSearchQuery(q),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search query',
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: colorScheme.outline,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    mapProvider.setSearchQuery('');
                  },
                ),
              IconButton(
                tooltip: 'Open map filter and radius settings',
                icon: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: colorScheme.onSurface,
                ),
                onPressed: () => MapFilterSheet.show(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorridorChipsOverlay(
    BuildContext context,
    MapFilterProvider mapProvider, {
    required bool isLandscape,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedCorridor = mapProvider.selectedCorridor;

    return Positioned(
      top: isLandscape ? 56 : 106,
      left: 16,
      right: 16,
      height: 34,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildCorridorChip(
              label: 'All Corridors',
              isSelected: selectedCorridor == null,
              colorScheme: colorScheme,
              onTap: () {
                mapProvider.selectCorridor(null);
                _mapController.move(mapProvider.userLatLng, 13.0);
                mapProvider.setZoom(13.0);
              },
            ),
            const SizedBox(width: 8),
            ...TechCorridor.corridors.map((corridor) {
              final isSelected = selectedCorridor?.id == corridor.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCorridorChip(
                  label: corridor.name
                      .replaceAll(' Tech Hub', '')
                      .replaceAll(' Innovation Center', '')
                      .replaceAll(' Software Technology Park', '')
                      .replaceAll(' (Johar Town)', ''),
                  isSelected: isSelected,
                  colorScheme: colorScheme,
                  onTap: () {
                    mapProvider.selectCorridor(corridor);
                    _mapController.move(corridor.center, 14.2);
                    mapProvider.setZoom(14.2);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCorridorChip({
    required String label,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniListingTile(
    BuildContext context,
    VideoPitch pitch,
    bool isSelected,
    MapFilterProvider mapProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        mapProvider.selectPitch(pitch);
        _mapController.move(LatLng(pitch.latitude, pitch.longitude), 14.0);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage: AssetImage(pitch.creatorAvatar),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pitch.creatorName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    pitch.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${pitch.hourlyRate.toStringAsFixed(0)}/hr',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
