/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
import 'dart:math';

import '../../core/config/app_config.dart';
import '../../core/config/secrets.dart';
import '../../core/models/app_user.dart';
import '../../core/models/student_qr_payload.dart';
import '../remote/worker_api_client.dart';

/// Attendance data access.
/// QR is generated on-device; sessions/records/roster come from the Attendance Worker.
abstract class AttendanceRepository {
  StudentQrPayload generateStudentQr(AppUser student);

  Future<List<Map<String, dynamic>>> fetchSessions({String? courseId});

  Future<List<Map<String, dynamic>>> fetchRecords({required String sessionId});

  /// Enrolled students + Present/Absent for a session.
  Future<AttendanceSheet> fetchSheet({required String sessionId});

  Future<List<Map<String, dynamic>>> fetchEnrollments({
    required String courseId,
  });

  Future<Map<String, dynamic>> addEnrollment({
    required String courseId,
    required String studentId,
    required String studentName,
  });

  Future<void> removeEnrollment({
    required String courseId,
    required String studentId,
  });
}

class AttendanceSheet {
  final String sessionId;
  final String courseId;
  final int enrolled;
  final int present;
  final int absent;
  final List<Map<String, dynamic>> rows;

  const AttendanceSheet({
    required this.sessionId,
    required this.courseId,
    required this.enrolled,
    required this.present,
    required this.absent,
    required this.rows,
  });
}

class MockAttendanceRepository implements AttendanceRepository {
  final _random = Random();

  @override
  StudentQrPayload generateStudentQr(AppUser student) {
    final now = DateTime.now();
    final token = List.generate(12, (_) => _random.nextInt(16).toRadixString(16))
        .join()
        .toUpperCase();

    // Prefer university username for SID so scans match D1 student_id values.
    final sid = student.identifier.trim().isNotEmpty
        ? student.identifier.trim()
        : student.id;

    return StudentQrPayload(
      studentId: sid,
      studentName: student.displayName,
      token: token,
      issuedAt: now,
      expiresAt: now.add(AppConfig.studentQrRefreshInterval),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSessions({String? courseId}) async {
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecords({
    required String sessionId,
  }) async {
    return const [];
  }

  @override
  Future<AttendanceSheet> fetchSheet({required String sessionId}) async {
    return AttendanceSheet(
      sessionId: sessionId,
      courseId: '',
      enrolled: 0,
      present: 0,
      absent: 0,
      rows: const [],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEnrollments({
    required String courseId,
  }) async {
    return const [];
  }

  @override
  Future<Map<String, dynamic>> addEnrollment({
    required String courseId,
    required String studentId,
    required String studentName,
  }) async {
    return {
      'course_id': courseId,
      'student_id': studentId,
      'student_name': studentName,
    };
  }

  @override
  Future<void> removeEnrollment({
    required String courseId,
    required String studentId,
  }) async {}
}

/// Live attendance sessions/records/roster + local rotating QR.
class CloudflareAttendanceRepository implements AttendanceRepository {
  CloudflareAttendanceRepository({
    WorkerApiClient? client,
    MockAttendanceRepository? localQr,
  })  : _client = client ??
            WorkerApiClient(
              baseUrl: AppConfig.attendanceWorkerUrl,
              apiKey: Secrets.attendanceWorkerApiKey,
            ),
        _localQr = localQr ?? MockAttendanceRepository();

  final WorkerApiClient _client;
  final MockAttendanceRepository _localQr;

  @override
  StudentQrPayload generateStudentQr(AppUser student) =>
      _localQr.generateStudentQr(student);

  @override
  Future<List<Map<String, dynamic>>> fetchSessions({String? courseId}) async {
    final query = <String, String>{};
    if (courseId != null && courseId.trim().isNotEmpty) {
      query['course_id'] = courseId.trim();
    }
    final json = await _client.get(
      '/api/attendance/sessions',
      query: query.isEmpty ? null : query,
    );
    return _asMapList(json['data']);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecords({
    required String sessionId,
  }) async {
    final json = await _client.get(
      '/api/attendance/records',
      query: {'session_id': sessionId},
    );
    return _asMapList(json['data']);
  }

  @override
  Future<AttendanceSheet> fetchSheet({required String sessionId}) async {
    final json = await _client.get(
      '/api/attendance/sheet',
      query: {'session_id': sessionId},
    );
    final summary = json['summary'];
    final map = summary is Map
        ? Map<String, dynamic>.from(summary)
        : <String, dynamic>{};
    return AttendanceSheet(
      sessionId: json['session_id']?.toString() ?? sessionId,
      courseId: json['course_id']?.toString() ?? '',
      enrolled: (map['enrolled'] as num?)?.toInt() ?? 0,
      present: (map['present'] as num?)?.toInt() ?? 0,
      absent: (map['absent'] as num?)?.toInt() ?? 0,
      rows: _asMapList(json['data']),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEnrollments({
    required String courseId,
  }) async {
    final id = Uri.encodeComponent(courseId.trim().toUpperCase());
    final json = await _client.get('/api/courses/$id/enrollments');
    return _asMapList(json['data']);
  }

  @override
  Future<Map<String, dynamic>> addEnrollment({
    required String courseId,
    required String studentId,
    required String studentName,
  }) async {
    final id = Uri.encodeComponent(courseId.trim().toUpperCase());
    final json = await _client.post(
      '/api/courses/$id/enrollments',
      body: {
        'student_id': studentId.trim(),
        'student_name': studentName.trim(),
      },
    );
    final data = json['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  @override
  Future<void> removeEnrollment({
    required String courseId,
    required String studentId,
  }) async {
    final cid = Uri.encodeComponent(courseId.trim().toUpperCase());
    final sid = Uri.encodeComponent(studentId.trim());
    await _client.delete('/api/courses/$cid/enrollments/$sid');
  }

  List<Map<String, dynamic>> _asMapList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }
}
