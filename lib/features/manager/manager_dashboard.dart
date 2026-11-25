import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../auth/types/auth_user.dart';

/// Halaman untuk role manager/admin pada skema database baru
/// (warehouse_rbac.db). Mengelola master barang: tambah (item:create)
/// dan hapus (item:delete) dengan pemeriksaan izin RBAC.
class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({
    super.key,
    required this.db,
    required this.user,
    this.onSwitchAccount,
  });

  final Database db;
  final AuthUser user;
  final VoidCallback? onSwitchAccount;

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  static const _primaryTeal = Color(0xFF145858);

  List<_ManagerItem> _items = const [];
  bool _isLoading = true;
  bool _canCreate = false;
  bool _canDelete = false;
  String? _statusMessage;
  bool _isErrorStatus = false;

  String get _roleLabel => switch (widget.user.roleId) {
        'manager' => 'Kepala Gudang',
        'admin' => 'Admin Sistem',
        _ => 'Petugas Gudang',
      };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<bool> _hasPermission(String permissionKey) async {
    final rows = await widget.db.query(
      'role_permissions',
      columns: const ['permission_key'],
      where: 'role_id = ? AND permission_key = ?',
      whereArgs: [widget.user.roleId, permissionKey],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final permissions = await Future.wait<bool>([
      _hasPermission('item:create'),
      _hasPermission('item:delete'),
    ]);
    final rows = await widget.db.query(
      'warehouse_items',
      columns: const [
        'id',
        'sku',
        'name',
        'category',
        'location',
        'stock',
        'updated_at',
      ],
      orderBy: 'sku ASC',
    );
    if (!mounted) return;
    setState(() {
      _items = rows.map(_ManagerItem.fromMap).toList();
      _canCreate = permissions[0];
      _canDelete = permissions[1];
      _isLoading = false;
    });
  }

  void _showStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
      _isErrorStatus = isError;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _openAddDialog() async {
    if (!_canCreate) {
      _showStatus(
        'Akses ditolak: Anda tidak memiliki izin item:create.',
        isError: true,
      );
      return;
    }
    final input = await _ItemFormDialog.show(context);
    if (input == null || !mounted) return;
    await _addItem(input);
  }

  Future<void> _addItem(_ItemFormInput input) async {
    final sku = input.sku.trim();
    final name = input.name.trim();
    final category = input.category.trim();
    final location = input.location.trim();

    if (sku.isEmpty || name.isEmpty || category.isEmpty || location.isEmpty) {
      _showStatus('Semua input wajib diisi.', isError: true);
      return;
    }
    if (input.stock < 0) {
      _showStatus('Stok awal tidak boleh negatif.', isError: true);
      return;
    }

    final existing = await widget.db.query(
      'warehouse_items',
      columns: const ['id'],
      where: 'sku = ?',
      whereArgs: [sku],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      _showStatus('SKU $sku sudah digunakan oleh barang lain.', isError: true);
      return;
    }

    try {
      await widget.db.insert('warehouse_items', {
        'sku': sku,
        'name': name,
        'category': category,
        'location': location,
        'stock': input.stock,
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      _showStatus('Barang $sku berhasil ditambahkan.');
      await _loadData();
    } on DatabaseException {
      if (!mounted) return;
      _showStatus('Gagal menyimpan barang ke database.', isError: true);
    }
  }

  Future<void> _confirmDelete(_ManagerItem item) async {
    if (!_canDelete) {
      _showStatus(
        'Akses ditolak: Anda tidak memiliki izin item:delete.',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah barang ${item.sku} ingin dihapus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.db.delete(
        'warehouse_items',
        where: 'id = ?',
        whereArgs: [item.id],
      );
      if (!mounted) return;
      _showStatus('Barang ${item.sku} berhasil dihapus.');
      await _loadData();
    } on DatabaseException {
      if (!mounted) return;
      _showStatus('Gagal menghapus barang dari database.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalStock = _items.fold<int>(0, (sum, item) => sum + item.stock);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        backgroundColor: _primaryTeal,
        foregroundColor: Colors.white,
        title: const Text('Gudang RBAC — Manajemen Barang'),
        actions: [
          if (widget.onSwitchAccount != null)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: widget.onSwitchAccount,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Ganti Akun'),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _ManagerSummaryHeader(
                    userName: widget.user.fullName,
                    roleLabel: _roleLabel,
                    itemCount: _items.length,
                    totalStock: totalStock,
                  ),
                ),
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _ManagerStatusBanner(
                      message: _statusMessage!,
                      isError: _isErrorStatus,
                      onDismiss: () => setState(() => _statusMessage = null),
                    ),
                  ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Barang'),
        backgroundColor: _canCreate ? _primaryTeal : Colors.grey,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryTeal),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Tidak ada data barang tersedia.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _ManagerItemCard(
          item: item,
          canDelete: _canDelete,
          onDelete: () => _confirmDelete(item),
        );
      },
    );
  }
}

class _ManagerItem {
  const _ManagerItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.location,
    required this.stock,
  });

  final int id;
  final String sku;
  final String name;
  final String category;
  final String location;
  final int stock;

  factory _ManagerItem.fromMap(Map<String, Object?> map) {
    return _ManagerItem(
      id: map['id']! as int,
      sku: map['sku']! as String,
      name: map['name']! as String,
      category: map['category']! as String,
      location: map['location']! as String,
      stock: map['stock']! as int,
    );
  }
}

class _ManagerSummaryHeader extends StatelessWidget {
  const _ManagerSummaryHeader({
    required this.userName,
    required this.roleLabel,
    required this.itemCount,
    required this.totalStock,
  });

  final String userName;
  final String roleLabel;
  final int itemCount;
  final int totalStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC8E0CA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF145858),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Login sebagai $roleLabel',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
          _SummaryStat(label: 'Jenis Barang', value: '$itemCount'),
          const SizedBox(width: 16),
          _SummaryStat(label: 'Total Stok', value: '$totalStock'),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF145858),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _ManagerStatusBanner extends StatelessWidget {
  const _ManagerStatusBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isError ? const Color(0xFFFDE8E8) : const Color(0xFFE3F2E7),
      borderRadius: BorderRadius.circular(10),
      child: ListTile(
        dense: true,
        leading: Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: isError ? Colors.red : const Color(0xFF145858),
        ),
        title: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: isError ? Colors.red.shade900 : const Color(0xFF145858),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: onDismiss,
        ),
      ),
    );
  }
}

class _ManagerItemCard extends StatelessWidget {
  const _ManagerItemCard({
    required this.item,
    required this.canDelete,
    required this.onDelete,
  });

  final _ManagerItem item;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFC8E0CA),
          child: Text(
            item.sku.length > 3
                ? item.sku.substring(item.sku.length - 3)
                : item.sku,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF145858),
            ),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${item.sku} · ${item.category} · ${item.location}'),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.stock}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: item.stock < 5 ? Colors.red : Colors.green,
                  ),
                ),
                const Text(
                  'stok',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: canDelete ? Colors.red : Colors.grey,
              ),
              onPressed: onDelete,
              tooltip: canDelete ? 'Hapus barang' : 'Tidak ada izin item:delete',
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemFormInput {
  const _ItemFormInput({
    required this.sku,
    required this.name,
    required this.category,
    required this.location,
    required this.stock,
  });

  final String sku;
  final String name;
  final String category;
  final String location;
  final int stock;
}

class _ItemFormDialog extends StatefulWidget {
  const _ItemFormDialog();

  static Future<_ItemFormInput?> show(BuildContext context) {
    return showDialog<_ItemFormInput>(
      context: context,
      builder: (_) => const _ItemFormDialog(),
    );
  }

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _stockController = TextEditingController(text: '0');

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final stock = int.tryParse(_stockController.text.trim()) ?? -1;
    Navigator.of(context).pop(
      _ItemFormInput(
        sku: _skuController.text,
        name: _nameController.text,
        category: _categoryController.text,
        location: _locationController.text,
        stock: stock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Barang'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU',
                  hintText: 'contoh: SKU-1005',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Kategori'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi',
                  hintText: 'contoh: Aisle A-05',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stok Awal'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'Stok harus berupa angka >= 0';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF145858),
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
