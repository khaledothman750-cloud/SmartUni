/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
import '../../core/config/app_config.dart';
import 'attendance_repository.dart';
import 'auth_repository.dart';
import 'cloudflare_auth_repository.dart';
import 'cloudflare_navigation_repository.dart';
import 'firebase_parking_repository.dart';
import 'navigation_repository.dart';
import 'parking_repository.dart';

/// Picks live Cloudflare/Firebase repositories (or mocks if flags are off).
class RepositoryHub {
  RepositoryHub._({
    required this.auth,
    required this.navigation,
    required this.parking,
    required this.attendance,
  });

  final AuthRepository auth;
  final NavigationRepository navigation;
  final ParkingRepository parking;
  final AttendanceRepository attendance;

  static final RepositoryHub instance = RepositoryHub._(
    auth: AppConfig.useCloudflareApis
        ? CloudflareAuthRepository()
        : MockAuthRepository(),
    navigation: AppConfig.useCloudflareApis
        ? CloudflareNavigationRepository()
        : MockNavigationRepository(),
    parking: AppConfig.parkingUsesFirebase
        ? FirebaseParkingRepository()
        : MockParkingRepository(),
    attendance: AppConfig.useCloudflareApis
        ? CloudflareAttendanceRepository()
        : MockAttendanceRepository(),
  );
}
