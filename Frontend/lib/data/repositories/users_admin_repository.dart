/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 20 October 2026
/// Project                     : SmartUni - Smart University CityU
import '../../core/config/app_config.dart';
import '../../core/config/secrets.dart';
import '../remote/worker_api_client.dart';

/// Admin CRUD for D1 `users` via the Users Worker.
class UsersAdminRepository {
  UsersAdminRepository({WorkerApiClient? client})
      : _client = client ??
            WorkerApiClient(
              baseUrl: AppConfig.usersWorkerUrl,
              apiKey: Secrets.usersWorkerApiKey,
            );

  final WorkerApiClient _client;

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final json = await _client.get('/api/users');
    final raw = json['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    required String fullName,
    required String role,
    String? email,
    String? faculty,
  }) async {
    final json = await _client.post(
      '/api/users',
      body: {
        'username': username.trim(),
        'password': password,
        'full_name': fullName.trim(),
        'role': role.trim().toLowerCase(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (faculty != null && faculty.trim().isNotEmpty)
          'faculty': faculty.trim(),
      },
    );
    final data = json['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<void> deleteUser(int id) async {
    await _client.delete('/api/users/$id');
  }
}
