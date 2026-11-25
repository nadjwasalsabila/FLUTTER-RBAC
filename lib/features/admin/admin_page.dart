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

  List<Map<String, Object?>> _roles = [];
  List<Map<String, Object?>> _permissions = [];
  List<List<bool>> _matrix = [];
  bool _isLoading = true;
  String? _statusMessage;
  bool _isErrorStatus = false;

  final Set<String> _updating = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final roles = await widget.db.query('roles', orderBy: 'display_name COLLATE NOCASE ASC');
      final permissions = await widget.db.query('permissions', orderBy: 'key COLLATE NOCASE ASC');

      final matrix = List.generate(roles.length, (_) => List.filled(permissions.length, false));

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
        _statusMessage = 'Matriks izin dimuat.';
        _isErrorStatus = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = 'Gagal memuat matriks: ${e.toString()}';
        _isErrorStatus = true;
      });
    }
  }

  Future<void> _togglePermission(int roleIndex, int permIndex) async {
    final roleId = _roles[roleIndex]['id'] as String;
    final permKey = _permissions[permIndex]['key'] as String;
    final key = '${roleId}:${permKey}';
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
        final currentActive = existing.first['is_active'] as int? ?? 0;
        await widget.db.execute(
          'UPDATE role_permissions SET is_active = ? WHERE role_id = ? AND permission_key = ?',
          [currentActive == 1 ? 0 : 1, roleId, permKey],
        );
      }

      if (!mounted) return;

      final nowActive = !(_matrix[roleIndex][permIndex]);
      setState(() {
        _matrix[roleIndex][permIndex] = nowActive;
        _statusMessage = 'Izin ${permKey} untuk ${_roles[roleIndex]['display_name']} '
            '${nowActive ? 'diaktifkan' : 'dinonaktifkan'}.';
        _isErrorStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_statusMessage!),
          backgroundColor: nowActive ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Gagal toggle izin: ${e.toString()}';
        _isErrorStatus = true;
      });
    } finally {
      setState(() => _updating.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        backgroundColor: _primaryTeal,
        foregroundColor: Colors.white,
        title: const Text('Kebijakan Izin Role'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Muat ulang matriks',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_statusMessage != null)
              _buildStatusBanner(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _primaryTeal.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings, color: _primaryTeal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Login sebagai: ${widget.fullName}',
                  style: const TextStyle(
                    color: _primaryTeal,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Role: ${widget.roleId}',
                  style: TextStyle(
                    color: _primaryTeal.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _isErrorStatus ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isErrorStatus ? Colors.red.shade200 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                fontSize: 13,
                color: _isErrorStatus ? Colors.red.shade800 : Colors.blue.shade800,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _statusMessage = null),
            child: const Text('Tutup', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _primaryTeal),
            SizedBox(height: 16),
            Text('Memuat matriks izin...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_roles.isEmpty || _permissions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('Tidak ada data role atau permission.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegend(),
              const SizedBox(height: 16),
              _buildTableHeader(),
              const SizedBox(height: 8),
              ...List.generate(_roles.length, (ri) => _buildRow(ri)),
              const SizedBox(height: 8),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _legendChip('Aktif', Colors.green),
        const SizedBox(width: 12),
        _legendChip('Nonaktif', Colors.grey),
      ],
    );
  }

  Widget _legendChip(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color, margin: const EdgeInsets.only(right: 4)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Role \ Permission',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        ..._permissions.map((p) {
          return Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 2),
              child: Text(
                p['key'] as String,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRow(int ri) {
    final role = _roles[ri];
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 150,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      role['display_name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      role['description'] as String? ?? '',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            ...List.generate(_permissions.length, (pi) {
              final active = _matrix[ri][pi];
              final permKey = _permissions[pi]['key'] as String;
              final updateKey = '${_roles[ri]['id']}:${permKey}';
              return Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 2),
                  child: _PermissionCell(
                    active: active,
                    label: permKey,
                    onTap: () => _togglePermission(ri, pi),
                    isUpdating: _updating.contains(updateKey),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        'Ket: Tap sel untuk mengubah status izin. Perubahan langsung berlaku (live policy).',
        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _PermissionCell extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;
  final bool isUpdating;

  const _PermissionCell({
    required this.active,
    required this.label,
    required this.onTap,
    required this.isUpdating,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUpdating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? Colors.green.shade200 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpdating ? Icons.sync : (active ? Icons.check_circle : Icons.cancel),
              size: 14,
              color: active ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? Colors.green.shade800 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
