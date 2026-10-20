/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
import 'package:flutter/material.dart';

import '../../features/admin/screens/admin_attendance_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_navigation_screen.dart';
import '../../features/admin/screens/admin_parking_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/attendance/screens/student_qr_screen.dart';
import '../../features/auth/screens/admin_login_screen.dart';
import '../../features/auth/screens/student_login_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/guest/screens/guest_home_screen.dart';
import '../../features/navigation/screens/navigation_screen.dart';
import '../../features/parking/screens/parking_screen.dart';
import '../../features/student/screens/student_home_screen.dart';
import '../../features/student/screens/student_profile_screen.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return _page(const WelcomeScreen());
      case AppRoutes.studentLogin:
        return _page(const StudentLoginScreen());
      case AppRoutes.adminLogin:
        return _page(const AdminLoginScreen());
      case AppRoutes.guestHome:
        return _page(const GuestHomeScreen());
      case AppRoutes.studentHome:
        return _page(const StudentHomeScreen());
      case AppRoutes.studentProfile:
        return _page(const StudentProfileScreen());
      case AppRoutes.adminHome:
        return _page(const AdminHomeScreen());
      case AppRoutes.navigation:
        return _page(const NavigationScreen());
      case AppRoutes.attendanceQr:
        return _page(const StudentQrScreen());
      case AppRoutes.parking:
        return _page(const ParkingScreen());
      case AppRoutes.adminNavigation:
        return _page(const AdminNavigationScreen());
      case AppRoutes.adminAttendance:
        return _page(const AdminAttendanceScreen());
      case AppRoutes.adminParking:
        return _page(const AdminParkingScreen());
      case AppRoutes.adminUsers:
        return _page(const AdminUsersScreen());
      default:
        return _page(const WelcomeScreen());
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
