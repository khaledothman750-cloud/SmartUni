/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/models/parking_slot.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/remote/worker_api_client.dart';
import '../../../data/repositories/repository_hub.dart';

/// Student parking view — live Firebase RTDB feed from ESP32 sensors.
class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  ParkingSummary? _summary;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load(showSpinner: true);
    _pollTimer = Timer.periodic(
      AppConfig.parkingRefreshInterval,
      (_) => _load(showSpinner: false),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await RepositoryHub.instance.parking.fetchSummary();
      if (!mounted) return;
      setState(() {
        _summary = data;
        _loading = false;
        _error = null;
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
        _error = 'Could not load parking data from Firebase.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Parking'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _load(showSpinner: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
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
          : summary == null
              ? const Center(child: Text('No parking data.'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  const SectionHeader(
                    title: 'Campus parking',
                    subtitle:
                        'Bay status from Firebase. Banner shows if the ESP32 is actively publishing.',
                  ),
                  const SizedBox(height: 10),
                  _EspStatusBanner(summary: summary),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Available',
                          value: '${summary.available}',
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Occupied',
                          value: '${summary.occupied}',
                          icon: Icons.directions_car_filled_outlined,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Slots',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...summary.slots.map((slot) {
                    final occupied = slot.isOccupied;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (occupied ? AppColors.danger : AppColors.success)
                              .withOpacity(0.12),
                          child: Icon(
                            occupied ? Icons.directions_car : Icons.local_parking_rounded,
                            color: occupied ? AppColors.danger : AppColors.success,
                          ),
                        ),
                        title: Text(
                          slot.code,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(slot.zone ?? 'Campus lot'),
                        trailing: Text(
                          occupied ? 'Occupied' : 'Available',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: occupied ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _EspStatusBanner extends StatelessWidget {
  final ParkingSummary summary;

  const _EspStatusBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.parkingUsesFirebase) {
      return _banner(
        text: 'Backend target: Cloudflare',
        bg: const Color(0xFFFFF7ED),
        border: const Color(0xFFFED7AA),
        fg: const Color(0xFF9A3412),
        icon: Icons.cloud_outlined,
      );
    }

    final online = summary.isEspOnline(
      staleAfter: AppConfig.parkingEspStaleAfter,
    );
    final last = summary.lastEspUpdate;
    final age = last == null
        ? null
        : DateTime.now().toUtc().difference(last.toUtc());

    if (online) {
      final ago = age == null ? '' : ' · updated ${_formatAge(age)} ago';
      return _banner(
        text: 'ESP32 online$ago',
        bg: const Color(0xFFECFDF5),
        border: const Color(0xFFA7F3D0),
        fg: const Color(0xFF065F46),
        icon: Icons.sensors,
      );
    }

    if (last == null) {
      return _banner(
        text: 'ESP32 offline — showing last known status (no fresh sensor data)',
        bg: const Color(0xFFFFF7ED),
        border: const Color(0xFFFED7AA),
        fg: const Color(0xFF9A3412),
        icon: Icons.sensors_off,
      );
    }

    return _banner(
      text:
          'ESP32 offline — last update ${_formatAge(age!)} ago (cached in Firebase)',
      bg: const Color(0xFFFEF2F2),
      border: const Color(0xFFFECACA),
      fg: const Color(0xFF991B1B),
      icon: Icons.sensors_off,
    );
  }

  static String _formatAge(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 48) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  Widget _banner({
    required String text,
    required Color bg,
    required Color border,
    required Color fg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
