import 'package:flutter/material.dart';
import '../../core/models/item_model.dart';
import '../../core/models/user_model.dart';
import '../../core/rbac/rbac_evaluator.dart';
import 'manager_service.dart';
import 'add_item_page.dart';
import 'item_detail_page.dart';

class ManagerPage extends StatefulWidget {
  final UserModel currentUser;

  const ManagerPage({super.key, required this.currentUser});

  @override
  State<ManagerPage> createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {
  List<ItemModel> _items = [];
  bool _isLoading = true;
  bool _canCreate = false;
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final items = await ManagerService.instance.getAllItems();
    final canCreate = await RbacEvaluator.instance.hasPermission(
      widget.currentUser.id,
      'item:create',
    );
    final canDelete = await RbacEvaluator.instance.hasPermission(
      widget.currentUser.id,
      'item:delete',
    );
    setState(() {
      _items = items;
      _canCreate = canCreate;
      _canDelete = canDelete;
      _isLoading = false;
    });
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
        builder: (_) => AddItemPage(currentUser: widget.currentUser),
      ),
    );
    if (result == true) await _loadData();
  }

  Future<void> _confirmDelete(ItemModel item) async {
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

    if (confirmed != true) return;

    final error = await ManagerService.instance.deleteItem(
      widget.currentUser.id,
      item.id!,
      item.sku,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barang ${item.sku} berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadData();
    }
  }

  void _openDetail(ItemModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemDetailPage(item: item)),
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
              'Login sebagai: ${widget.currentUser.name} (${widget.currentUser.roleName})',
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
  final ItemModel item;
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
            item.sku.length > 3 ? item.sku.substring(item.sku.length - 3) : item.sku,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item.sku} · ${item.category} · ${item.location}'),
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
