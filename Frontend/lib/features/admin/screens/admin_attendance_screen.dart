/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 14 October 2026
/// Project                     : SmartUni - Smart University CityU
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/remote/worker_api_client.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/repository_hub.dart';

/// Admin attendance — roster + present/absent sheet from Cloudflare.
class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  List<Map<String, dynamic>> _sessions = [];
  AttendanceSheet? _sheet;
  String? _sessionId;
  bool _loadingSessions = true;
  bool _loadingSheet = false;
  String? _error;

  Map<String, dynamic>? get _selectedSession {
    if (_sessionId == null) return null;
    for (final s in _sessions) {
      if (s['id']?.toString() == _sessionId) return s;
    }
    return null;
  }

  String? get _courseId => _selectedSession?['course_id']?.toString();

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loadingSessions = true;
      _error = null;
    });
    try {
      final sessions =
          await RepositoryHub.instance.attendance.fetchSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _sessionId = sessions.isNotEmpty
            ? sessions.first['id']?.toString()
            : null;
        _loadingSessions = false;
      });
      if (_sessionId != null) {
        await _loadSheet(_sessionId!);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSessions = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSessions = false;
        _error = 'Could not load attendance sessions.';
      });
    }
  }

  Future<void> _loadSheet(String sessionId) async {
    setState(() {
      _loadingSheet = true;
      _error = null;
      _sessionId = sessionId;
    });
    try {
      final sheet = await RepositoryHub.instance.attendance.fetchSheet(
        sessionId: sessionId,
      );
      if (!mounted) return;
      setState(() {
        _sheet = sheet;
        _loadingSheet = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSheet = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSheet = false;
        _error =
            'Could not load attendance sheet. Deploy Worker + create course_enrollments table.';
      });
    }
  }

  Future<void> _openRosterEditor() async {
    final courseId = _courseId;
    if (courseId == null || courseId.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return _RosterSheet(
          courseId: courseId,
          onChanged: () {
            if (_sessionId != null) _loadSheet(_sessionId!);
          },
        );
      },
    );
  }

  String _formatScanTime(Object? raw) {
    if (raw == null) return '—';
    final text = raw.toString();
    if (text.length >= 16) {
      return text.substring(11, 16);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final sheet = _sheet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin · Attendance'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadingSessions ? null : _loadSessions,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loadingSessions
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  const SectionHeader(
                    title: 'Class attendance',
                    subtitle:
                        'Roster (enrollments) + scans → Present / Absent.',
                  ),
                  const SizedBox(height: 14),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (_sessions.isEmpty)
                    const Text('No attendance sessions found in D1.')
                  else ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey(_sessionId),
                      initialValue: _sessionId,
                      decoration:
                          const InputDecoration(labelText: 'Session'),
                      items: _sessions
                          .map(
                            (s) => DropdownMenuItem(
                              value: s['id']?.toString(),
                              child: Text(
                                '${s['course_id'] ?? ''} · ${s['session_date'] ?? ''} ${s['start_time'] ?? ''}'
                                    .trim(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _loadSheet(v);
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _courseId == null ? null : _openRosterEditor,
                      icon: const Icon(Icons.group_add_outlined),
                      label: Text(
                        _courseId == null
                            ? 'Manage class roster'
                            : 'Manage roster · $_courseId',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loadingSheet)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (sheet == null)
                      const Text('Select a session to view attendance.')
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _StatChip(
                              label: 'Enrolled',
                              value: '${sheet.enrolled}',
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatChip(
                              label: 'Present',
                              value: '${sheet.present}',
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatChip(
                              label: 'Absent',
                              value: '${sheet.absent}',
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (sheet.rows.isEmpty)
                        const Text(
                          'No students enrolled for this course yet. Tap “Manage roster” to add them.',
                        )
                      else
                        ...sheet.rows.map((row) {
                          final status =
                              (row['status'] as String? ?? 'Absent').trim();
                          final present =
                              status.toLowerCase() == 'present';
                          final name =
                              row['student_name']?.toString() ?? 'Student';
                          final sid =
                              row['student_id']?.toString() ?? '';
                          final enrolled = row['enrolled'] != false;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: (present
                                        ? AppColors.success
                                        : AppColors.danger)
                                    .withOpacity(0.12),
                                child: Icon(
                                  present
                                      ? Icons.check_rounded
                                      : Icons.close_rounded,
                                  color: present
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                enrolled
                                    ? sid
                                    : '$sid · not on roster',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: present
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                  ),
                                  Text(
                                    _formatScanTime(row['scanned_at']),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterSheet extends StatefulWidget {
  final String courseId;
  final VoidCallback onChanged;

  const _RosterSheet({
    required this.courseId,
    required this.onChanged,
  });

  @override
  State<_RosterSheet> createState() => _RosterSheetState();
}

class _RosterSheetState extends State<_RosterSheet> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await RepositoryHub.instance.attendance.fetchEnrollments(
        courseId: widget.courseId,
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
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
        _error = 'Could not load roster. Create course_enrollments in D1.';
      });
    }
  }

  Future<void> _add() async {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    if (id.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter student ID and name.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await RepositoryHub.instance.attendance.addEnrollment(
        courseId: widget.courseId,
        studentId: id,
        studentName: name,
      );
      _idController.clear();
      _nameController.clear();
      widget.onChanged();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(String studentId) async {
    try {
      await RepositoryHub.instance.attendance.removeEnrollment(
        courseId: widget.courseId,
        studentId: studentId,
      );
      widget.onChanged();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Class roster · ${widget.courseId}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add every student who should attend this course. '
              'Absent = enrolled but not scanned.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Student ID (login / QR SID)',
                hintText: 'e.g. student',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Student name',
                hintText: 'e.g. Khaled Othman',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saving ? null : _add(),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _saving ? null : _add,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(_saving ? 'Adding…' : 'Add to roster'),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rows.isEmpty
                      ? const Center(child: Text('Roster is empty.'))
                      : ListView.builder(
                          itemCount: _rows.length,
                          itemBuilder: (context, i) {
                            final row = _rows[i];
                            final sid =
                                row['student_id']?.toString() ?? '';
                            final name =
                                row['student_name']?.toString() ?? '';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(sid),
                              trailing: IconButton(
                                tooltip: 'Remove',
                                onPressed: () => _remove(sid),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.danger,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
