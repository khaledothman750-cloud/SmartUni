/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
class CampusLocation {
  final String id;
  final String name;
  final String type;
  final int floor;
  final String? building;
  final String? description;
  final double? latitude;
  final double? longitude;

  const CampusLocation({
    required this.id,
    required this.name,
    required this.type,
    this.floor = 0,
    this.building,
    this.description,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude!.abs() > 0.01 &&
      longitude!.abs() > 0.01;

  /// Internal graph nodes (WP_*) — hide from directory / From–To pickers.
  bool get isWaypoint {
    if (type.toLowerCase() == 'waypoint') return true;
    final code = (building ?? '').toUpperCase();
    if (code.startsWith('WP_')) return true;
    return name.toLowerCase().startsWith('path');
  }

  /// Maps Navigation Worker `mapLocation` JSON → app model.
  factory CampusLocation.fromWorkerJson(Map<String, dynamic> json) {
    return CampusLocation(
      id: json['id'].toString(),
      name: (json['name'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? 'building').trim(),
      floor: (json['floor'] as num?)?.toInt() ?? 0,
      building: json['code'] as String?,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class NavigationRoutePreview {
  final List<CampusLocation> path;
  final double totalDistanceMeters;

  const NavigationRoutePreview({
    required this.path,
    required this.totalDistanceMeters,
  });
}
