import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/app_theme.dart';

class AdminPolicyPage extends StatefulWidget {
  final Database db;
  final String fullName;
  final String roleId;

  const AdminPolicyPage({
    super.key,
    required this.db,
    required this.fullName,
    required this.roleId,
  });

  @override
  State<AdminPolicyPage> createState() => _AdminPolicyPageState();
}

class _AdminPolicyPageState extends State<AdminPolicyPage> {
  final Set<String> _updating = {};

  List<Map<String, Object?>> _roles = [];
  List<Map<String, Object?>> _permissions = [];
  List<List<bool>> _matrix = [];
  bool _isLoading = true;
  String? _lastMessage;
  bool _lastMessageIsError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final roles = await widget.db.query('roles',
          orderBy: 'display_name COLLATE NOCASE ASC');
      final permissions = await widget.db.query('permissions',
          orderBy: 'key COLLATE NOCASE ASC');
      // Satu query untuk seluruh matriks — bukan N×M query per sel.
      final allRows = await widget.db.query(
        'role_permissions',
        columns: const ['role_id', 'permission_key', 'is_active'],
      );
      final active = <String>{
        for (final r in allRows)
          if ((r['is_active'] as int? ?? 0) == 1)
            '${r['role_id']}:${r['permission_key']}',
      };

      final matrix = List.generate(
        roles.length,
        (ri) => List.generate(
          permissions.length,
          (pi) => active.contains(
            '${roles[ri]['id']}:${permissions[pi]['key']}',
          ),
        ),
      );

      if (!mounted) return;
      setState(() {
        _roles = roles.cast();
        _permissions = permissions.cast();
        _matrix = matrix;
        _isLoading = false;
        _lastMessage = 'Matriks izin dimuat.';
        _lastMessageIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _lastMessage = 'Gagal memuat: ${e.toString()}';
        _lastMessageIsError = true;
      });
    }
  }

  Future<void> _toggle(int ri, int pi) async {
    final roleId = _roles[ri]['id'] as String;
    final roleName = _roles[ri]['display_name'] as String;
    final permKey = _permissions[pi]['key'] as String;
    final key = '$roleId:$permKey';
    if (_updating.contains(key)) return;

    setState(() => _updating.add(key));

    try {
      final existing = await widget.db.query(
        'role_permissions',
        columns: const ['is_active'],
        where: 'role_id = ? AND permission_key = ?',
        whereArgs: [roleId, permKey],
        limit: 1,
      );

      if (existing.isEmpty) {
        await widget.db.insert('role_permissions', {
          'role_id': roleId,
          'permission_key': permKey,
          'is_active': 1,
        });
      } else {
        final current = existing.first['is_active'] as int? ?? 0;
        await widget.db.execute(
          'UPDATE role_permissions SET is_active = ? WHERE role_id = ? AND permission_key = ?',
          [current == 1 ? 0 : 1, roleId, permKey],
        );
      }

      if (!mounted) return;
      setState(() {
        _matrix[ri][pi] = !_matrix[ri][pi];
        _lastMessage =
            'Izin "$permKey" untuk $roleName ${_matrix[ri][pi] ? 'diaktifkan' : 'dinonaktifkan'}.';
        _lastMessageIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastMessage = 'Gagal: ${e.toString()}';
        _lastMessageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _updating.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paleMint,
      appBar: AppBar(
        title: const Text('Kelola izin peran'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Row(
                      children: [
                        Icon(Icons.admin_panel_settings,
                            color: AppColors.primaryTeal, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Daftar izin per role',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_lastMessage != null)
                    AppStatusBanner(
                      message: _lastMessage!,
                      isError: _lastMessageIsError,
                      onDismiss: () =>
                          setState(() => _lastMessage = null),
                    ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    )
                  else if (_roles.isEmpty)
                    const Center(
                      child: Text(
                        'Tidak ada data.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    _PolicyTable(
                      roles: _roles,
                      permissions: _permissions,
                      matrix: _matrix,
                      onToggle: _toggle,
                      updating: _updating,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.paleMint,
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppColors.primaryTeal, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistem hak akses berbasis role',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Dengan sistem RBAC, setiap role memiliki izin berbeda. '
                  'Ketuk sel di bawah untuk mengaktifkan atau '
                  'menonaktifkan izin.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
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

class _PolicyTable extends StatelessWidget {
  final List<Map<String, Object?>> roles;
  final List<Map<String, Object?>> permissions;
  final List<List<bool>> matrix;
  final Future<void> Function(int, int) onToggle;
  final Set<String> updating;

  const _PolicyTable({
    required this.roles,
    required this.permissions,
    required this.matrix,
    required this.onToggle,
    required this.updating,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: const Center(
                    child: Text(
                      'Izin / Peran',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                ),
                ...permissions.map((p) {
                  final key = p['key'] as String;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _permIcon(key),
                            size: 18,
                            color: AppColors.primaryTeal,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            key.replaceAll(':', ' '),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...List.generate(roles.length, (ri) => _RoleRow(
                roles: roles,
                permissions: permissions,
                matrix: matrix,
                onToggle: onToggle,
                updating: updating,
                ri: ri,
              )),
        ],
      ),
    );
  }

  IconData _permIcon(String key) {
    return switch (key) {
      'item:read' => Icons.inventory_2,
      'stock:adjust' => Icons.tune,
      'item:create' => Icons.add_circle,
      'item:delete' => Icons.delete_outline,
      'policy:edit' => Icons.settings_suggest,
      _ => Icons.circle_outlined,
    };
  }
}

class _RoleRow extends StatelessWidget {
  final List<Map<String, Object?>> roles;
  final List<Map<String, Object?>> permissions;
  final List<List<bool>> matrix;
  final Future<void> Function(int, int) onToggle;
  final Set<String> updating;
  final int ri;

  const _RoleRow({
    required this.roles,
    required this.permissions,
    required this.matrix,
    required this.onToggle,
    required this.updating,
    required this.ri,
  });

  @override
  Widget build(BuildContext context) {
    final role = roles[ri];
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      role['display_name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.darkText,
                      ),
                    ),
                    Text(
                      role['description'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 1, height: 24, color: AppColors.border),
            ...List.generate(permissions.length, (pi) {
              final active = matrix[ri][pi];
              final key = '${roles[ri]['id']}:${permissions[pi]['key'] as String}';
              final isUpdating = updating.contains(key);
              return Expanded(
                child: GestureDetector(
                  onTap: isUpdating ? null : () => onToggle(ri, pi),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.successBg
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? AppColors.primaryTeal
                            : Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isUpdating
                            ? Icons.sync
                            : (active
                                ? Icons.check_circle
                                : Icons.circle_outlined),
                        size: 18,
                        color: active
                            ? AppColors.primaryTeal
                            : Colors.grey,
                      ),
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
