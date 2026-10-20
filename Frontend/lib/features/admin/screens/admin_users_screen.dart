/// Author / Project Supervisor : Omar Terro
/// GitHub                      : https://github.com/IOTERRO
/// Website                     : https://omarterro.fr
/// Student (FYP)               : Khaled Othman
/// Date                        : 20 October 2026
/// Project                     : SmartUni - Smart University CityU
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/remote/worker_api_client.dart';
import '../../../data/repositories/users_admin_repository.dart';

/// Admin · manage D1 users (students / admins) via Users Worker.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _repo = UsersAdminRepository();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _repo.fetchUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load users from Cloudflare: $e';
      });
    }
  }

  Future<void> _openAddDialog() async {
    final username = TextEditingController();
    final password = TextEditingController();
    final fullName = TextEditingController();
    final email = TextEditingController();
    final faculty = TextEditingController(text: 'Engineering Faculty');
    var role = 'student';
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Add user'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: username,
                      decoration: const InputDecoration(
                        labelText: 'Username (login / QR SID)',
                        hintText: 'e.g. STU-202110201 or student',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: fullName,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: faculty,
                      decoration: const InputDecoration(
                        labelText: 'Faculty (optional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Student'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setLocal(() => role = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (username.text.trim().isEmpty ||
                              password.text.isEmpty ||
                              fullName.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Username, password, and full name are required.',
                                ),
                              ),
                            );
                            return;
                          }
                          setLocal(() => saving = true);
                          try {
                            await _repo.createUser(
                              username: username.text,
                              password: password.text,
                              fullName: fullName.text,
                              role: role,
                              email: email.text,
                              faculty: faculty.text,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _load();
                          } on ApiException catch (e) {
                            setLocal(() => saving = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message)),
                            );
                          }
                        },
                  child: Text(saving ? 'Saving…' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );

    username.dispose();
    password.dispose();
    fullName.dispose();
    email.dispose();
    faculty.dispose();
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final id = (user['id'] as num?)?.toInt();
    final username = user['username']?.toString() ?? '';
    final role = (user['role']?.toString() ?? 'student').toLowerCase();
    if (id == null) return;

    if (role == 'admin') {
      final adminCount = _users
          .where((u) => (u['role']?.toString() ?? '').toLowerCase() == 'admin')
          .length;
      if (adminCount <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete the last admin account.'),
          ),
        );
        return;
      }
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove user?'),
        content: Text('Delete “$username”? They will no longer be able to log in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _repo.deleteUser(id);
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
    final students = _users
        .where((u) => (u['role']?.toString() ?? '') == 'student')
        .length;
    final admins = _users
        .where((u) => (u['role']?.toString() ?? '') == 'admin')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin · Users'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add user'),
        backgroundColor: AppColors.adminAccent,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 88),
                children: [
                  const SectionHeader(
                    title: 'App users',
                    subtitle:
                        'Accounts in Cloudflare D1 users table (login + QR SID).',
                  ),
                  const SizedBox(height: 12),
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
                  Row(
                    children: [
                      Expanded(
                        child: _CountCard(
                          label: 'Students',
                          value: '$students',
                          color: AppColors.attendanceAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CountCard(
                          label: 'Admins',
                          value: '$admins',
                          color: AppColors.adminAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_users.isEmpty)
                    const Text('No users found.')
                  else
                    ..._users.map((u) {
                      final role =
                          (u['role']?.toString() ?? 'student').toLowerCase();
                      final isAdmin = role == 'admin';
                      final name =
                          u['full_name']?.toString() ??
                          u['username']?.toString() ??
                          'User';
                      final username = u['username']?.toString() ?? '';
                      final faculty = u['faculty']?.toString();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (isAdmin
                                    ? AppColors.adminAccent
                                    : AppColors.attendanceAccent)
                                .withOpacity(0.12),
                            child: Icon(
                              isAdmin
                                  ? Icons.shield_outlined
                                  : Icons.school_outlined,
                              color: isAdmin
                                  ? AppColors.adminAccent
                                  : AppColors.attendanceAccent,
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              username,
                              role,
                              if (faculty != null && faculty.isNotEmpty)
                                faculty,
                            ].join(' · '),
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove',
                            onPressed: () => _deleteUser(u),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.danger,
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

class _CountCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CountCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
