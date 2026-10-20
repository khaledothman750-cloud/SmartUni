/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
import '../../core/models/campus_location.dart';
import '../mock/mock_data.dart';

/// Navigation data access.
/// Live: Cloudflare Worker + locations table. Fallback: [MockNavigationRepository].
abstract class NavigationRepository {
  Future<List<CampusLocation>> fetchLocations();

  Future<List<CampusLocation>> search(String query);

  Future<NavigationRoutePreview> findRoute({
    required String fromId,
    required String toId,
  });
}

class MockNavigationRepository implements NavigationRepository {
  @override
  Future<List<CampusLocation>> fetchLocations() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(MockData.locations);
  }

  @override
  Future<List<CampusLocation>> search(String query) async {
    final all = await fetchLocations();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (l) =>
              l.name.toLowerCase().contains(q) ||
              l.type.toLowerCase().contains(q) ||
              (l.building?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Future<NavigationRoutePreview> findRoute({
    required String fromId,
    required String toId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final all = await fetchLocations();
    final from = all.firstWhere((l) => l.id == fromId);
    final to = all.firstWhere((l) => l.id == toId);
    return MockData.sampleRoute(from: from, to: to);
  }
}
