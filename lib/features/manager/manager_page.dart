import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/rbac/rbac_evaluator.dart';
import '../../core/rbac/rbac_service.dart';
import '../auth/types/auth_user.dart';
import 'add_item_page.dart';
import 'item_detail_page.dart';
import 'manager_service.dart';

class ManagerPage extends StatefulWidget {
  final Database db;
  final AuthUser currentUser;

  const ManagerPage({
    super.key,
    required this.db,
    required this.currentUser,
  });

  @override
  State<ManagerPage> createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {
  static const _primaryTeal = Color(0xFF145858);

  final RbacEvaluator _rbacEvaluator = RbacEvaluator(_db);
  final ManagerService _managerService = ManagerService(_db);

  List<Map<String, Object?>> _items = [];
  bool _isLoading = true;
  bool _canCreate = false;
  bool _canDelete = false;
  late final String _roleName;

  @override
  void initState() {
    super.initState();
    _roleName = _capitalize(widget.currentUser.roleId);
    _loadData();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await widget.db.query(
        'warehouse_items',
        orderBy: 'sku ASC',
      );
      final canCreate = await _rbacEvaluator.hasPermission(
        widget.currentUser.id,
        'item:create',
      );
      final canDelete = await _rbacEvaluator.hasPermission(
        widget.currentUser.id,
        'item:delete',
      );
      if (!mounted) return;
      setState(() {
        _items = items.cast();
        _canCreate = canCreate;
        _canDelete = canDelete;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddItem() async {
    if (!_canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses ditolak: Anda tidak memiliki izin item:create.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddItemPage(
          db: widget.db,
          currentUser: widget.currentUser,
        ),
      ),
    );
    if (result == true) await _loadData();
  }

  Future<void> _confirmDelete(Map<String, Object?> item) async {
    if (!_canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses ditolak: Anda tidak memiliki izin item:delete.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah barang ${item['sku']} ingin dihapus?'),
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

    if (confirmed != true) return;

    try {
      await widget.db.delete(
        'warehouse_items',
        where: 'id = ?',
        whereArgs: [item['id']],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barang ${item['sku']} berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openDetail(Map<String, Object?> item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Barang'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              'Login sebagai: ${widget.currentUser.fullName} ($_roleName)',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddItem,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Barang'),
        backgroundColor: _canCreate
            ? Theme.of(context).colorScheme.primary
            : Colors.grey,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Belum ada barang.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      separatorBuilder: (_, p) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _ItemCard(
          item: item,
          canDelete: _canDelete,
          onTap: () => _openDetail(item),
          onDelete: () => _confirmDelete(item),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Map<String, Object?> item;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            item['sku']!.toString().length > 3
                ? item['sku']!.toString().substring(item['sku']!.toString().length - 3)
                : item['sku']!.toString(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(item['name']!.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item['sku']} · ${item['category']} · ${item['location']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item['stock']!.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: (item['stock'] as int) < 5 ? Colors.red : Colors.green,
                  ),
                ),
                const Text('stok', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: canDelete ? Colors.red : Colors.grey,
              ),
              onPressed: onDelete,
              tooltip: canDelete ? 'Hapus barang' : 'Tidak ada izin',
            ),
          ],
        ),
      ),
    );
  }
}
