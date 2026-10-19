// Author / Project Supervisor : Omar Terro
// GitHub                      : https://github.com/IOTERRO
// Website                     : https://omarterro.fr
// Student (FYP)               : Khaled Othman
// Date                        : 19 October 2026
// Project                     : SmartUni - Smart University CityU
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/maps/offline_campus_map.dart';
import '../../../core/models/campus_location.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/remote/worker_api_client.dart';
import '../../../data/repositories/repository_hub.dart';

/// Shared Navigation UI — Cloudflare route + offline/online campus map.
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();

  List<CampusLocation> _locations = [];
  String? _fromId;
  String? _toId;
  NavigationRoutePreview? _route;
  bool _loading = true;
  bool _routing = false;
  bool _mapReady = false;
  String _search = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    OfflineCampusMapSource.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      await OfflineCampusMapSource.ensureReady();
    } catch (_) {
      // Fall back to online tiles in buildTileLayer.
    }
    if (!mounted) return;
    setState(() => _mapReady = true);
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await RepositoryHub.instance.navigation.fetchLocations();
      if (!mounted) return;
      setState(() {
        _locations = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load campus locations.';
      });
    }
  }

  /// Buildings only — path waypoints stay in the graph for drawing routes.
  List<CampusLocation> get _pickable {
    return _locations.where((l) => l.type.toLowerCase() != 'waypoint').toList();
  }

  List<CampusLocation> get _filtered {
    final q = _search.trim().toLowerCase();
    final base = _pickable;
    if (q.isEmpty) return base;
    return base
        .where(
          (l) =>
              l.name.toLowerCase().contains(q) ||
              l.type.toLowerCase().contains(q) ||
              (l.building?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  LatLng? _latLngOf(CampusLocation l) {
    if (!l.hasCoordinates) return null;
    return LatLng(l.latitude!, l.longitude!);
  }

  List<LatLng> get _routePoints {
    final route = _route;
    if (route == null) return const [];
    return route.path
        .map(_latLngOf)
        .whereType<LatLng>()
        .toList(growable: false);
  }

  void _fitRouteOnMap(List<LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 16);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  Future<void> _findRoute() async {
    if (_fromId == null || _toId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select start and destination.')),
      );
      return;
    }
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose two different locations.')),
      );
      return;
    }

    setState(() => _routing = true);
    try {
      final route = await RepositoryHub.instance.navigation.findRoute(
        fromId: _fromId!,
        toId: _toId!,
      );
      if (!mounted) return;
      setState(() => _route = route);
      final points = route.path
          .map(_latLngOf)
          .whereType<LatLng>()
          .toList(growable: false);
      if (points.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Route found, but locations need latitude/longitude in D1 to draw on the map.',
            ),
          ),
        );
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fitRouteOnMap(points);
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find a route.')),
      );
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  Widget _buildMap() {
    final points = _routePoints;
    final markers = <Marker>[];
    for (var i = 0; i < points.length; i++) {
      final isStart = i == 0;
      final isEnd = i == points.length - 1;
      markers.add(
        Marker(
          point: points[i],
          width: 40,
          height: 40,
          child: Icon(
            isStart
                ? Icons.flag_circle
                : (isEnd ? Icons.location_on : Icons.circle),
            color: isStart
                ? AppColors.success
                : (isEnd ? AppColors.danger : AppColors.blue),
            size: isStart || isEnd ? 36 : 14,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 320,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: CampusMapDefaults.center,
            initialZoom: CampusMapDefaults.zoom,
            minZoom: 13,
            maxZoom: 17,
          ),
          children: [
            OfflineCampusMapSource.buildTileLayer(),
            if (points.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    strokeWidth: 5,
                    color: AppColors.blue.withValues(alpha: 0.9),
                  ),
                ],
              ),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(OfflineCampusMapSource.modeLabel),
                const TextSourceAttribution('© OpenStreetMap'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Navigation'),
      ),
      body: _loading || !_mapReady
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    children: [
                      const SectionHeader(
                        title: 'Find your way',
                        subtitle:
                            'Cloudflare finds the path; the map shows it on campus.',
                      ),
                      const SizedBox(height: 12),
                      _buildMap(),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search buildings, labs, offices…',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _fromId,
                        decoration: const InputDecoration(labelText: 'From'),
                        items: _filtered
                            .map(
                              (l) => DropdownMenuItem(
                                value: l.id,
                                child: Text(l.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _fromId = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _toId,
                        decoration: const InputDecoration(labelText: 'To'),
                        items: _pickable
                            .map(
                              (l) => DropdownMenuItem(
                                value: l.id,
                                child: Text(l.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _toId = v),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _routing ? null : _findRoute,
                        icon: _routing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.navigation_rounded),
                        label: Text(_routing ? 'Finding…' : 'Find route'),
                      ),
                      if (_route != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF4FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD7E4FF)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total distance',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${_route!.totalDistanceMeters.toStringAsFixed(0)} m',
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._route!.path.asMap().entries.map((entry) {
                          final i = entry.key;
                          final step = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.navigationAccent
                                    .withValues(alpha: 0.12),
                                foregroundColor: AppColors.navigationAccent,
                                child: Text('${i + 1}'),
                              ),
                              title: Text(
                                step.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${step.type} · Floor ${step.floor}'
                                '${step.building != null ? ' · ${step.building}' : ''}'
                                '${step.hasCoordinates ? '' : ' · (no map coords)'}',
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 22),
                      const SectionHeader(
                        title: 'Campus directory',
                        subtitle: 'Locations loaded from the Navigation Worker.',
                      ),
                      const SizedBox(height: 10),
                      ..._filtered.map(
                        (l) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              l.hasCoordinates
                                  ? Icons.place
                                  : Icons.place_outlined,
                              color: AppColors.navigationAccent,
                            ),
                            title: Text(
                              l.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(l.description ?? l.type),
                            trailing: Text(
                              'F${l.floor}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
