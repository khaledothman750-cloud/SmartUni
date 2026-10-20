/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/design_mode_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/repositories/repository_hub.dart';
import '../../navigation/screens/navigation_screen.dart';

class AdminNavigationScreen extends StatelessWidget {
  const AdminNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin · Navigation')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            const DesignModeBanner(),
            const SectionHeader(
              title: 'Locations module',
              subtitle:
                  'Live status for the Navigation Worker. Buildings and edges are managed in D1.',
            ),
            const SizedBox(height: 14),
            _MetaCard(
              title: 'Worker URL',
              value: AppConfig.navigationWorkerUrl,
              icon: Icons.cloud_outlined,
            ),
            const SizedBox(height: 10),
            const _MetaCard(
              title: 'API key',
              value: 'Loaded from secrets.dart (gitignored — not in the repo)',
              icon: Icons.key_outlined,
            ),
            const SizedBox(height: 10),
            FutureBuilder(
              future: RepositoryHub.instance.navigation.fetchLocations(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return _MetaCard(
                  title: 'Locations (live)',
                  value: snapshot.connectionState == ConnectionState.waiting
                      ? 'Loading…'
                      : snapshot.hasError
                          ? 'Failed to load'
                          : '$count records from Cloudflare',
                  icon: Icons.place_outlined,
                );
              },
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NavigationScreen()),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open campus navigation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetaCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.navigationAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
