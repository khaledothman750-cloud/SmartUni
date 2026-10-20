/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/models/student_qr_payload.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/design_mode_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/repositories/repository_hub.dart';

/// Student shows a rotating personal QR code.
/// Classroom device (separate app) will scan this and write Cloudflare attendance.
class StudentQrScreen extends StatefulWidget {
  const StudentQrScreen({super.key});

  @override
  State<StudentQrScreen> createState() => _StudentQrScreenState();
}

class _StudentQrScreenState extends State<StudentQrScreen> {
  StudentQrPayload? _payload;
  Timer? _timer;
  int _secondsLeft = AppConfig.studentQrRefreshInterval.inSeconds;

  @override
  void initState() {
    super.initState();
    _rotate();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _rotate() {
    final user = SessionController.instance.user;
    if (user == null) return;
    setState(() {
      _payload = RepositoryHub.instance.attendance.generateStudentQr(user);
      _secondsLeft = AppConfig.studentQrRefreshInterval.inSeconds;
    });
  }

  void _tick() {
    if (_payload == null) return;
    if (_secondsLeft <= 1) {
      _rotate();
      return;
    }
    setState(() => _secondsLeft -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionController.instance.user;
    final payload = _payload;

    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance QR')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            children: [
              const DesignModeBanner(),
              const SectionHeader(
                title: 'Present this QR in class',
                subtitle:
                    'Your code refreshes automatically. A classroom scanner posts it to the Cloudflare attendance Worker.',
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.attendanceAccent.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      user?.displayName ?? 'Student',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.id ?? '',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (payload != null)
                      QrImageView(
                        data: payload.encoded,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                      )
                    else
                      const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FF),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Refreshes in ${_secondsLeft}s',
                        style: const TextStyle(
                          color: AppColors.attendanceAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (payload != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Token ${payload.token}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F8F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD7E8DD)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.success, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Flow: show this QR → Classroom Scanner reads it → '
                        'Attendance Worker stores the record in Cloudflare D1.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _rotate,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh QR now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
