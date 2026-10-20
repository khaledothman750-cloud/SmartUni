/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
/// Non-secret application configuration.
///
/// Secrets (API keys) belong in `secrets.dart` (gitignored).
/// Copy from `secrets.example.dart` for local setup.
class AppConfig {
  AppConfig._();

  static const String appName = 'Smart University';
  static const String campusName = 'City University · Abi Samra Campus';

  /// Cloudflare Worker for campus Navigation (D1: cityu).
  static const String navigationWorkerUrl =
      'https://navigation.khaledothman750.workers.dev';

  /// Cloudflare Worker for users / login (D1: users).
  static const String usersWorkerUrl =
      'https://users.khaledothman750.workers.dev';

  /// Cloudflare Worker for attendance (D1: smart-university-db).
  static const String attendanceWorkerUrl =
      'https://smart-university.khaledothman750.workers.dev';

  /// Firebase Realtime Database project for parking IoT.
  static const String firebaseProjectId = 'smart-uni-a86c1';
  static const String firebaseDatabaseUrl =
      'https://smart-uni-a86c1-default-rtdb.europe-west1.firebasedatabase.app';
  static const String firebaseAuthDomain = 'smart-uni-a86c1.firebaseapp.com';

  /// RTDB path written by `iot/parking_node`.
  static const String firebaseParkingPath = 'SmartUniversity/Parking';

  /// Parking is live from Firebase + ESP32 sensors.
  static const bool parkingUsesFirebase = true;

  /// When true, auth + navigation + attendance use Cloudflare Workers (not mocks).
  static const bool useCloudflareApis = true;

  /// When true, shows the yellow design-mode banner (keep false for live demos).
  static const bool designMode = false;

  /// How often the student attendance QR rotates in the UI.
  static const Duration studentQrRefreshInterval = Duration(seconds: 20);

  /// How often the parking screen re-reads Firebase (ESP publishes ~every 10s).
  static const Duration parkingRefreshInterval = Duration(seconds: 5);

  /// ESP is "offline" if no bay `updated_at` is newer than this (≈ 3–4 publish cycles).
  static const Duration parkingEspStaleAfter = Duration(seconds: 45);
}
