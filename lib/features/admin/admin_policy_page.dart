import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

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
  static const _primaryTeal = Color(0xFF145858);
  static const _softMint = Color(0xFFC8E0CA);
  static const _warmAmber = Color(0xFFF7B318);
  static const _paleMint = Color(0xFFE8F1E9);
  static const _darkText = Color(0xFF102A2A);

  final Set<String> _updating = {};

  List<Map<String, Object?>> _roles = [];
  List<Map<String, Object?>> _permissions = [];
  List<List<bool>> _matrix = [];
  bool _isLoading = true;
  String? _lastMessage;

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

      final matrix = List.generate(
          roles.length, (_) => List.filled(permissions.length, false));

      for (var ri = 0; ri < roles.length; ri++) {
        final roleId = roles[ri]['id'] as String;
        for (var pi = 0; pi < permissions.length; pi++) {
          final permKey = permissions[pi]['key'] as String;
          final row = await widget.db.query(
            'role_permissions',
            columns: const ['is_active'],
            where: 'role_id = ? AND permission_key = ?',
            whereArgs: [roleId, permKey],
            limit: 1,
          );
          if (row.isNotEmpty) {
            final active = row.first['is_active'] as int? ?? 0;
            matrix[ri][pi] = active == 1;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _roles = roles.cast();
        _permissions = permissions.cast();
        _matrix = matrix;
        _isLoading = false;
        _lastMessage = 'Matriks izin dimuat.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _lastMessage = 'Gagal memuat: ${e.toString()}';
      });
    }
  }

  Future<void> _toggle(int ri, int pi) async {
    final roleId = _roles[ri]['id'] as String;
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
        _lastMessage = '${_roles[ri]['display_name']} — '
            '${permKey} ${_matrix[ri][pi] ? 'diaktifkan' : 'dinonaktifkan'}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastMessage = 'Gagal: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _updating.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paleMint,
      appBar: AppBar(
        backgroundColor: _primaryTeal,
        foregroundColor: Colors.white,
        title: const Text('Kelola izin peran'),
        centerTitle: false,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh,
                color: Colors.white, size: 20),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: SafeArea(
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
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings,
                          color: _primaryTeal, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Daftar izin per role',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_lastMessage != null) _buildStatusChip(),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: _primaryTeal),
                  )
                else if (_roles.isEmpty)
                  const Center(
                    child: Text(
                      'Tidak ada data.',
                      style: TextStyle(color: Colors.black54),
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
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _softMint),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primaryTeal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined,
                color: _primaryTeal, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistem hak akses berbasis role',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _primaryTeal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dengan sistem RBAC, setiap role memiliki izin berbeda. '
                  'Admin dapat mengatur izin dengan mengaktifkan atau '
                  'menonaktifkan sel di bawah.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2E7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _softMint),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                color: _primaryTeal, size: 18),
            const SizedBox(width: 8),
            Text(
              _lastMessage!,
              style: const TextStyle(
                fontSize: 13,
                color: _primaryTeal,
              ),
            ),
          ],
        ),
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

  static const _primaryTeal = Color(0xFF145858);
  static const _softMint = Color(0xFFC8E0CA);
  static const _warmAmber = Color(0xFFF7B318);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _softMint),
      ),
      child: Padding(
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
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _primaryTeal,
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
                              color: _primaryTeal,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              key.replaceAll(':', ' '),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
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
            const Divider(height: 1, color: Color(0xFFE3EDE4)),
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

  static const _primaryTeal = Color(0xFF145858);
  static const _softMint = Color(0xFFC8E0CA);
  static const _warmAmber = Color(0xFFF7B318);
  static const _paleMint = Color(0xFFE8F1E9);
  static const _darkText = Color(0xFF102A2A);

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
                        color: _primaryTeal,
                      ),
                    ),
                    Text(
                      role['description'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: const Color(0xFFE3EDE4),
            ),
            ...List.generate(permissions.length, (pi) {
              final active = matrix[ri][pi];
              final permKey = permissions[pi]['key'] as String;
              final key = '${roles[ri]['id']}:$permKey';
              return Expanded(
                child: GestureDetector(
                  onTap: updating.contains(key) ? null : () => onToggle(ri, pi),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFE3F2E7) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active ? const Color(0xFF145858) : Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          updating.contains(key)
                              ? Icons.sync
                              : (active ? Icons.check_circle : Icons.circle_outlined),
                          size: 16,
                          color: active ? _primaryTeal : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          permKey.replaceAll(':', ' '),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? _primaryTeal : Colors.grey.shade500,
                          ),
                        ),
                      ],
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
