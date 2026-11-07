/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
import '../../core/config/app_config.dart';
import '../../core/config/secrets.dart';
import '../../core/models/campus_location.dart';
import '../remote/worker_api_client.dart';
import 'navigation_repository.dart';

/// Campus locations + routing via the Navigation Worker.
class CloudflareNavigationRepository implements NavigationRepository {
  CloudflareNavigationRepository({WorkerApiClient? client})
      : _client = client ??
            WorkerApiClient(
              baseUrl: AppConfig.navigationWorkerUrl,
              apiKey: Secrets.navigationWorkerApiKey,
            );

  final WorkerApiClient _client;

  void _ensureKey() {
    if (Secrets.navigationWorkerApiKey.contains('PASTE_KEY')) {
      throw ApiException(
        'Missing navigation API key. Copy secrets.example.dart → secrets.dart.',
      );
    }
  }

  @override
  Future<List<CampusLocation>> fetchLocations() async {
    _ensureKey();
    final json = await _client.get('/api/locations');
    return _parseLocationList(json['data']);
  }

  @override
  Future<List<CampusLocation>> search(String query) async {
    _ensureKey();
    final q = query.trim();
    if (q.isEmpty) return fetchLocations();

    final json = await _client.get(
      '/api/locations/search',
      query: {'q': q},
    );
    return _parseLocationList(json['data']);
  }

  @override
  Future<NavigationRoutePreview> findRoute({
    required String fromId,
    required String toId,
  }) async {
    _ensureKey();

    final json = await _client.get(
      '/api/navigation',
      query: {
        'from': fromId,
        'to': toId,
      },
    );

    final path = _parseLocationList(json['path']);
    final distance = (json['total_distance'] as num?)?.toDouble() ?? 0;
    return NavigationRoutePreview(
      path: path,
      totalDistanceMeters: distance,
    );
  }

  List<CampusLocation> _parseLocationList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => CampusLocation.fromWorkerJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }
}
