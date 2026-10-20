/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/campus_hero_card.dart';
import '../../../core/widgets/design_mode_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/service_card.dart';

/// Admin role: DB Access style modules (Navigation / Attendance / Parking).
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  void _logout(BuildContext context) {
    SessionController.instance.clear();
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Portal'),
            SizedBox(height: 2),
            Text(
              'DB Access modules',
              style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DesignModeBanner(),
              const CampusHeroCard(
                title: 'Module management',
                subtitle: 'Oversee live Navigation, Attendance, and Parking backends.',
                icon: Icons.dashboard_customize_outlined,
                gradient: [AppColors.navy, AppColors.adminAccent],
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'DB Access',
                subtitle:
                    'Each module opens its admin view with live Cloudflare or Firebase data.',
              ),
              const SizedBox(height: 14),
              ServiceCard(
                title: 'Navigation',
                subtitle: 'Locations table (Cloudflare Worker).',
                icon: Icons.map_outlined,
                accent: AppColors.navigationAccent,
                tag: 'CLOUDFLARE',
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminNavigation),
              ),
              const SizedBox(height: 12),
              ServiceCard(
                title: 'Attendance',
                subtitle: 'Sessions & records (Cloudflare) + classroom QR scanner.',
                icon: Icons.fact_check_outlined,
                accent: AppColors.attendanceAccent,
                tag: 'CLOUDFLARE',
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminAttendance),
              ),
              const SizedBox(height: 12),
              ServiceCard(
                title: 'Parking',
                subtitle: 'IoT sensor status (Firebase).',
                icon: Icons.local_parking_rounded,
                accent: AppColors.parkingAccent,
                tag: 'FIREBASE',
                onTap: () => Navigator.pushNamed(context, AppRoutes.adminParking),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
